// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

/// Explicitly releases camera tracks attached to web video elements.
///
/// Some browser scanner implementations stop decoding without stopping the
/// underlying MediaStreamTrack, which leaves Chrome's camera light active.
Future<void> stopBrowserCameraTracks() async {
  for (final element in html.document.querySelectorAll('video')) {
    if (element is! html.VideoElement) continue;
    final stream = element.srcObject;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
      element.srcObject = null;
    }
    element.pause();
  }
}
