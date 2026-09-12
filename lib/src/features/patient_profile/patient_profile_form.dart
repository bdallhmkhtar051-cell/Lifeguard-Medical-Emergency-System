import 'package:flutter/material.dart';

import 'emergency_profile.dart';

typedef SaveProfile = Future<bool> Function(EmergencyProfile profile);

class PatientProfileForm extends StatefulWidget {
  const PatientProfileForm({
    required this.profile,
    required this.saving,
    required this.fieldErrors,
    required this.onSave,
    required this.onCancel,
    required this.onReload,
    this.serverError,
    super.key,
  });

  final EmergencyProfile profile;
  final bool saving;
  final String? serverError;
  final Map<String, List<String>> fieldErrors;
  final SaveProfile onSave;
  final VoidCallback onCancel;
  final VoidCallback onReload;

  @override
  State<PatientProfileForm> createState() => _PatientProfileFormState();
}

class _PatientProfileFormState extends State<PatientProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late String _bloodGroup;
  late List<_AllergyDraft> _allergies;
  late List<_ConditionDraft> _conditions;
  late List<_MedicationDraft> _medications;
  late List<_ContactDraft> _contacts;
  late final TextEditingController _physicianName;
  late final TextEditingController _physicianPhone;
  late final TextEditingController _insuranceProvider;
  late final TextEditingController _insurancePolicyNumber;
  late final TextEditingController _firstResponderNotes;
  late String _organDonorStatus;
  bool _dirty = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _bloodGroup = widget.profile.bloodGroup;
    _allergies = widget.profile.allergies.map(_AllergyDraft.fromModel).toList();
    _conditions = widget.profile.medicalConditions
        .map(_ConditionDraft.fromModel)
        .toList();
    _medications = widget.profile.medications
        .map(_MedicationDraft.fromModel)
        .toList();
    _contacts = widget.profile.emergencyContacts
        .map(_ContactDraft.fromModel)
        .toList();
    _physicianName = TextEditingController(
      text: widget.profile.primaryPhysicianName,
    );
    _physicianPhone = TextEditingController(
      text: widget.profile.primaryPhysicianPhone,
    );
    _insuranceProvider = TextEditingController(
      text: widget.profile.insuranceProvider,
    );
    _insurancePolicyNumber = TextEditingController(
      text: widget.profile.insurancePolicyNumber,
    );
    _firstResponderNotes = TextEditingController(
      text: widget.profile.firstResponderNotes,
    );
    _organDonorStatus = widget.profile.organDonorStatus;
  }

  @override
  void dispose() {
    _disposeAll(_allergies);
    _disposeAll(_conditions);
    _disposeAll(_medications);
    _disposeAll(_contacts);
    _physicianName.dispose();
    _physicianPhone.dispose();
    _insuranceProvider.dispose();
    _insurancePolicyNumber.dispose();
    _firstResponderNotes.dispose();
    super.dispose();
  }

  void _markDirty([String? _]) {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
  }

  void _add<T extends _DisposableDraft>(List<T> drafts, T draft) {
    setState(() {
      drafts.add(draft);
      _dirty = true;
    });
  }

  void _remove<T extends _DisposableDraft>(List<T> drafts, int index) {
    setState(() {
      drafts.removeAt(index).dispose();
      _dirty = true;
    });
  }

  Future<void> _cancel() async {
    if (!_dirty) {
      widget.onCancel();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved profile changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true) {
      widget.onCancel();
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_contacts.isNotEmpty &&
        _contacts.where((contact) => contact.isPrimary).length != 1) {
      setState(() {
        _localError =
            'Select exactly one primary contact before saving the profile.';
      });
      return;
    }
    _localError = null;
    final profile = widget.profile.copyWith(
      bloodGroup: _bloodGroup,
      primaryPhysicianName: _physicianName.text,
      primaryPhysicianPhone: _physicianPhone.text,
      insuranceProvider: _insuranceProvider.text,
      insurancePolicyNumber: _insurancePolicyNumber.text,
      organDonorStatus: _organDonorStatus,
      firstResponderNotes: _firstResponderNotes.text,
      allergies: _allergies.map((item) => item.toModel()).toList(),
      medicalConditions: _conditions.map((item) => item.toModel()).toList(),
      medications: _medications.map((item) => item.toModel()).toList(),
      emergencyContacts: _contacts.map((item) => item.toModel()).toList(),
    );
    final saved = await widget.onSave(profile);
    if (saved) {
      _dirty = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit emergency profile',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Editing ${widget.profile.fullName}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    key: const ValueKey('cancel-profile-button'),
                    onPressed: widget.saving ? null : _cancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const ValueKey('save-profile-button'),
                    onPressed: widget.saving ? null : _save,
                    icon: widget.saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(widget.saving ? 'Saving…' : 'Save changes'),
                  ),
                ],
              ),
            ],
          ),
          if (widget.serverError != null) ...[
            const SizedBox(height: 16),
            _FormError(
              message: widget.serverError!,
              details: widget.fieldErrors.values
                  .expand((item) => item)
                  .toList(),
              onReload: widget.onReload,
            ),
          ],
          if (_localError != null) ...[
            const SizedBox(height: 16),
            _FormError(message: _localError!, details: const []),
          ],
          const SizedBox(height: 20),
          _FormSection(
            title: 'Critical information',
            description: 'Identity details are managed separately.',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: DropdownButtonFormField<String>(
                key: const ValueKey('blood-group-field'),
                initialValue: bloodGroupLabels.containsKey(_bloodGroup)
                    ? _bloodGroup
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Blood group',
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                ),
                hint: const Text('Select a blood group'),
                items: bloodGroupLabels.keys
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(bloodGroupLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: widget.saving
                    ? null
                    : (value) {
                        setState(() {
                          _bloodGroup = value ?? '';
                          _dirty = true;
                        });
                      },
                validator: (value) =>
                    value == null ? 'Select a blood group.' : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FormSection(
            title: 'Emergency coordination',
            description:
                'Optional patient-reported details. Confirm them with official sources when possible.',
            child: Column(
              children: [
                _ResponsiveFields(
                  children: [
                    _ProfileTextField(
                      controller: _physicianName,
                      label: 'Primary physician name',
                      enabled: !widget.saving,
                      onChanged: _markDirty,
                    ),
                    _ProfileTextField(
                      controller: _physicianPhone,
                      label: 'Primary physician phone',
                      enabled: !widget.saving,
                      keyboardType: TextInputType.phone,
                      maxLength: 16,
                      onChanged: _markDirty,
                      validator: _optionalInternationalPhone,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ResponsiveFields(
                  children: [
                    _ProfileTextField(
                      controller: _insuranceProvider,
                      label: 'Insurance provider',
                      enabled: !widget.saving,
                      onChanged: _markDirty,
                    ),
                    _ProfileTextField(
                      controller: _insurancePolicyNumber,
                      label: 'Policy or member number',
                      enabled: !widget.saving,
                      onChanged: _markDirty,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('organ-donor-status-field'),
                  initialValue: organDonorStatusLabels.containsKey(
                    _organDonorStatus,
                  )
                      ? _organDonorStatus
                      : 'Unknown',
                  decoration: const InputDecoration(
                    labelText: 'Organ donor status',
                    prefixIcon: Icon(Icons.volunteer_activism_outlined),
                  ),
                  items: organDonorStatusLabels.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: widget.saving
                      ? null
                      : (value) {
                          setState(() {
                            _organDonorStatus = value ?? 'Unknown';
                            _dirty = true;
                          });
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('first-responder-notes-field'),
                  controller: _firstResponderNotes,
                  enabled: !widget.saving,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'First-responder notes',
                    hintText:
                        'Short factual instructions or context; do not enter a diagnosis.',
                    alignLabelWithHint: true,
                  ),
                  onChanged: _markDirty,
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Donor status and notes are informational and do not replace official records or clinical judgment.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _EditableListSection(
            title: 'Allergies',
            description: 'Record the allergen and any known reaction.',
            addLabel: 'Add allergy',
            onAdd: widget.saving || _allergies.length >= 20
                ? null
                : () => _add(_allergies, _AllergyDraft.empty()),
            children: [
              for (var index = 0; index < _allergies.length; index++)
                _AllergyEditor(
                  key: ValueKey('allergy-$index'),
                  draft: _allergies[index],
                  enabled: !widget.saving,
                  onChanged: _markDirty,
                  onRemove: () => _remove(_allergies, index),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _EditableListSection(
            title: 'Medical conditions',
            description: 'Include chronic or high-risk conditions.',
            addLabel: 'Add condition',
            onAdd: widget.saving || _conditions.length >= 20
                ? null
                : () => _add(_conditions, _ConditionDraft.empty()),
            children: [
              for (var index = 0; index < _conditions.length; index++)
                _ConditionEditor(
                  key: ValueKey('condition-$index'),
                  draft: _conditions[index],
                  enabled: !widget.saving,
                  onChanged: _markDirty,
                  onRemove: () => _remove(_conditions, index),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _EditableListSection(
            title: 'Current medications',
            description: 'Use the medication label or prescribed instructions.',
            addLabel: 'Add medication',
            onAdd: widget.saving || _medications.length >= 20
                ? null
                : () => _add(_medications, _MedicationDraft.empty()),
            children: [
              for (var index = 0; index < _medications.length; index++)
                _MedicationEditor(
                  key: ValueKey('medication-$index'),
                  draft: _medications[index],
                  enabled: !widget.saving,
                  onChanged: _markDirty,
                  onRemove: () => _remove(_medications, index),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _EditableListSection(
            title: 'Emergency contacts',
            description: 'Only one contact can be marked as primary.',
            addLabel: 'Add contact',
            onAdd: widget.saving || _contacts.length >= 5
                ? null
                : () => _add(_contacts, _ContactDraft.empty()),
            children: [
              for (var index = 0; index < _contacts.length; index++)
                _ContactEditor(
                  key: ValueKey('contact-$index'),
                  draft: _contacts[index],
                  enabled: !widget.saving,
                  onChanged: _markDirty,
                  onPrimaryChanged: (selected) {
                    setState(() {
                      if (selected) {
                        for (final contact in _contacts) {
                          contact.isPrimary = false;
                        }
                      }
                      _contacts[index].isPrimary = selected;
                      _localError = null;
                      _dirty = true;
                    });
                  },
                  onRemove: () => _remove(_contacts, index),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: widget.saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}

String? _optionalInternationalPhone(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(text)
      ? null
      : 'Use international format, for example +252612345678.';
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _EditableListSection extends StatelessWidget {
  const _EditableListSection({
    required this.title,
    required this.description,
    required this.addLabel,
    required this.onAdd,
    required this.children,
  });

  final String title;
  final String description;
  final String addLabel;
  final VoidCallback? onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: title,
      description: description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Nothing recorded.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            )
          else
            ...children,
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(addLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.children, required this.onRemove});

  final List<Widget> children;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Remove item',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 660 || children.length == 1) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _AllergyEditor extends StatelessWidget {
  const _AllergyEditor({
    required this.draft,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final _AllergyDraft draft;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      onRemove: enabled ? onRemove : null,
      children: [
        _ResponsiveFields(
          children: [
            _ProfileTextField(
              controller: draft.name,
              label: 'Allergen',
              enabled: enabled,
              onChanged: onChanged,
              required: true,
            ),
            _ProfileTextField(
              controller: draft.reaction,
              label: 'Known reaction',
              enabled: enabled,
              onChanged: onChanged,
              maxLength: 500,
            ),
            DropdownButtonFormField<String>(
              initialValue: _allergySeverities.contains(draft.severity)
                  ? draft.severity
                  : null,
              decoration: const InputDecoration(labelText: 'Severity'),
              items: _allergySeverities
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: enabled
                  ? (value) {
                      draft.severity = value ?? 'Unknown';
                      onChanged(draft.severity);
                    }
                  : null,
              validator: (value) =>
                  value == null ? 'Severity is required.' : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _ConditionEditor extends StatelessWidget {
  const _ConditionEditor({
    required this.draft,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final _ConditionDraft draft;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      onRemove: enabled ? onRemove : null,
      children: [
        _ResponsiveFields(
          children: [
            _ProfileTextField(
              controller: draft.name,
              label: 'Condition',
              enabled: enabled,
              onChanged: onChanged,
              required: true,
            ),
            _ProfileTextField(
              controller: draft.notes,
              label: 'Notes',
              enabled: enabled,
              onChanged: onChanged,
              maxLength: 500,
            ),
          ],
        ),
      ],
    );
  }
}

class _MedicationEditor extends StatelessWidget {
  const _MedicationEditor({
    required this.draft,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final _MedicationDraft draft;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      onRemove: enabled ? onRemove : null,
      children: [
        _ResponsiveFields(
          children: [
            _ProfileTextField(
              controller: draft.name,
              label: 'Medication',
              enabled: enabled,
              onChanged: onChanged,
              required: true,
            ),
            _ProfileTextField(
              controller: draft.dosage,
              label: 'Dosage',
              enabled: enabled,
              onChanged: onChanged,
            ),
            _ProfileTextField(
              controller: draft.frequency,
              label: 'Frequency',
              enabled: enabled,
              onChanged: onChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _ContactEditor extends StatelessWidget {
  const _ContactEditor({
    required this.draft,
    required this.enabled,
    required this.onChanged,
    required this.onPrimaryChanged,
    required this.onRemove,
    super.key,
  });

  final _ContactDraft draft;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onPrimaryChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      onRemove: enabled ? onRemove : null,
      children: [
        _ResponsiveFields(
          children: [
            _ProfileTextField(
              controller: draft.name,
              label: 'Contact name',
              enabled: enabled,
              onChanged: onChanged,
              required: true,
            ),
            _ProfileTextField(
              controller: draft.relationship,
              label: 'Relationship',
              enabled: enabled,
              onChanged: onChanged,
              maxLength: 50,
              required: true,
            ),
            _ProfileTextField(
              controller: draft.phoneNumber,
              label: 'Phone number',
              enabled: enabled,
              keyboardType: TextInputType.phone,
              maxLength: 30,
              onChanged: onChanged,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Phone number is required.';
                }
                if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(text)) {
                  return 'Use international format, e.g. +252612345678.';
                }
                return null;
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Primary contact'),
          value: draft.isPrimary,
          onChanged: enabled ? onPrimaryChanged : null,
        ),
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.onChanged,
    this.keyboardType,
    this.maxLength = 100,
    this.required = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int maxLength;
  final bool required;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
      validator:
          validator ??
          (required
              ? (value) => value == null || value.trim().isEmpty
                    ? '$label is required.'
                    : null
              : null),
    );
  }
}

class _FormError extends StatelessWidget {
  const _FormError({
    required this.message,
    required this.details,
    this.onReload,
  });

  final String message;
  final List<String> details;
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            for (final detail in details)
              Text(
                '• $detail',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            if (onReload != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onReload,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload server version'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

abstract interface class _DisposableDraft {
  void dispose();
}

class _AllergyDraft implements _DisposableDraft {
  _AllergyDraft(this.name, this.severity, this.reaction);

  factory _AllergyDraft.fromModel(Allergy model) => _AllergyDraft(
    TextEditingController(text: model.name),
    model.severity,
    TextEditingController(text: model.reaction),
  );

  factory _AllergyDraft.empty() =>
      _AllergyDraft.fromModel(const Allergy(name: ''));

  final TextEditingController name;
  String severity;
  final TextEditingController reaction;

  Allergy toModel() => Allergy(
    name: name.text.trim(),
    severity: severity,
    reaction: reaction.text.trim(),
  );

  @override
  void dispose() {
    name.dispose();
    reaction.dispose();
  }
}

class _ConditionDraft implements _DisposableDraft {
  _ConditionDraft(this.name, this.notes);

  factory _ConditionDraft.fromModel(MedicalCondition model) => _ConditionDraft(
    TextEditingController(text: model.name),
    TextEditingController(text: model.notes),
  );

  factory _ConditionDraft.empty() =>
      _ConditionDraft.fromModel(const MedicalCondition(name: ''));

  final TextEditingController name;
  final TextEditingController notes;

  MedicalCondition toModel() =>
      MedicalCondition(name: name.text.trim(), notes: notes.text.trim());

  @override
  void dispose() {
    name.dispose();
    notes.dispose();
  }
}

class _MedicationDraft implements _DisposableDraft {
  _MedicationDraft(this.name, this.dosage, this.frequency);

  factory _MedicationDraft.fromModel(Medication model) => _MedicationDraft(
    TextEditingController(text: model.name),
    TextEditingController(text: model.dosage),
    TextEditingController(text: model.frequency),
  );

  factory _MedicationDraft.empty() =>
      _MedicationDraft.fromModel(const Medication(name: ''));

  final TextEditingController name;
  final TextEditingController dosage;
  final TextEditingController frequency;

  Medication toModel() => Medication(
    name: name.text.trim(),
    dosage: dosage.text.trim(),
    frequency: frequency.text.trim(),
  );

  @override
  void dispose() {
    name.dispose();
    dosage.dispose();
    frequency.dispose();
  }
}

class _ContactDraft implements _DisposableDraft {
  _ContactDraft(this.name, this.relationship, this.phoneNumber, this.isPrimary);

  factory _ContactDraft.fromModel(EmergencyContact model) => _ContactDraft(
    TextEditingController(text: model.name),
    TextEditingController(text: model.relationship),
    TextEditingController(text: model.phoneNumber),
    model.isPrimary,
  );

  factory _ContactDraft.empty() => _ContactDraft.fromModel(
    const EmergencyContact(name: '', phoneNumber: ''),
  );

  final TextEditingController name;
  final TextEditingController relationship;
  final TextEditingController phoneNumber;
  bool isPrimary;

  EmergencyContact toModel() => EmergencyContact(
    name: name.text.trim(),
    relationship: relationship.text.trim(),
    phoneNumber: phoneNumber.text.trim(),
    isPrimary: isPrimary,
  );

  @override
  void dispose() {
    name.dispose();
    relationship.dispose();
    phoneNumber.dispose();
  }
}

void _disposeAll(Iterable<_DisposableDraft> drafts) {
  for (final draft in drafts) {
    draft.dispose();
  }
}

const _allergySeverities = <String>['Unknown', 'Mild', 'Moderate', 'Severe'];
