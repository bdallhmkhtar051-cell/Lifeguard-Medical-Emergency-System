import 'package:flutter/material.dart';

import '../auth/auth_models.dart';

class AccessibilitySettingsPage extends StatelessWidget {
  const AccessibilitySettingsPage({
    required this.user,
    required this.expiresAtUtc,
    required this.textScale,
    required this.highContrast,
    required this.reducedMotion,
    required this.onTextScaleChanged,
    required this.onHighContrastChanged,
    required this.onReducedMotionChanged,
    required this.onReset,
    super.key,
  });

  final AppUser user;
  final DateTime? expiresAtUtc;
  final double textScale;
  final bool highContrast;
  final bool reducedMotion;
  final ValueChanged<double> onTextScaleChanged;
  final ValueChanged<bool> onHighContrastChanged;
  final ValueChanged<bool> onReducedMotionChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const ValueKey('accessibility-settings-page'),
    padding: const EdgeInsets.all(20),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Accessibility & session settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Adjust the authenticated workspace for this session. Medical data and account permissions are not changed.',
              style: TextStyle(color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Heading(
                      icon: Icons.text_fields,
                      text: 'Reading preferences',
                    ),
                    const SizedBox(height: 18),
                    Semantics(
                      label: 'Text size',
                      value: '${(textScale * 100).round()} percent',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Text size: ${(textScale * 100).round()}%',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Slider(
                            key: const ValueKey('settings-text-scale'),
                            value: textScale,
                            min: 1,
                            max: 1.3,
                            divisions: 3,
                            label: '${(textScale * 100).round()}%',
                            onChanged: onTextScaleChanged,
                          ),
                        ],
                      ),
                    ),
                    SwitchListTile(
                      key: const ValueKey('settings-high-contrast'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'High contrast',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: const Text(
                        'Strengthens borders, controls and focus visibility.',
                      ),
                      secondary: const Icon(Icons.contrast),
                      value: highContrast,
                      onChanged: onHighContrastChanged,
                    ),
                    SwitchListTile(
                      key: const ValueKey('settings-reduced-motion'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Reduce motion',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: const Text(
                        'Requests reduced interface animation for this workspace.',
                      ),
                      secondary: const Icon(Icons.motion_photos_off_outlined),
                      value: reducedMotion,
                      onChanged: onReducedMotionChanged,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        key: const ValueKey('settings-reset'),
                        onPressed: onReset,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset preferences'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Heading(
                      icon: Icons.lock_clock_outlined,
                      text: 'Current secure session',
                    ),
                    const SizedBox(height: 16),
                    _SessionRow(label: 'Signed in as', value: user.displayName),
                    _SessionRow(label: 'Email', value: user.email),
                    _SessionRow(
                      label: 'Role',
                      value:
                          user.singleRole?.label ??
                          'Unsupported multiple roles',
                    ),
                    _SessionRow(
                      label: 'Session expires',
                      value: expiresAtUtc == null
                          ? 'Not available'
                          : _dateTime(expiresAtUtc!.toLocal()),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'The access token is kept in application memory. Refreshing the browser or signing out clears the local session.',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ),
    ],
  );
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 145,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

String _dateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
