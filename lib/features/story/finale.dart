import 'lines.dart';
import 'models.dart';
import 'stations/stations.dart';

/// Final sinematiği: kapı açılır, Pamuk vagondaki eşyaları yuvaya taşır,
/// pencereden ilk kar, Pamuk uyur, çocuk treni yıldızların altında geri
/// sürer, jenerik. `itemIds` çocuğun topladığı vagon eşyaları.
List<CinematicShot> finalShots(List<String> itemIds) {
  final items = [
    for (final id in itemIds) ?StationRegistry.itemById(id),
  ];
  return [
    const CinematicShot(
      line: Lines.finalDoor,
      mood: PamukMood.happy,
      duration: Duration(seconds: 5),
      scenery: Scenery.den,
      showTrain: false,
    ),
    CinematicShot(
      line: Lines.finalItems,
      mood: PamukMood.happy,
      duration: const Duration(seconds: 7),
      scenery: Scenery.den,
      showTrain: false,
      items: items,
    ),
    CinematicShot(
      line: Lines.finalSnow,
      mood: PamukMood.thinking,
      duration: const Duration(seconds: 5),
      scenery: Scenery.den,
      showTrain: false,
      items: items,
    ),
    CinematicShot(
      line: Lines.finalThanks,
      mood: PamukMood.sleepy,
      duration: const Duration(seconds: 6),
      scenery: Scenery.den,
      showTrain: false,
      items: items,
    ),
    const CinematicShot(
      duration: Duration(seconds: 6),
      scenery: Scenery.track,
      trainMoving: true,
      showPamuk: false,
    ),
    const CinematicShot(
      line: Lines.finalCredits,
      duration: Duration(seconds: 10),
      scenery: Scenery.track,
      showTrain: false,
      showPamuk: false,
      credits: true,
    ),
  ];
}
