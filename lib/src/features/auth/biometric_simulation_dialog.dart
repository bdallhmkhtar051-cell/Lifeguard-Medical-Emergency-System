import 'package:flutter/material.dart';

enum _SimulationState { ready, scanning, succeeded, failed }

enum _BiometricMethod { face, fingerprint }

/// Visual thesis demonstration; no real biometric information is accessed.
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

class _BiometricSimulationDialogState extends State<BiometricSimulationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanner = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  _SimulationState _state = _SimulationState.ready;
  _BiometricMethod _method = _BiometricMethod.face;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _selectMethod(_BiometricMethod value) {
    if (_state == _SimulationState.scanning) return;
    _scanner.reset();
    setState(() {
      _method = value;
      _state = _SimulationState.ready;
    });
  }

  Future<void> _scan({required bool succeeds}) async {
    if (_state == _SimulationState.scanning) return;
    setState(() => _state = _SimulationState.scanning);
    _scanner.repeat(reverse: true);
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    _scanner.stop();
    setState(
      () => _state = succeeds
          ? _SimulationState.succeeded
          : _SimulationState.failed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanning = _state == _SimulationState.scanning;
    final succeeded = _state == _SimulationState.succeeded;
    final methodName = _method == _BiometricMethod.face
        ? 'Face recognition'
        : 'Fingerprint scan';
    return Dialog(
      key: const ValueKey('biometric-simulation-dialog'),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const _HeaderIcon(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure biometric access',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'LifeGuard identity verification',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('close-biometric-simulation'),
                    onPressed: scanning
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SegmentedButton<_BiometricMethod>(
                segments: const [
                  ButtonSegment(
                    value: _BiometricMethod.face,
                    icon: Icon(Icons.face_retouching_natural_outlined),
                    label: Text('Face scan'),
                  ),
                  ButtonSegment(
                    value: _BiometricMethod.fingerprint,
                    icon: Icon(Icons.fingerprint),
                    label: Text('Fingerprint'),
                  ),
                ],
                selected: {_method},
                onSelectionChanged: scanning
                    ? null
                    : (selection) => _selectMethod(selection.first),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                key: const ValueKey('biometric-scan-area'),
                onTap: scanning || succeeded
                    ? null
                    : () => _scan(succeeds: true),
                child: _ScanStage(
                  method: _method,
                  state: _state,
                  animation: _scanner,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _statusText(methodName),
                key: const ValueKey('biometric-simulation-status'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thesis demonstration only: the camera and fingerprint reader '
                'are not accessed, no biometric data is saved, and password '
                'sign-in remains required.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 18),
              if (!succeeded)
                FilledButton.icon(
                  key: const ValueKey('start-biometric-simulation'),
                  onPressed: scanning ? null : () => _scan(succeeds: true),
                  icon: Icon(
                    _method == _BiometricMethod.face
                        ? Icons.center_focus_strong
                        : Icons.fingerprint,
                  ),
                  label: Text(scanning ? 'Verifying...' : 'Begin $methodName'),
                )
              else
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('Continue to password sign-in'),
                ),
              if (!scanning && !succeeded) ...[
                const SizedBox(height: 6),
                TextButton(
                  key: const ValueKey('simulate-biometric-failure'),
                  onPressed: () => _scan(succeeds: false),
                  child: const Text('Demonstrate an unsuccessful scan'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(String methodName) => switch (_state) {
    _SimulationState.ready => 'Ready for $methodName',
    _SimulationState.scanning => 'Checking identity...',
    _SimulationState.succeeded => 'Biometric verification successful',
    _SimulationState.failed =>
      'No match found. Reposition and try $methodName again.',
  };
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.shield_outlined, color: Color(0xFF2563EB)),
  );
}

class _ScanStage extends StatelessWidget {
  const _ScanStage({
    required this.method,
    required this.state,
    required this.animation,
  });
  final _BiometricMethod method;
  final _SimulationState state;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final scanning = state == _SimulationState.scanning;
    final succeeded = state == _SimulationState.succeeded;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 270,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071426), Color(0xFF10294B)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: succeeded ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          if (method == _BiometricMethod.face)
            _FaceScanner(animation: animation, scanning: scanning)
          else
            _FingerprintScanner(animation: animation, scanning: scanning),
          if (succeeded)
            Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                color: Color(0xE610B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 72,
              ),
            ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 14,
            child: Text(
              scanning
                  ? 'SCANNING BIOMETRIC PATTERN...'
                  : succeeded
                  ? 'IDENTITY MATCH CONFIRMED'
                  : method == _BiometricMethod.face
                  ? 'Position your face inside the frame'
                  : 'Touch the fingerprint sensor',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: succeeded
                    ? const Color(0xFF6EE7B7)
                    : const Color(0xFFBAE6FD),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceScanner extends StatelessWidget {
  const _FaceScanner({required this.animation, required this.scanning});
  final Animation<double> animation;
  final bool scanning;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 178,
    height: 190,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF38BDF8), width: 2),
            borderRadius: BorderRadius.circular(46),
          ),
        ),
        const Icon(
          Icons.face_retouching_natural_outlined,
          color: Color(0xFF7DD3FC),
          size: 126,
        ),
        if (scanning)
          AnimatedBuilder(
            animation: animation,
            builder: (_, child) => Align(
              alignment: Alignment(0, -0.82 + (animation.value * 1.64)),
              child: child,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF34D399),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF34D399), blurRadius: 12),
                ],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    ),
  );
}

class _FingerprintScanner extends StatelessWidget {
  const _FingerprintScanner({required this.animation, required this.scanning});
  final Animation<double> animation;
  final bool scanning;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (_, __) => Transform.scale(
      scale: scanning ? .85 + (animation.value * .15) : 1,
      child: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          color: const Color(0xFF0C4A6E).withValues(alpha: .45),
          shape: BoxShape.circle,
          border: Border.all(
            color: scanning ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
            width: 3,
          ),
        ),
        child: const Icon(
          Icons.fingerprint,
          color: Color(0xFF7DD3FC),
          size: 116,
        ),
      ),
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: .06)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
