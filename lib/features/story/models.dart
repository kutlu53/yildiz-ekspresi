import 'package:flutter/widgets.dart';

import 'lines.dart';

/// Pamuk'un ruh hâli; vektör çizim ve animasyon buna göre değişir.
enum PamukMood { idle, sleepy, happy, thinking, talking }

/// Durakların dekoru. Her durak kendi dünyasında geçer.
enum Scenery {
  station,
  garage,
  track,
  bridge,
  tunnel,
  hall,
  cabin,
  market,
  valley,
  snowfield,
  summit,
  den,
}

/// Saatin dünyadaki yuvası: kabin paneli, istasyon direği, köprü kulesi,
/// tünel feneri.
enum ClockFrameStyle { cab, post, tower, lantern, gold, ice }

/// Sinematik bir çekim: dekor, Pamuk'un hâli, bir replik ve süre.
class CinematicShot {
  final Line? line;
  final PamukMood mood;
  final Duration duration;
  final Scenery? scenery;
  final bool showTrain;
  final bool trainMoving;
  final bool showPamuk;

  /// Rafta görünen vagon eşyaları (final: eşyalar yuvaya taşınır).
  final List<VagonItem> items;

  /// Jenerik çekimi: başlık ve teşekkür yazısı.
  final bool credits;

  const CinematicShot({
    this.line,
    this.mood = PamukMood.idle,
    this.duration = const Duration(seconds: 3),
    this.scenery,
    this.showTrain = true,
    this.trainMoving = false,
    this.showPamuk = true,
    this.items = const [],
    this.credits = false,
  });
}

/// Bir sahnenin ilerleme kancaları. Mekanikler bunları çağırır.
abstract class SceneController {
  /// Sahne tamamlandı; motor bir sonraki sahneye geçer.
  void complete();

  /// Çocuk yanlış yaptı; aralıklı tekrar için işaretlenir.
  void mistake();

  /// Pamuk konuşur (balon + TTS).
  Future<void> say(Line line);

  /// Serbest metin okur (ör. sayı sayma).
  Future<void> sayText(String text);
}

class Scene {
  final String id;
  final Widget Function(BuildContext context, SceneController controller) build;

  const Scene({required this.id, required this.build});
}

/// Vagona eklenen eşya; yolculukta ve finalde görünür.
class VagonItem {
  final String id;
  final String name;
  final IconData icon;

  const VagonItem({required this.id, required this.name, required this.icon});
}

class Station {
  final int number;
  final String title;
  final String place;
  final Scenery scenery;
  final ClockFrameStyle clockFrame;
  final List<CinematicShot> intro;
  final List<Scene> scenes;
  final List<CinematicShot> outro;
  final VagonItem reward;

  /// Yola çıkarken Pamuk'un söylediği replik (bir önceki duraktan buraya).
  final Line travelLine;

  /// Gökyüzü ilerlemesi için 0 (sonbahar) - 1 (kış).
  double get season => (number - 1) / 9;

  const Station({
    required this.number,
    required this.title,
    required this.place,
    required this.scenery,
    required this.clockFrame,
    required this.intro,
    required this.scenes,
    required this.outro,
    required this.reward,
    required this.travelLine,
  });

  String sceneKey(int index) => '$number.${scenes[index].id}';
}
