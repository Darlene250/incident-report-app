import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/utils/data_error_messages.dart';
import '../models/app_user.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';

/// Live incident lists, filters, counters and the write actions.
///
/// Screens never touch Firestore: they read this provider, which listens to the
/// service streams, so every screen updates automatically on changes.
class IncidentProvider extends ChangeNotifier {
  IncidentProvider({IncidentService? incidentService})
      : _incidentService = incidentService ?? IncidentService();

  final IncidentService _incidentService;

  /// One load per photo per session, shared by every card and the details
  /// screen. Photos never change after submission, so this cache never goes
  /// stale.
  final Map<String, Future<Uint8List?>> _photoCache = <String, Future<Uint8List?>>{};

  StreamSubscription<List<Incident>>? _allSubscription;
  StreamSubscription<List<Incident>>? _mySubscription;

  AppUser? _user;
  List<Incident> _allIncidents = const <Incident>[];
  List<Incident> _myIncidents = const <Incident>[];
  bool _isLoadingAll = false;
  bool _isLoadingMine = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _searchQuery = '';
  IncidentStatus? _statusFilter;
  IncidentCategory? _categoryFilter;
  bool _isDisposed = false;

  /// Every report, newest first.
  List<Incident> get allIncidents => _allIncidents;

  /// Reports created by the signed-in user, newest first.
  List<Incident> get myIncidents => _myIncidents;

  bool get isLoading => _isLoadingAll || _isLoadingMine;

  /// True until the signed-in user's own reports arrive. Screens that only show
  /// "my reports" should use this instead of [isLoading].
  bool get isLoadingMyReports => _isLoadingMine;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  /// Null means "All".
  IncidentStatus? get statusFilter => _statusFilter;

  /// Null means "All".
  IncidentCategory? get categoryFilter => _categoryFilter;

  bool get isStaff => _user?.role == UserRole.staff;

  /// Search + status + category applied to [allIncidents].
  List<Incident> get filteredIncidents {
    final String query = _searchQuery.trim().toLowerCase();

    return _allIncidents.where((Incident incident) {
      if (_statusFilter != null && incident.status != _statusFilter) return false;
      if (_categoryFilter != null && incident.category != _categoryFilter) return false;
      if (query.isEmpty) return true;

      return incident.title.toLowerCase().contains(query) ||
          incident.description.toLowerCase().contains(query) ||
          incident.location.toLowerCase().contains(query) ||
          incident.category.label.toLowerCase().contains(query) ||
          incident.reportedByName.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  // Counters for the home summary tiles and profile stats (the signed-in user's
  // own reports).
  int get myReportCount => _myIncidents.length;
  int get mySubmittedCount => _countMine(IncidentStatus.submitted);
  int get myInProgressCount => _countMine(IncidentStatus.inProgress);
  int get myResolvedCount => _countMine(IncidentStatus.resolved);

  int _countMine(IncidentStatus status) =>
      _myIncidents.where((Incident incident) => incident.status == status).length;

  /// Re-points the streams at [user]. Called from the provider tree whenever the
  /// auth session changes.
  void updateUser(AppUser? user) {
    final String? previousUid = _user?.uid;
    _user = user;
    if (previousUid == user?.uid) return;

    _resubscribe();
  }

  /// Live document for one report, so a details screen updates as staff change
  /// the status elsewhere.
  Stream<Incident?> watchIncident(String id) => _incidentService.streamIncident(id);

  /// The photo of [incident], or null when it has none. A failed load is
  /// dropped from the cache so the next build retries it.
  Future<Uint8List?>? photoFor(Incident incident) {
    if (!incident.hasPhoto) return null;

    return _photoCache.putIfAbsent(incident.id, () {
      return _incidentService.loadPhoto(incident.id).catchError((Object error) {
        _photoCache.remove(incident.id);
        return null;
      });
    });
  }

  /// Re-opens the Firestore streams, e.g. after an error.
  void refresh() => _resubscribe();

  void _resubscribe() {
    _allSubscription?.cancel();
    _mySubscription?.cancel();
    _allIncidents = const <Incident>[];
    _myIncidents = const <Incident>[];
    _isLoadingAll = false;
    _isLoadingMine = false;
    _errorMessage = null;

    final String? uid = _user?.uid;
    if (uid != null) {
      _isLoadingAll = true;
      _isLoadingMine = true;

      _allSubscription = _incidentService.streamAllIncidents().listen(
        (List<Incident> incidents) {
          _allIncidents = incidents;
          _isLoadingAll = false;
          _notify();
        },
        onError: (Object error) {
          _isLoadingAll = false;
          _errorMessage = dataErrorMessage(error);
          _notify();
        },
      );

      _mySubscription = _incidentService.streamIncidentsByUser(uid).listen(
        (List<Incident> incidents) {
          _myIncidents = incidents;
          _isLoadingMine = false;
          _notify();
        },
        onError: (Object error) {
          _isLoadingMine = false;
          _errorMessage = dataErrorMessage(error);
          _notify();
        },
      );
    }

    // updateUser() runs during a build, so notify after it finishes.
    scheduleMicrotask(_notify);
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _notify();
  }

  void setStatusFilter(IncidentStatus? status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    _notify();
  }

  void setCategoryFilter(IncidentCategory? category) {
    if (_categoryFilter == category) return;
    _categoryFilter = category;
    _notify();
  }

  /// Saves the report and its optional photo together. Returns the created
  /// report, or null when something failed.
  Future<Incident?> submitIncident({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    XFile? photo,
    bool isAnonymous = false,
  }) async {
    final AppUser? user = _user;
    if (user == null) {
      _errorMessage = 'Please sign in again to submit a report.';
      _notify();
      return null;
    }
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _errorMessage = null;
    _notify();

    try {
      final String incidentId = _incidentService.newIncidentId();
      // Bytes (not a file path) so the same code works on web and mobile.
      final Uint8List? photoBytes = await photo?.readAsBytes();
      if (photoBytes != null && photoBytes.length > IncidentService.maxPhotoBytes) {
        throw StateError('That photo is too large. Please choose a smaller one.');
      }

      final Incident incident = Incident.newReport(
        id: incidentId,
        title: title.trim(),
        description: description.trim(),
        category: category,
        location: location.trim(),
        reportedByUid: user.uid,
        reportedByName: user.fullName.isEmpty ? user.email : user.fullName,
        hasPhoto: photoBytes != null,
        isAnonymous: isAnonymous,
      );

      await _incidentService.createIncident(incident, photoBytes: photoBytes);

      return incident;
    } catch (error) {
      _errorMessage = dataErrorMessage(error);
      return null;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  /// Staff only. The role is re-checked here even though the rules enforce it.
  Future<bool> updateStatus(String incidentId, IncidentStatus newStatus) async {
    final AppUser? user = _user;
    if (!isStaff || user == null) {
      _errorMessage = 'Only staff members can change the status of a report.';
      _notify();
      return false;
    }
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    _notify();

    try {
      await _incidentService.updateStatus(incidentId, newStatus, user.uid);
      return true;
    } catch (error) {
      _errorMessage = dataErrorMessage(error);
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  /// Reporters may only edit or delete their own report while it is still
  /// `Submitted`, i.e. before staff start working on it. The Firestore rules
  /// enforce the same rule on the server.
  bool canModify(Incident incident) {
    final AppUser? user = _user;
    if (user == null) return false;

    return incident.reportedByUid == user.uid && incident.status == IncidentStatus.submitted;
  }

  bool canDelete(Incident incident) => canModify(incident);
  bool canEdit(Incident incident) => canModify(incident);

  /// Saves the reporter's corrections to title, description, category and
  /// location. Returns true on success.
  Future<bool> updateIncidentDetails(
    Incident incident, {
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
  }) async {
    if (!canEdit(incident)) {
      _errorMessage = 'You can only edit your own report while it is still submitted.';
      _notify();
      return false;
    }
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    _notify();

    try {
      await _incidentService.updateIncidentDetails(
        incident.id,
        title: title.trim(),
        description: description.trim(),
        category: category,
        location: location.trim(),
      );
      return true;
    } catch (error) {
      _errorMessage = dataErrorMessage(error);
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  Future<bool> deleteIncident(Incident incident) async {
    if (!canDelete(incident)) {
      _errorMessage = 'You can only delete your own report while it is still submitted.';
      _notify();
      return false;
    }
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    _notify();

    try {
      await _incidentService.deleteIncident(incident.id, hasPhoto: incident.hasPhoto);
      _photoCache.remove(incident.id);
      return true;
    } catch (error) {
      _errorMessage = dataErrorMessage(error);
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _notify();
  }

  void _notify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _allSubscription?.cancel();
    _mySubscription?.cancel();
    super.dispose();
  }
}
