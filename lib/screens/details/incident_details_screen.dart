import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/data_error_messages.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/icon_text_row.dart';
import '../../core/widgets/incident_thumbnail.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../report_form/report_form_screen.dart';

/// Single report view: summary, status timeline, description and — for staff —
/// a status update control.
///
/// The incident comes from `streamIncident`, so a student watching this screen
/// sees the status change as soon as a staff member updates it.
class IncidentDetailsScreen extends StatefulWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});

  final String incidentId;

  /// Single navigation entry point used by the Home, Reports and Profile lists.
  static Future<void> open(BuildContext context, String incidentId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => IncidentDetailsScreen(incidentId: incidentId),
      ),
    );
  }

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  Stream<Incident?>? _stream;
  IncidentStatus? _pendingStatus;

  @override
  void initState() {
    super.initState();
    _stream = context.read<IncidentProvider>().watchIncident(widget.incidentId);
  }

  void _retry() {
    setState(() {
      _stream = context.read<IncidentProvider>().watchIncident(widget.incidentId);
    });
  }

  /// The details stream picks up the saved changes, so nothing needs to be
  /// passed back.
  void _openEdit(Incident incident) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ReportFormScreen(initial: incident),
      ),
    );
  }

  Future<void> _confirmDelete(Incident incident) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete report?'),
        content: const Text('This report will be removed permanently.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final IncidentProvider provider = context.read<IncidentProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);

    final bool deleted = await provider.deleteIncident(incident);
    if (!mounted) return;

    if (deleted) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Report deleted.')));
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? 'We could not delete this report.'),
        backgroundColor: AppColors.error,
      ),
    );
    provider.clearError();
  }

  Future<void> _updateStatus(Incident incident) async {
    final IncidentStatus? target = _pendingStatus;
    if (target == null) return;

    final IncidentProvider provider = context.read<IncidentProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final bool updated = await provider.updateStatus(incident.id, target);
    if (!mounted) return;

    if (updated) {
      setState(() => _pendingStatus = null);
      messenger.showSnackBar(
        SnackBar(content: Text('Status updated to ${target.label}.')),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? 'We could not update the status.'),
        backgroundColor: AppColors.error,
      ),
    );
    provider.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final IncidentProvider provider = context.watch<IncidentProvider>();

    return StreamBuilder<Incident?>(
      stream: _stream,
      builder: (BuildContext context, AsyncSnapshot<Incident?> snapshot) {
        if (snapshot.hasError) {
          return _scaffold(
            actions: const <Widget>[],
            body: ErrorView(
              message: dataErrorMessage(snapshot.error!),
              onRetry: _retry,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _scaffold(
            actions: const <Widget>[],
            body: const LoadingView(message: 'Loading report…'),
          );
        }

        final Incident? incident = snapshot.data;
        if (incident == null) {
          return _scaffold(
            actions: const <Widget>[],
            body: const ErrorView(
              title: 'Report unavailable',
              message: 'This report may have been deleted.',
            ),
          );
        }

        return _scaffold(
          actions: provider.canModify(incident)
              ? <Widget>[
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    tooltip: 'Report actions',
                    onSelected: (String value) {
                      if (value == 'edit') _openEdit(incident);
                      if (value == 'delete') _confirmDelete(incident);
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit report'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete report'),
                      ),
                    ],
                  ),
                ]
              : const <Widget>[],
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              8,
              AppSizes.screenPadding,
              28,
            ),
            children: <Widget>[
              _SummaryCard(incident: incident, photo: provider.photoFor(incident)),
              const SizedBox(height: 22),
              Text('Status Timeline', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              _StatusTimeline(incident: incident),
              const SizedBox(height: 22),
              Text('Description', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 8),
              Text(incident.description, style: AppTextStyles.body),
              if (incident.hasPhoto) ...<Widget>[
                const SizedBox(height: 22),
                Text('Photo', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),
                _PhotoSection(photo: provider.photoFor(incident)),
              ],
              if (provider.isStaff) ...<Widget>[
                const SizedBox(height: 22),
                Text('Update Status', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),
                _StaffStatusSection(
                  incident: incident,
                  pendingStatus: _pendingStatus,
                  isSubmitting: provider.isSubmitting,
                  onChanged: (IncidentStatus? status) =>
                      setState(() => _pendingStatus = status),
                  onUpdate: () => _updateStatus(incident),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _scaffold({required List<Widget> actions, required Widget body}) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Incident Details'),
        actions: actions,
      ),
      body: SafeArea(child: body),
    );
  }
}

/// Full-width photo, shown with a spinner while it loads from Firestore.
class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.photo});

  final Future<Uint8List?>? photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      child: FutureBuilder<Uint8List?>(
        future: photo,
        builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
          final Uint8List? bytes = snapshot.data;
          if (bytes != null) {
            return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
          }

          return Container(
            height: 180,
            color: AppColors.myReportsTile,
            alignment: Alignment.center,
            child: snapshot.connectionState == ConnectionState.waiting
                ? const CircularProgressIndicator()
                : Text('The photo could not be loaded.', style: AppTextStyles.caption),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.incident, required this.photo});

  final Incident incident;
  final Future<Uint8List?>? photo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IncidentThumbnail(
                imageFuture: photo,
                fallbackIcon: incident.category.icon,
                size: 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      incident.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            incident.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StatusChip(status: incident.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          IconTextRow(
            icon: Icons.calendar_today_rounded,
            text: 'Submitted on ${_submittedLabel(incident.createdAt)}',
          ),
          const SizedBox(height: 8),
          IconTextRow(
            icon: incident.isAnonymous
                ? Icons.visibility_off_outlined
                : Icons.person_outline_rounded,
            text: incident.isAnonymous
                ? 'Reported anonymously'
                : 'Reported by ${incident.reportedByName}',
          ),
        ],
      ),
    );
  }
}

String _submittedLabel(DateTime date) {
  return DateFormat("MMM dd, yyyy 'at' h:mm a").format(date);
}

/// Horizontal three-step tracker built from the incident's status history.
class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.incident});

  final Incident incident;

  static const double _nodeWidth = 78;
  static const double _circleSize = 28;

  @override
  Widget build(BuildContext context) {
    final int currentIndex = IncidentStatus.values.indexOf(incident.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < IncidentStatus.values.length; i++) ...<Widget>[
            if (i > 0)
              Expanded(
                child: Padding(
                  // Aligns the connector with the centre of the 28px circles.
                  padding: const EdgeInsets.only(top: _circleSize / 2 - 1),
                  child: Container(
                    height: 2,
                    color: i <= currentIndex ? AppColors.primary : AppColors.border,
                  ),
                ),
              ),
            _TimelineStep(
              status: IncidentStatus.values[i],
              isCompleted: i < currentIndex,
              isCurrent: i == currentIndex,
              reachedAt: _reachedAt(incident, IncidentStatus.values[i]),
              width: _nodeWidth,
              circleSize: _circleSize,
            ),
          ],
        ],
      ),
    );
  }

  DateTime? _reachedAt(Incident incident, IncidentStatus status) {
    DateTime? reached;
    for (final StatusChange change in incident.statusHistory) {
      if (change.status == status) reached = change.changedAt;
    }

    return reached;
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
    required this.reachedAt,
    required this.width,
    required this.circleSize,
  });

  final IncidentStatus status;
  final bool isCompleted;
  final bool isCurrent;
  final DateTime? reachedAt;
  final double width;
  final double circleSize;

  @override
  Widget build(BuildContext context) {
    final bool isReached = isCompleted || isCurrent;

    return SizedBox(
      width: width,
      child: Column(
        children: <Widget>[
          Container(
            height: circleSize,
            width: circleSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isReached ? AppColors.primary : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : isCurrent
                    ? Container(
                        height: 9,
                        width: 9,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
          ),
          const SizedBox(height: 8),
          Text(
            status.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.tileLabel.copyWith(
              color: isReached ? AppColors.textPrimary : AppColors.textHint,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            reachedAt == null ? '—' : DateFormat('d MMM, h:mm a').format(reachedAt!),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.textHint,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

/// Staff-only dropdown + update button.
class _StaffStatusSection extends StatelessWidget {
  const _StaffStatusSection({
    required this.incident,
    required this.pendingStatus,
    required this.isSubmitting,
    required this.onChanged,
    required this.onUpdate,
  });

  final Incident incident;
  final IncidentStatus? pendingStatus;
  final bool isSubmitting;
  final ValueChanged<IncidentStatus?> onChanged;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final IncidentStatus selected = pendingStatus ?? incident.status;
    final bool canUpdate = selected != incident.status && !isSubmitting;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DropdownButtonFormField<IncidentStatus>(
            initialValue: selected,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
            style: AppTextStyles.body,
            items: <DropdownMenuItem<IncidentStatus>>[
              for (final IncidentStatus status in IncidentStatus.values)
                DropdownMenuItem<IncidentStatus>(
                  value: status,
                  child: Text(status.label),
                ),
            ],
            onChanged: isSubmitting ? null : onChanged,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Update',
            isLoading: isSubmitting,
            onPressed: canUpdate ? onUpdate : null,
          ),
        ],
      ),
    );
  }
}
