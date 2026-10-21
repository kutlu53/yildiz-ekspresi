# Yıldız Ekspresi

Kış uykusunu kaçıran ayı Pamuk'u ilk kar yağmadan yuvasına götürürken ilkokul
öğrencilerine analog saati ve zaman birimlerini öğreten Flutter oyunu.
Proje yönergeleri `CLAUDE.md`, hikâye ve sahne listesi `docs/senaryo.md`
dosyasında.

## Durum

Faz 0 (kamera riski testi) tamamlandı, sınıf cihazlarında deneme bekliyor.
Faz 1 oynanabilir: Prolog ve Durak 1-3 (Garaj, İlk Hat, Çarklı Köprü),
sürüklenebilir saat, altı mekanik, yardım merdiveni, TTS ve yerel kayıt.
Yolculuğun tamamı oynanabilir: Durak 1-10 ve final sinematiği hazır. Dakika
sayma, dijital-analog eşleme, sözlü saat, 24 saatlik gün, haftanın günleri,
aylar ve mevsimler, takvim okuma, birim dönüşümü terazisi, süreli Hızlı Saat
ve kapıdaki beş dişlili saat kilidi. Oyun sonu modu: başlıktaki haritadan
istenen durak yeniden oynanır; hikâye bitince Hızlı Saat ve Zaman Kapıları
(sürükleme) haritadan açılır. Kalan: sınıf ve ikili mod, öğretmen paneli,
Zaman Kapıları (kamera).
Menü ve düğme yok; hikâye tek akış hâlinde kendiliğinden ilerler.
Pamuk, tren ve dekorlar kodla çizilen vektör; Rive animasyonları gelince
yerine takılır. Öğretmen menüsü: başlıkta Pamuk'a uzun basın.

## Canlı deneme

Her `main` gönderimi GitHub Actions ile derlenir, test edilir ve GitHub Pages'e
yayınlanır: https://kutlu53.github.io/yildiz-ekspresi/ (HTTPS olduğu için
kamera modu çalışır; MediaPipe modeli ilk açılışta indirilir). İş akışı:
`.github/workflows/pages.yml`.

## Çalıştırma

```bash
flutter pub get
flutter run -d chrome        # Faz 0 kamera testi için web hedefi
flutter test                 # birim ve widget testleri; test/e2e: hikâyeyi baştan sona oynayan "robot çocuk"
flutter build web --release  # build/web altında PWA çıktısı
python tool/gen_sfx.py       # assets/sfx altındaki efekt ve müzik dosyalarını yeniden üretir (numpy)
```

Kamera testi ekranı Chrome'da kamera izni ister. Görüntü yalnızca tarayıcıda
işlenir; hiçbir kare diske veya sunucuya gönderilmez. MediaPipe model ve WASM
dosyaları ilk açılışta CDN'den indirilir (çevrimdışı paketleme Faz 2'de).

## Klasör yapısı

| Yol | İçerik |
|---|---|
| `docs/senaryo.md` | Hikâye omurgası, karakterler, 10 durağın sahne listesi |
| `lib/core/` | `ClockTime`, `AngleMapper`, `TurkishTime`, `Week`, `Year`: UI'dan bağımsız saat/açı/hafta/yıl mantığı |
| `lib/features/story/stages.dart` | Sahne yerleşimleri: küçük saat + büyük nesne + olay (kabin ve kol, vagon tabelaları, tünel kapısı) |
| `lib/features/story/` | Hikâye motoru: `StoryFlow` tek akış, `StationPlayer`, sinematik oynatıcı, dekor nesneleri, yerel kayıt, replik listesi, `stations/` altında durak içerikleri |
| `lib/features/mechanics/` | Etkileşim sözlüğü: Elleri Tak, Hangisi?, Say, Saati Kur, Saati Oku, Zili Çal, Eşleştir, Gün Turu, Kart Yerleştir (Sırala), Taş Yolu, Seçenek Seç, Takvim, Terazi, Hızlı Saat; ortak yardım merdiveni |
| `lib/features/armclock/` | Kol Saati mini oyunu: süreli, puanlı; kamera ile kollar saat olur, kamerasızda sürükleme |
| `lib/features/teacher/` | Öğretmen paneli: öğrenci profilleri, sınıf ön ayarı, takılınan sahne raporu, kilit açma, durağa atlama |
| `lib/features/camera/` | Poz kaynağı (web: MediaPipe köprüsü), kol açısı, sabit tutma algılayıcı, Faz 0 ekranı (öğretmen menüsünden) |
| `lib/shared/widgets/` | Kadran çizimi, sürüklenebilir saat, Pamuk, tren, dekorlar (`SceneryView`, `ClockFrame`), gün penceresi (`DayWindow`), yol haritası (`RouteMap`), kutlama (`StarBurst` konfeti), buhar (`SteamPuffs`) |
| `lib/shared/audio/` | TTS sarmalayıcısı (`Speech`), ses efektleri ve müzik (`Sfx`, `Cue`) |
| `assets/sfx/`, `tool/gen_sfx.py` | Sentezlenmiş efektler ve müzik döngüleri; gerçek kayıtlar aynı adla konur |
| `web/pose.js` | Tarayıcıda MediaPipe Pose Landmarker'ı çalıştıran köprü |
| `test/` | Birim testleri |

## Kamera modu kuralları (Zaman Kapıları)

- Sol kol = akrep (kırmızı), sağ kol = yelkovan (mavi); kamera ayna gibi gösterilir.
- Omuz → bilek vektörünün dikey eksene göre açısı kadran konumuna çevrilir.
- Adım: tam saat / yarım / çeyrek / 5 dakika; tolerans ±8-25° arasında ayarlanabilir.
- Poz 1,5 sn sabit kalınca doğrulanır.
- Her kapının sürükleme eşdeğeri vardır; kamerasız cihazda hikâye aynı akar.
