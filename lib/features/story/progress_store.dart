import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihazda yerel ilerleme. Sunucu yok. Her öğrencinin kendi kaydı vardır
/// (sınıf tableti); öğretmen panelinden öğrenci seçilir.
class Progress {
  /// Tamamlanan en yüksek durak numarası (0: hiçbiri).
  int completedStation;

  /// Yarım kalan durak için sahne indeksi (durak numarası → indeks).
  Map<int, int> sceneIndex;

  /// Toplanan vagon eşyası kimlikleri.
  List<String> items;

  /// Yanlış yapılan sahneler, sonraki oturumda ısınma olarak gelir.
  List<String> retryScenes;

  /// Sahne anahtarı → toplam hata sayısı (öğretmen raporu).
  Map<String, int> mistakes;

  /// Sınıf ön ayarı: 2, 3, 4 ya da null (tümü).
  int? grade;

  /// Kol Saati mini oyununda en iyi puan.
  int armClockBest;

  bool teacherUnlockedAll;
  bool prologSeen;

  Progress({
    this.completedStation = 0,
    Map<int, int>? sceneIndex,
    List<String>? items,
    List<String>? retryScenes,
    Map<String, int>? mistakes,
    this.grade,
    this.armClockBest = 0,
    this.teacherUnlockedAll = false,
    this.prologSeen = false,
  })  : sceneIndex = sceneIndex ?? {},
        items = items ?? [],
        retryScenes = retryScenes ?? [],
        mistakes = mistakes ?? {};

  int get currentStation => completedStation + 1;

  bool isUnlocked(int station) =>
      teacherUnlockedAll || station <= currentStation;

  Map<String, dynamic> toJson() => {
        'completedStation': completedStation,
        'sceneIndex': sceneIndex.map((k, v) => MapEntry('$k', v)),
        'items': items,
        'retryScenes': retryScenes,
        'mistakes': mistakes,
        'grade': grade,
        'armClockBest': armClockBest,
        'teacherUnlockedAll': teacherUnlockedAll,
        'prologSeen': prologSeen,
      };

  static Progress fromJson(Map<String, dynamic> j) => Progress(
        completedStation: j['completedStation'] as int? ?? 0,
        sceneIndex: (j['sceneIndex'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(int.parse(k), v as int)),
        items: (j['items'] as List<dynamic>? ?? []).cast<String>(),
        retryScenes:
            (j['retryScenes'] as List<dynamic>? ?? []).cast<String>(),
        mistakes: (j['mistakes'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as int)),
        grade: j['grade'] as int?,
        armClockBest: j['armClockBest'] as int? ?? 0,
        teacherUnlockedAll: j['teacherUnlockedAll'] as bool? ?? false,
        prologSeen: j['prologSeen'] as bool? ?? false,
      );
}

class ProgressStore extends ChangeNotifier {
  static const _key = 'progress.v1';
  static const _rosterKey = 'roster.v1';
  static const defaultStudent = 'Öğrenci';
  static final ProgressStore instance = ProgressStore._();

  ProgressStore._();

  Progress _progress = Progress();
  bool _loaded = false;
  List<String> _students = [defaultStudent];
  String _current = defaultStudent;

  Progress get progress => _progress;
  bool get loaded => _loaded;
  List<String> get students => List.unmodifiable(_students);
  String get currentStudent => _current;

  /// Varsayılan öğrenci eski anahtarı kullanır; diğerleri ada göre ayrılır.
  String _keyFor(String name) =>
      name == defaultStudent ? _key : '$_key.${base64Url.encode(utf8.encode(name))}';

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final roster = prefs.getString(_rosterKey);
      if (roster != null) {
        final j = jsonDecode(roster) as Map<String, dynamic>;
        _students = (j['students'] as List<dynamic>).cast<String>();
        _current = j['current'] as String? ?? defaultStudent;
        if (!_students.contains(_current)) _current = _students.first;
      }
      _progress = _read(prefs, _current);
    } catch (e) {
      debugPrint('İlerleme okunamadı: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Progress _read(SharedPreferences prefs, String name) {
    final raw = prefs.getString(_keyFor(name));
    if (raw == null) return Progress();
    return Progress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Başka bir öğrencinin kaydını okur (rapor için; aktif kayıt değişmez).
  Future<Progress> progressOf(String name) async {
    if (name == _current) return _progress;
    final prefs = await SharedPreferences.getInstance();
    return _read(prefs, name);
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFor(_current), jsonEncode(_progress.toJson()));
      await prefs.setString(
          _rosterKey, jsonEncode({'students': _students, 'current': _current}));
    } catch (e) {
      debugPrint('İlerleme yazılamadı: $e');
    }
    notifyListeners();
  }

  // ---- öğrenciler ----

  Future<void> addStudent(String name) async {
    final n = name.trim();
    if (n.isEmpty || _students.contains(n)) return;
    _students.add(n);
    await save();
  }

  Future<void> selectStudent(String name) async {
    if (!_students.contains(name) || name == _current) return;
    _current = name;
    try {
      final prefs = await SharedPreferences.getInstance();
      _progress = _read(prefs, name);
    } catch (e) {
      debugPrint('İlerleme okunamadı: $e');
      _progress = Progress();
    }
    await save();
  }

  Future<void> removeStudent(String name) async {
    if (name == defaultStudent || !_students.contains(name)) return;
    _students.remove(name);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyFor(name));
    } catch (e) {
      debugPrint('Kayıt silinemedi: $e');
    }
    if (_current == name) {
      _current = _students.first;
      final prefs = await SharedPreferences.getInstance();
      _progress = _read(prefs, _current);
    }
    await save();
  }

  // ---- ilerleme ----

  Future<void> markPrologSeen() async {
    _progress.prologSeen = true;
    await save();
  }

  Future<void> setSceneIndex(int station, int index) async {
    _progress.sceneIndex[station] = index;
    await save();
  }

  Future<void> completeStation(int station, String itemId) async {
    if (station > _progress.completedStation) {
      _progress.completedStation = station;
    }
    _progress.sceneIndex.remove(station);
    if (!_progress.items.contains(itemId)) _progress.items.add(itemId);
    await save();
  }

  Future<void> addRetry(String sceneKey) async {
    _progress.mistakes[sceneKey] = (_progress.mistakes[sceneKey] ?? 0) + 1;
    if (!_progress.retryScenes.contains(sceneKey)) {
      _progress.retryScenes.add(sceneKey);
    }
    await save();
  }

  Future<String?> takeRetry() async {
    if (_progress.retryScenes.isEmpty) return null;
    final key = _progress.retryScenes.removeAt(0);
    await save();
    return key;
  }

  Future<void> setTeacherUnlock(bool value) async {
    _progress.teacherUnlockedAll = value;
    await save();
  }

  Future<void> setArmClockBest(int score) async {
    if (score <= _progress.armClockBest) return;
    _progress.armClockBest = score;
    await save();
  }

  Future<void> setGrade(int? grade) async {
    _progress.grade = grade;
    await save();
  }

  Future<void> reset() async {
    final grade = _progress.grade;
    _progress = Progress(grade: grade);
    await save();
  }
}
