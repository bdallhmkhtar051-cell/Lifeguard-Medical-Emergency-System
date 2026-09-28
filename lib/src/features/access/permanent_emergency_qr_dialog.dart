import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/network/api_exception.dart';
import '../../core/platform/browser_print.dart';
import 'access_models.dart';
import 'access_repository.dart';

/// Shows the patient's reusable emergency identifier.
/// Scanning this code identifies a patient; it never authorizes record access.
class PermanentEmergencyQrDialog extends StatefulWidget {
  const PermanentEmergencyQrDialog({
    required this.repository,
    required this.patientName,
    super.key,
  });

  final AccessRepository repository;
  final String patientName;

  @override
  State<PermanentEmergencyQrDialog> createState() =>
      _PermanentEmergencyQrDialogState();
}

class _PermanentEmergencyQrDialogState
    extends State<PermanentEmergencyQrDialog> {
  EmergencyMedicalId? _medicalId;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final medicalId = await widget.repository.emergencyMedicalId();
      if (mounted) setState(() => _medicalId = medicalId);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rotate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace permanent emergency QR?'),
        content: const Text(
          'The current QR will stop working immediately. Any card, bracelet, '
          'screenshot, or printed copy using it must be replaced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep current QR'),
          ),
          FilledButton(
            key: const ValueKey('confirm-rotate-emergency-qr'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace QR'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final replacement = await widget.repository.rotateEmergencyMedicalId();
      if (!mounted) return;
      setState(() => _medicalId = replacement);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permanent emergency QR replaced. Old copies no longer work.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _print() {
    if (printCurrentPage()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Printing is available in the web application.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.health_and_safety_outlined, color: Color(0xFF0F766E)),
          SizedBox(width: 10),
          Expanded(child: Text('Permanent Emergency Medical ID')),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(42),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
              ? _EmergencyQrError(message: _error!, onRetry: _load)
              : _EmergencyQrContent(
                  medicalId: _medicalId!,
                  patientName: widget.patientName,
                ),
        ),
      ),
      actions: [
        if (_medicalId != null && !_loading && _error == null)
          TextButton.icon(
            key: const ValueKey('rotate-emergency-qr'),
            onPressed: _rotate,
            icon: const Icon(Icons.sync_lock_outlined),
            label: const Text('Replace QR'),
          ),
        if (_medicalId != null && !_loading && _error == null)
          OutlinedButton.icon(
            key: const ValueKey('print-emergency-card'),
            onPressed: _print,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print card'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _EmergencyQrContent extends StatelessWidget {
  const _EmergencyQrContent({
    required this.medicalId,
    required this.patientName,
  });

  final EmergencyMedicalId medicalId;
  final String patientName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: const ValueKey('printable-emergency-id-card'),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0FDFA), Colors.white],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF5EEAD4), width: 2),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.health_and_safety,
                    color: Color(0xFF0F766E),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'LIFEGUARD EMERGENCY ID',
                    style: TextStyle(
                      color: Color(0xFF115E59),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                patientName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(10),
                child: QrImageView(
                  key: ValueKey('emergency-qr-${medicalId.id}'),
                  data: medicalId.qrPayload,
                  version: QrVersions.auto,
                  size: 220,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  semanticsLabel:
                      'Permanent LifeGuard emergency identification QR',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'IDENTIFICATION ONLY • RECORD REMAINS LOCKED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0F766E),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                medicalId.id.toUpperCase(),
                key: const ValueKey('permanent-emergency-id-value'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'This reusable code can be printed on an emergency card or bracelet. '
          'It helps an authenticated doctor identify the patient, but it does not unlock the medical record.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, color: Color(0xFFC2410C), size: 19),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Medical information remains locked. Emergency access still requires a documented, time-limited break-glass action.',
                  style: TextStyle(color: Color(0xFF9A3412), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmergencyQrError extends StatelessWidget {
  const _EmergencyQrError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 40),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}

String _message(Object error) => error is ApiException
    ? error.message
    : 'The permanent emergency ID could not be loaded.';
