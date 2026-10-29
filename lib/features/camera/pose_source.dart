import 'package:flutter/widgets.dart';

import 'pose_frame.dart';
import 'pose_source_stub.dart'
    if (dart.library.js_interop) 'pose_source_web.dart' as impl;

/// Kameradan poz okuyan kaynak. Platforma göre farklı uygulanır:
/// web'de MediaPipe (JS köprüsü), mobilde ML Kit (henüz eklenmedi).
///
/// Gizlilik: görüntü yalnızca cihazda işlenir; hiçbir uygulama kareleri
/// diske veya ağa yazmaz.
abstract class PoseSource {
  /// Bu platformda kamera modu kullanılabilir mi?
  bool get isSupported;

  /// Desteklenmiyorsa kullanıcıya gösterilecek Türkçe açıklama.
  String get unsupportedReason;

  /// Her kamera karesi için bir okuma.
  Stream<PoseFrame> get frames;

  /// Ayna görünümlü kamera önizlemesi. Oranı [PoseFrame.aspectRatio] verir.
  Widget buildPreview();

  /// Kamerayı açar ve model yükler. İzin reddi vb. durumda hata fırlatır.
  Future<void> start();

  Future<void> stop();

  void dispose();
}

PoseSource createPoseSource() => impl.createPoseSource();

/// Kamera açılamayınca çocuğa/öğretmene okunacak Türkçe açıklama.
String describeCameraError(Object e) {
  final text = e.toString();
  if (text.contains('NotAllowedError') || text.contains('Permission')) {
    return 'Kamera izni verilmedi. Tarayıcı adres çubuğundan kameraya izin '
        'verip yeniden dene.';
  }
  if (text.contains('NotFoundError')) {
    return 'Bu cihazda kamera bulunamadı.';
  }
  if (text.contains('NotReadableError') || text.contains('TrackStartError')) {
    return 'Kamera başka bir uygulama tarafından kullanılıyor.';
  }
  if (text.contains('mediaDevices') || text.contains('https')) {
    return 'Kamera yalnız güvenli bağlantıda (https) açılır.';
  }
  if (text.contains('zamanPose') || text.contains('pose.js')) {
    return 'Kamera modülü yüklenemedi; ilk açılışta internet bağlantısı gerekir.';
  }
  return 'Kamera başlatılamadı: $text';
}
