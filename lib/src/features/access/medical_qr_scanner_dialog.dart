import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef MedicalQrScannerViewBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onDetected);

/// Uses the browser camera to read a LifeGuard Medical ID QR link.
class MedicalQrScannerDialog extends StatefulWidget {
  const MedicalQrScannerDialog({
    this.scannerBuilder,
    this.expectedBaseUri,
    super.key,
  });

  // The builder is a small test seam; production always uses MobileScanner.
  final MedicalQrScannerViewBuilder? scannerBuilder;
  final Uri? expectedBaseUri;

  @override
  State<MedicalQrScannerDialog> createState() => _MedicalQrScannerDialogState();
}

class _MedicalQrScannerDialogState extends State<MedicalQrScannerDialog> {
  MobileScannerController? _controller;
  String? _error;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    if (widget.scannerBuilder == null) {
      _controller = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
  }

  void _handleCapture(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        _handleValue(value);
        return;
      }
    }
  }

  void _handleValue(String value) {
    if (_accepted) return;
    final token = extractMedicalQrToken(
      value,
      expectedBaseUri: widget.expectedBaseUri ?? Uri.base,
    );
    if (token == null) {
      setState(() {
        _error = 'This is not a valid LifeGuard Medical ID QR code.';
      });
      return;
    }

    _accepted = true;
    unawaited(_controller?.stop());
    Navigator.pop(context, token);
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customScanner = widget.scannerBuilder;
    return AlertDialog(
      title: const Text('Scan Medical ID QR'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (customScanner != null)
                      customScanner(context, _handleValue)
                    else
                      MobileScanner(
                        controller: _controller,
                        onDetect: _handleCapture,
                        errorBuilder: (_, error) => _CameraError(error: error),
                        placeholderBuilder: (_) => const ColoredBox(
                          color: Color(0xFF020617),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    const _ScannerFrame(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Hold the patient’s LifeGuard QR code inside the frame. '
              'Chrome may ask for camera permission.',
              textAlign: TextAlign.center,
            ),
            if (_error case final message?) ...[
              const SizedBox(height: 10),
              Text(
                message,
                key: const ValueKey('scanner-error'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Center(
      child: Container(
        width: 230,
        height: 230,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2DD4BF), width: 4),
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    ),
  );
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF0F172A),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white,
            size: 44,
          ),
          const SizedBox(height: 12),
          const Text(
            'Camera unavailable',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            error.errorCode.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Allow camera access in Chrome and open the scanner again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFCBD5E1)),
          ),
        ],
      ),
    ),
  );
}

/// Rejects unrelated QR codes before any token is sent to the API.
String? extractMedicalQrToken(
  String scannedValue, {
  required Uri expectedBaseUri,
}) {
  final uri = Uri.tryParse(scannedValue.trim());
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  if (!_sameWebOrigin(uri, expectedBaseUri)) {
    return null;
  }

  String? token;
  if (uri.fragment.isNotEmpty) {
    try {
      token = Uri.splitQueryString(uri.fragment)['medicalQr'];
    } on FormatException {
      return null;
    }
  }
  token ??= uri.queryParameters['medicalQr'];
  final normalized = token?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

bool _sameWebOrigin(Uri first, Uri second) {
  const webSchemes = {'http', 'https'};
  if (!webSchemes.contains(first.scheme.toLowerCase()) ||
      !webSchemes.contains(second.scheme.toLowerCase())) {
    return false;
  }
  return first.scheme.toLowerCase() == second.scheme.toLowerCase() &&
      first.host.toLowerCase() == second.host.toLowerCase() &&
      first.port == second.port;
}
