import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/platform/browser_camera_cleanup.dart';

typedef MedicalQrScannerViewBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onDetected);
typedef CameraCleanup = Future<void> Function();

enum MedicalQrScanKind { temporaryConsent, permanentEmergency }

class MedicalQrScanResult {
  const MedicalQrScanResult({required this.kind, required this.value});

  final MedicalQrScanKind kind;
  final String value;
}

/// Uses the browser camera to read a LifeGuard Medical ID QR link.
class MedicalQrScannerDialog extends StatefulWidget {
  const MedicalQrScannerDialog({
    this.scannerBuilder,
    this.expectedBaseUri,
    this.cameraCleanup,
    super.key,
  });

  // The builder is a small test seam; production always uses MobileScanner.
  final MedicalQrScannerViewBuilder? scannerBuilder;
  final Uri? expectedBaseUri;
  final CameraCleanup? cameraCleanup;

  @override
  State<MedicalQrScannerDialog> createState() => _MedicalQrScannerDialogState();
}

class _MedicalQrScannerDialogState extends State<MedicalQrScannerDialog> {
  MobileScannerController? _controller;
  String? _error;
  bool _accepted = false;
  bool _closing = false;

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

  Future<void> _handleValue(String value) async {
    if (_accepted || _closing) return;
    final result = parseMedicalQr(
      value,
      expectedBaseUri: widget.expectedBaseUri ?? Uri.base,
    );
    if (result == null) {
      setState(() {
        _error = 'This is not a valid LifeGuard Medical ID QR code.';
      });
      return;
    }

    _accepted = true;
    await _close(result);
  }

  Future<void> _close([MedicalQrScanResult? result]) async {
    if (_closing) return;
    setState(() => _closing = true);
    final controller = _controller;
    try {
      await controller?.stop();
    } catch (_) {
      // Continue to the browser-level track cleanup below.
    }
    try {
      await (widget.cameraCleanup ?? stopBrowserCameraTracks)();
    } catch (_) {
      // Continue to controller disposal below.
    }
    try {
      await controller?.dispose();
    } catch (_) {
      // State disposal remains the final camera-release safeguard.
    }
    _controller = null;
    if (mounted) Navigator.pop(context, result);
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customScanner = widget.scannerBuilder;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final previewHeight = (viewportHeight * .46).clamp(180.0, 360.0);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        // Short browser windows scroll instead of overflowing vertically.
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: const Text('Scan Medical ID QR'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: previewHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (customScanner != null)
                        customScanner(context, _handleValue)
                      else
                        MobileScanner(
                          controller: _controller,
                          onDetect: _handleCapture,
                          errorBuilder: (_, error) =>
                              _CameraError(error: error),
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
                'Scan either a temporary consent QR or a permanent emergency ID. '
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
            onPressed: _closing ? null : () => unawaited(_close()),
            child: Text(_closing ? 'Closing…' : 'Cancel'),
          ),
        ],
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = (constraints.biggest.shortestSide * .64).clamp(120.0, 230.0);
      return IgnorePointer(
        child: Center(
          child: Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2DD4BF), width: 4),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
      );
    },
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

/// Classifies both supported LifeGuard QR formats before calling the API.
MedicalQrScanResult? parseMedicalQr(
  String scannedValue, {
  required Uri expectedBaseUri,
}) {
  final normalized = scannedValue.trim();
  if (RegExp(r'^LIFEGUARD:EMERGENCY:1:[0-9a-fA-F]{32}$').hasMatch(normalized)) {
    return MedicalQrScanResult(
      kind: MedicalQrScanKind.permanentEmergency,
      value: normalized,
    );
  }

  final token = extractMedicalQrToken(
    normalized,
    expectedBaseUri: expectedBaseUri,
  );
  return token == null
      ? null
      : MedicalQrScanResult(
          kind: MedicalQrScanKind.temporaryConsent,
          value: token,
        );
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
