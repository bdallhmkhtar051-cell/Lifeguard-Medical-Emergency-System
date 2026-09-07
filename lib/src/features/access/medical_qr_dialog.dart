import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/network/api_exception.dart';
import 'access_models.dart';
import 'access_repository.dart';

/// Displays a real server-issued link. The doctor must still authenticate
/// before the one-use token can create a short emergency access grant.
class MedicalQrDialog extends StatefulWidget {
  const MedicalQrDialog({required this.repository, super.key});

  final AccessRepository repository;

  @override
  State<MedicalQrDialog> createState() => _MedicalQrDialogState();
}

class _MedicalQrDialogState extends State<MedicalQrDialog> {
  MedicalQrAccess? _access;
  String? _error;
  bool _busy = true;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _issue();
  }

  Future<void> _issue() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final access = await widget.repository.issueMedicalQr();
      if (mounted) setState(() => _access = access);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _link {
    final parameters = Map<String, String>.from(Uri.base.queryParameters)
      ..remove('medicalQr');
    return Uri.base
        .replace(
          queryParameters: parameters.isEmpty ? null : parameters,
          fragment: 'medicalQr=${Uri.encodeQueryComponent(_access!.token)}',
        )
        .toString();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _link));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Secure QR link copied.')));
  }

  Future<void> _close() async {
    if (_closing) return;
    setState(() => _closing = true);
    try {
      if (_access != null) await widget.repository.revokeMedicalQr();
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Secure Medical ID QR'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: _busy
                ? const Padding(
                    padding: EdgeInsets.all(42),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                ? _QrError(message: _error!, onRetry: _issue)
                : _QrContent(access: _access!, link: _link),
          ),
        ),
        actions: [
          if (_access != null && !_busy)
            TextButton.icon(
              onPressed: _closing ? null : _copy,
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copy link'),
            ),
          FilledButton.icon(
            onPressed: _closing ? null : _close,
            icon: const Icon(Icons.lock_outline),
            label: Text(_closing ? 'Revoking…' : 'Close and revoke'),
          ),
        ],
      ),
    );
  }
}

class _QrContent extends StatelessWidget {
  const _QrContent({required this.access, required this.link});

  final MedicalQrAccess access;
  final String link;

  @override
  Widget build(BuildContext context) {
    final expiry = access.expiresAt.toLocal();
    final minute = expiry.minute.toString().padLeft(2, '0');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: QrImageView(
            data: link,
            version: QrVersions.auto,
            size: 240,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            semanticsLabel: 'One-use LifeGuard Medical ID QR code',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'A doctor scans this code, signs in, and receives 15 minutes of audited access. The code works once only.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'EXPIRES ${expiry.hour}:$minute',
          style: const TextStyle(
            color: Color(0xFFB91C1C),
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _QrError extends StatelessWidget {
  const _QrError({required this.message, required this.onRetry});

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
    : 'The secure QR could not be created.';
