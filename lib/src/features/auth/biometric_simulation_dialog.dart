import 'package:flutter/material.dart';

enum _SimulationState { ready, scanning, succeeded, failed }

/// Demonstrates the proposed biometric user journey without authenticating.
///
/// No camera, fingerprint reader, Windows Hello API, or biometric data is used.
class BiometricSimulationDialog extends StatefulWidget {
  const BiometricSimulationDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const BiometricSimulationDialog(),
  );

  @override
  State<BiometricSimulationDialog> createState() =>
      _BiometricSimulationDialogState();
}

class _BiometricSimulationDialogState extends State<BiometricSimulationDialog> {
  _SimulationState _state = _SimulationState.ready;

  Future<void> _scan({required bool succeeds}) async {
    setState(() => _state = _SimulationState.scanning);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      setState(() {
        _state = succeeds
            ? _SimulationState.succeeded
            : _SimulationState.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scanning = _state == _SimulationState.scanning;
    final succeeded = _state == _SimulationState.succeeded;
    final failed = _state == _SimulationState.failed;

    return AlertDialog(
      key: const ValueKey('biometric-simulation-dialog'),
      title: const Text('Biometric sign-in simulation'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: succeeded
                    ? scheme.primaryContainer
                    : failed
                    ? scheme.errorContainer
                    : scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: scanning
                    ? const SizedBox.square(
                        dimension: 58,
                        child: CircularProgressIndicator(strokeWidth: 5),
                      )
                    : Icon(
                        succeeded
                            ? Icons.verified_user_outlined
                            : failed
                            ? Icons.face_retouching_off_outlined
                            : Icons.face_retouching_natural_outlined,
                        size: 62,
                        color: failed ? scheme.error : scheme.primary,
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              scanning
                  ? 'Simulating device verification…'
                  : succeeded
                  ? 'Simulation successful'
                  : failed
                  ? 'Simulation could not verify the user'
                  : 'Preview how device biometric verification would appear.',
              key: const ValueKey('biometric-simulation-status'),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              succeeded
                  ? 'In the proposed real version, Windows Hello would return a '
                        'signed passkey result. Continue with your password in '
                        'this prototype.'
                  : 'Demonstration only: no camera, face, fingerprint, or '
                        'Windows Hello data is accessed. This does not sign you in.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('close-biometric-simulation'),
          onPressed: scanning ? null : () => Navigator.of(context).pop(),
          child: Text(succeeded ? 'Continue to password' : 'Cancel'),
        ),
        if (!succeeded)
          TextButton(
            key: const ValueKey('simulate-biometric-failure'),
            onPressed: scanning ? null : () => _scan(succeeds: false),
            child: const Text('Show failure'),
          ),
        if (!succeeded)
          FilledButton.icon(
            key: const ValueKey('start-biometric-simulation'),
            onPressed: scanning ? null : () => _scan(succeeds: true),
            icon: const Icon(Icons.face_outlined),
            label: Text(scanning ? 'Scanning…' : 'Start simulation'),
          ),
      ],
    );
  }
}
