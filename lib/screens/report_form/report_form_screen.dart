import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/locations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/category_tile.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';

/// Creates a new report, or edits [initial] when one is given.
///
/// Editing is only offered while a report is still `Submitted`; the photo and
/// the anonymity choice are fixed once a report has been filed.
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, this.initial});

  /// The report being edited, or null for a new report.
  final Incident? initial;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  // Kept in step with hasValidContent() in firestore.rules.
  static const int _minTitleLength = 5;
  static const int _maxTitleLength = 100;
  static const int _minDescriptionLength = 15;
  static const int _maxDescriptionLength = 1000;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState<IncidentCategory>> _categoryKey =
      GlobalKey<FormFieldState<IncidentCategory>>();
  late final TextEditingController _titleController =
      TextEditingController(text: widget.initial?.title);
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.initial?.description);
  final ImagePicker _picker = ImagePicker();

  // Only pre-selected when it is still one of the offered locations, because
  // the dropdown requires its value to be among its items.
  late String? _location = CampusLocations.all.contains(widget.initial?.location)
      ? widget.initial?.location
      : null;
  XFile? _photo;
  Uint8List? _photoBytes;
  bool _isAnonymous = false;

  bool get _isEditing => widget.initial != null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    final String title = (value ?? '').trim();
    if (title.isEmpty) return 'Enter a title';
    if (title.length < _minTitleLength) return 'Use at least $_minTitleLength characters';

    return null;
  }

  String? _validateDescription(String? value) {
    final String description = (value ?? '').trim();
    if (description.isEmpty) return 'Enter a description';
    if (description.length < _minDescriptionLength) {
      return 'Use at least $_minDescriptionLength characters';
    }

    return null;
  }

  Future<void> _pickPhoto() async {
    try {
      // Resized and re-encoded on the device so the photo fits comfortably in
      // a Firestore document (typically 100–300 KB).
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _photo = picked;
        _photoBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not open your gallery. Please try again.')),
      );
    }
  }

  void _removePhoto() {
    setState(() {
      _photo = null;
      _photoBytes = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final IncidentCategory? category = _categoryKey.currentState?.value;
    final String? location = _location;
    if (category == null || location == null) return;

    final IncidentProvider incidents = context.read<IncidentProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);

    final Incident? initial = widget.initial;
    if (initial != null) {
      final bool saved = await incidents.updateIncidentDetails(
        initial,
        title: _titleController.text,
        description: _descriptionController.text,
        category: category,
        location: location,
      );
      if (!mounted) return;
      _showResult(
        messenger,
        incidents,
        success: saved,
        successMessage: 'Report updated.',
        fallbackError: 'We could not save your changes. Please try again.',
        navigator: navigator,
      );
      return;
    }

    final Incident? created = await incidents.submitIncident(
      title: _titleController.text,
      description: _descriptionController.text,
      category: category,
      location: location,
      photo: _photo,
      isAnonymous: _isAnonymous,
    );

    if (!mounted) return;
    _showResult(
      messenger,
      incidents,
      success: created != null,
      successMessage: 'Report submitted successfully.',
      fallbackError: 'We could not submit your report. Please try again.',
      navigator: navigator,
    );
  }

  void _showResult(
    ScaffoldMessengerState messenger,
    IncidentProvider incidents, {
    required bool success,
    required String successMessage,
    required String fallbackError,
    required NavigatorState navigator,
  }) {
    if (success) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      return;
    }

    // The form keeps everything the user typed so they can retry.
    messenger.showSnackBar(
      SnackBar(
        content: Text(incidents.errorMessage ?? fallbackError),
        backgroundColor: AppColors.error,
      ),
    );
    // Cleared so the message cannot resurface on another screen.
    incidents.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final IncidentProvider incidents = context.watch<IncidentProvider>();
    final bool isSubmitting = incidents.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        centerTitle: true,
        title: Text(_isEditing ? 'Edit Report' : 'Report an Incident'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            8,
            AppSizes.screenPadding,
            28,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Select a category', style: AppTextStyles.inputLabel),
                const SizedBox(height: 10),
                _CategorySelector(
                  fieldKey: _categoryKey,
                  initialValue: widget.initial?.category,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Title',
                  hintText: 'Briefly describe the issue...',
                  controller: _titleController,
                  maxLength: _maxTitleLength,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  validator: _validateTitle,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Description',
                  hintText:
                      'Provide more details about the issue... e.g. what happened, when, impact, etc.',
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 4,
                  maxLength: _maxDescriptionLength,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  validator: _validateDescription,
                ),
                const SizedBox(height: 16),
                Text('Location', style: AppTextStyles.inputLabel),
                const SizedBox(height: 8),
                _LocationDropdown(
                  value: _location,
                  onChanged: (String? value) => setState(() => _location = value),
                ),
                if (!_isEditing) ...<Widget>[
                  const SizedBox(height: 20),
                  Text('Add a photo (optional)', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 10),
                  if (_photoBytes == null)
                    _PhotoPickerBox(onTap: isSubmitting ? null : _pickPhoto)
                  else
                    _PhotoPreview(bytes: _photoBytes!, onRemove: _removePhoto),
                  const SizedBox(height: 12),
                  _AnonymousSwitch(
                    value: _isAnonymous,
                    onChanged: isSubmitting
                        ? null
                        : (bool value) => setState(() => _isAnonymous = value),
                  ),
                ],
                const SizedBox(height: 26),
                PrimaryButton(
                  label: _isEditing ? 'Save Changes' : 'Submit Report',
                  isLoading: isSubmitting,
                  onPressed: isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single-select category picker wired into the form so it can show an inline
/// error.
class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.fieldKey, this.initialValue});

  final GlobalKey<FormFieldState<IncidentCategory>> fieldKey;
  final IncidentCategory? initialValue;

  @override
  Widget build(BuildContext context) {
    return FormField<IncidentCategory>(
      key: fieldKey,
      initialValue: initialValue,
      validator: (IncidentCategory? value) =>
          value == null ? 'Select a category' : null,
      builder: (FormFieldState<IncidentCategory> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                for (final IncidentCategory category in IncidentCategory.values)
                  CategoryTile(
                    icon: category.icon,
                    label: category.label,
                    isSelected: field.value == category,
                    onTap: () => field.didChange(category),
                  ),
              ],
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 2),
                child: Text(field.errorText!, style: AppTextStyles.errorText),
              ),
          ],
        );
      },
    );
  }
}

class _LocationDropdown extends StatelessWidget {
  const _LocationDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
      style: AppTextStyles.body,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
      ),
      hint: Text('Select a campus location', style: AppTextStyles.hint),
      items: <DropdownMenuItem<String>>[
        for (final String location in CampusLocations.all)
          DropdownMenuItem<String>(
            value: location,
            child: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
      validator: (String? value) => value == null ? 'Select a location' : null,
    );
  }
}

/// Lets a reporter hide their name, e.g. for sensitive safety reports.
class _AnonymousSwitch extends StatelessWidget {
  const _AnonymousSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    // Material (not a decorated Container) so the tile's ink splash is visible.
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        title: Text('Report anonymously', style: AppTextStyles.inputLabel),
        subtitle: Text(
          'Your name is hidden from everyone, including staff.',
          style: AppTextStyles.caption,
        ),
      ),
    );
  }
}

class _PhotoPickerBox extends StatelessWidget {
  const _PhotoPickerBox({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const BorderRadius radius = BorderRadius.all(
      Radius.circular(AppSizes.inputRadius),
    );

    return SizedBox(
      height: 118,
      width: double.infinity,
      child: CustomPaint(
        // Painted on top so the dashed edge stays visible over the filled child.
        foregroundPainter: _DashedBorderPainter(
          radius: AppSizes.inputRadius,
          color: AppColors.textHint.withValues(alpha: 0.6),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            color: AppColors.shell,
            child: InkWell(
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.image_outlined, size: 24, color: AppColors.primary),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to add photos',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      child: SizedBox(
        height: 170,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.memory(bytes, fit: BoxFit.cover),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onRemove,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    height: 32,
                    width: 32,
                    child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  static const double _dash = 6;
  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          Radius.circular(radius),
        ),
      );

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = math.min(distance + _dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
