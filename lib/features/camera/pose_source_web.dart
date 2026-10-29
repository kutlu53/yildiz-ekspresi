import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'pose_frame.dart';
import 'pose_source.dart';

/// `web/pose.js` içinde tanımlanan `window.zamanPose` nesnesi.
extension type _ZamanPoseApi._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> start(web.HTMLVideoElement video, JSFunction cb);
  external void stop();
}

@JS('zamanPose')
external JSObject? get _zamanPoseRaw;

class _WebPoseSource implements PoseSource {
  static const _viewType = 'zaman-pose-video';
  static bool _factoryRegistered = false;

  final _controller = StreamController<PoseFrame>.broadcast();
  web.HTMLVideoElement? _video;
  JSFunction? _callback;
  bool _running = false;

  _WebPoseSource() {
    _registerFactory();
  }

  void _registerFactory() {
    if (_factoryRegistered) return;
    _factoryRegistered = true;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final video = web.HTMLVideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true');
      video.style
        ..width = '100%'
        ..height = '100%'
        ..objectFit = 'fill'
        ..transform = 'scaleX(-1)';
      _video = video;
      return video;
    });
  }

  @override
  bool get isSupported => true;

  @override
  String get unsupportedReason => '';

  @override
  Stream<PoseFrame> get frames => _controller.stream;

  @override
  Widget buildPreview() => const HtmlElementView(viewType: _viewType);

  Future<_ZamanPoseApi> _waitForApi() async {
    for (var i = 0; i < 100; i++) {
      final raw = _zamanPoseRaw;
      if (raw != null) return _ZamanPoseApi._(raw);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError(
        'pose.js yüklenemedi (zamanPose bulunamadı); internet ya da engellenen CDN.');
  }

  Future<web.HTMLVideoElement> _waitForVideo() async {
    for (var i = 0; i < 50; i++) {
      final v = _video;
      if (v != null) return v;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    throw StateError('Video öğesi oluşturulamadı; önizleme ekranda olmalı.');
  }

  @override
  Future<void> start() async {
    if (_running) return;
    final api = await _waitForApi();
    final video = await _waitForVideo();

    _callback = (JSArray<JSNumber> points, JSNumber fps, JSNumber width,
        JSNumber height) {
      if (_controller.isClosed) return;
      final pts = points.toDart.map((n) => n.toDartDouble).toList();
      _controller.add(PoseFrame.fromLandmarks(
        pts,
        fps: fps.toDartDouble,
        videoWidth: width.toDartDouble,
        videoHeight: height.toDartDouble,
      ));
    }.toJS;

    await api.start(video, _callback!).toDart;
    _running = true;
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    final raw = _zamanPoseRaw;
    if (raw != null) _ZamanPoseApi._(raw).stop();
  }

  @override
  void dispose() {
    stop();
    _controller.close();
  }
}

PoseSource createPoseSource() => _WebPoseSource();
