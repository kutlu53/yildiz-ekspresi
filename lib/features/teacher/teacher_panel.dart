import 'package:flutter/material.dart';

import '../../shared/audio/sfx.dart';
import '../camera/camera_test_screen.dart';
import '../story/models.dart';
import '../story/progress_store.dart';
import '../story/stations/stations.dart';

/// Sahne kimliklerinin öğretmen için Türkçe adları.
const sceneTitles = <String, String>{
  'attach': 'Elleri Tak',
  'tap': 'Hangisi?',
  'turn': 'Yelkovan bir tur',
  'lever': 'Kalkış kolu',
  'read': 'Saati Oku',
  'gate': 'Zaman Kapısı',
  'half': 'Buçuk',
  'bell': 'Zili Çal',
  'count': 'Beşer say',
  'set': 'Saati Kur',
  'drip': 'Damla saati',
  'board': 'Pano',
  'platform': 'Hangi peron',
  'spoken': 'Sözlü saat',
  'window': 'Pencere (24 saat)',
  'day': 'Günün akışı',
  'fifteen': 'On beş mi üç mü',
  'stones': 'Gün taşları',
  'hunt': 'Takvim avı',
  'towns': 'Ay kasabaları',
  'houses': 'Kaç gün',
  'wagons': 'Mevsim vagonları',
  'calendar': 'Takvim',
  'balance': 'Terazi',
  'timetable': 'Tarife',
  'quick': 'Hızlı Saat',
};

/// Sahne anahtarını ("3.bell") öğretmen diline çevirir.
String describeScene(String key) {
  final dot = key.indexOf('.');
  if (dot < 0) return key;
  final number = int.tryParse(key.substring(0, dot));
  final id = key.substring(dot + 1);
  final station = number == null ? null : StationRegistry.byNumber(number);
  final place = station?.place ?? 'Durak $number';
  return '$place · ${sceneTitles[id] ?? id}';
}

/// Öğretmen paneli: öğrenci seçimi, sınıf ön ayarı, ilerleme ve takılınan
/// sahneler raporu, kilit açma, durağa atlama, kamera testi. Çocuk arayüzü
/// değil; düğme ve metin serbest. Başlıkta Pamuk'a uzun basınca açılır.
class TeacherPanel extends StatefulWidget {
  final ValueChanged<Station> onJump;

  const TeacherPanel({super.key, required this.onJump});

  @override
  State<TeacherPanel> createState() => _TeacherPanelState();
}

class _TeacherPanelState extends State<TeacherPanel> {
  final _store = ProgressStore.instance;
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    _name.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Progress get _p => _store.progress;

  @override
  Widget build(BuildContext context) {
    final stations = StationRegistry.forGrade(_p.grade);
    final total = stations.length;
    final done = stations.where((s) => s.number <= _p.completedStation).length;
    final mistakes = _p.mistakes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Öğretmen Paneli')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Öğrenci'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _store.students)
                InputChip(
                  label: Text(s),
                  selected: s == _store.currentStudent,
                  onSelected: (_) => _store.selectStudent(s),
                  onDeleted: s == ProgressStore.defaultStudent
                      ? null
                      : () => _store.removeStudent(s),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Yeni öğrenci adı'),
                  onSubmitted: (_) => _add(),
                ),
              ),
              IconButton(onPressed: _add, icon: const Icon(Icons.person_add)),
            ],
          ),
          _section('Sınıf ön ayarı'),
          SegmentedButton<int?>(
            segments: const [
              ButtonSegment(value: 2, label: Text('2. sınıf')),
              ButtonSegment(value: 3, label: Text('3. sınıf')),
              ButtonSegment(value: 4, label: Text('4. sınıf')),
              ButtonSegment(value: null, label: Text('Tümü')),
            ],
            selected: {_p.grade},
            onSelectionChanged: (v) => _store.setGrade(v.first),
          ),
          const SizedBox(height: 4),
          Text(
            'Duraklar: ${stations.map((s) => s.number).join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          _section('İlerleme'),
          Text('${_store.currentStudent}: $done / $total durak tamamlandı'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tüm durakların kilidini aç'),
            value: _p.teacherUnlockedAll,
            onChanged: _store.setTeacherUnlock,
          ),
          TextButton.icon(
            onPressed: () => _store.reset(),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Bu öğrencinin ilerlemesini sıfırla'),
          ),
          _section('Ses'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ses efektleri'),
            value: Sfx.instance.enabled,
            onChanged: (v) async {
              await Sfx.instance.setEnabled(v);
              _refresh();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Arka plan müziği'),
            value: Sfx.instance.musicEnabled,
            onChanged: (v) async {
              await Sfx.instance.setMusicEnabled(v);
              _refresh();
            },
          ),
          _section('Takılınan sahneler'),
          if (mistakes.isEmpty)
            const Text('Henüz hata kaydı yok.')
          else
            for (final e in mistakes.take(10))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFB300),
                  child: Text('${e.value}'),
                ),
                title: Text(describeScene(e.key)),
                subtitle: const Text('hata'),
              ),
          _section('Durağa git'),
          for (final s in StationRegistry.stations)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text('${s.number}'),
              title: Text('${s.place}: ${s.title}'),
              enabled: stations.contains(s),
              onTap: () {
                Navigator.of(context).pop();
                widget.onJump(s);
              },
            ),
          _section('Kamera (Faz 0)'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.videocam),
            title: const Text('Kamera testi'),
            subtitle: const Text(
                'Görüntü yalnızca cihazda işlenir, kaydedilmez, sunucuya gitmez.'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CameraTestScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add() async {
    await _store.addStudent(_name.text);
    _name.clear();
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );
}
