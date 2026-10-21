import 'dart:async';

import 'package:flutter/widgets.dart';

import 'pose_frame.dart';
import 'pose_source.dart';

/// Web dışı platformlar için geçici kaynak. Faz 2'de mobil tarafta
/// `google_mlkit_pose_detection` ile değiştirilecek.
class _UnsupportedPoseSource implements PoseSource {
  final _controller = StreamController<PoseFrame>.broadcast();

  @override
  bool get isSupported => false;

  @override
  String get unsupportedReason =>
      'Kamera modu bu cihazda henüz hazır değil. Faz 0 testi web (Chrome) '
      'üzerinde yapılıyor.';

  @override
  Stream<PoseFrame> get frames => _controller.stream;

  @override
  Widget buildPreview() => const SizedBox.shrink();

  @override
  Future<void> start() async {
    throw UnsupportedError(unsupportedReason);
  }

  @override
  Future<void> stop() async {}

  @override
  void dispose() {
    _controller.close();
  }
}

PoseSource createPoseSource() => _UnsupportedPoseSource();
