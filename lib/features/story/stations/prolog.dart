import '../lines.dart';
import '../models.dart';

/// Prolog: Pamuk garda uyanır, saatinin elleri düşmüştür.
const prologShots = <CinematicShot>[
  CinematicShot(
    line: Lines.prologWake,
    mood: PamukMood.sleepy,
    duration: Duration(seconds: 4),
    showTrain: false,
  ),
  CinematicShot(
    line: Lines.prologClock,
    mood: PamukMood.thinking,
    duration: Duration(seconds: 4),
    showTrain: false,
  ),
  CinematicShot(
    line: Lines.prologSnow,
    mood: PamukMood.happy,
    duration: Duration(seconds: 5),
    showTrain: false,
  ),
  CinematicShot(
    line: Lines.prologGo,
    mood: PamukMood.happy,
    duration: Duration(seconds: 3),
    showTrain: false,
  ),
];
