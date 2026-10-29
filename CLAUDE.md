# Yıldız Ekspresi: Analog Saat ve Zaman Öğretim Oyunu

> Bu dosya Claude Code için proje özeti ve çalışma yönergesidir. Proje klasörünün kök dizinine koyun; Claude Code her oturumda otomatik okur. Hikâye ve sahne ayrıntıları `docs/senaryo.md` dosyasındadır; sahne tasarımı değişirse önce o dosya güncellenir.

## 1. Proje Amacı

İlkokul öğrencilerine **analog saatte akrep ve yelkovanı** tanıtarak başlayıp sırasıyla **dakika, saat, gün, hafta, ay ve yıl** kavramlarını sinematik bir hikâyenin içinde öğreten eğitim oyunu.

- **Hedef kitle:** İlkokul 2-4. sınıf; tek oyun tüm düzeyi kapsar, sınıfa göre durak kilitleri açılır
- **Dil:** Türkçe (arayüz, seslendirme). Kod ve değişken adları İngilizce
- **Kullanım ortamı:** Sınıf (tahta/projeksiyon, tablet) ve ev
- **Çıktı:** Flutter ile mobil + web (PWA); çevrimdışı çalışabilir
- **Olası çerçeve:** TÜBİTAK 2204-B ortaokul proje fikriyle uyumlu

## 2. Hikâye (kesinleşti)

**Omurga:** Kış uykusunu kaçıran ayı **Pamuk**'u, ilk kar yağmadan önce **Yıldız Ekspresi** ile Kar Dağı'ndaki yuvasına götürmek. Tren tarifeyle çalışır, Pamuk saati bilmez; çocuk makinist çırağıdır ve saati okuyan tek kişidir. Hedef bir yer değil bir andır, bu yüzden her zaman birimi hikâyenin ilerlemesi için gereklidir.

Temel ilkeler:
- **Metin tabanlı değil, sinematik.** Her durak kısa bir animasyonla açılır, sorun görsel gösterilir, Pamuk tek cümle söyler. Ekranda okunması zorunlu metin yoktur; her yazı sesle de verilir.
- **Saat dünyanın parçasıdır.** İstasyon saati, fener, köprü çarkı gibi nesneler; çocuk dokununca dünya tepki verir (düdük, köprü, ışık).
- **Çocuk öğretendir.** Pamuk sorar, çocuk gösterir.
- **Yanlış bir olaydır, ceza değil.** Tren bekler, Pamuk horlar; "bir daha deneyelim".
- **Görünür ilerleme:** Duraklar arası tren yolculuğu sinematiği, gökyüzü kışa döner, Pamuk'un vagonuna her durakta bir eşya eklenir.
- **Menü ve düğme yok.** Uygulama doğrudan hikâyeyle açılır; başlıkta Pamuk'a dokunmak tek başlangıç dokunuşudur (tarayıcıda ses için gerekli). Başlıktaki yol haritası dünyanın parçasıdır: tren tamamlanan durakta durur, açık bir durağa dokunmak onu oynatır, hikâye bitince kar tanesi Hızlı Saat'i ve kapı Zaman Kapıları'nı açar. Akış prolog → yolculuk → durak → yolculuk → durak biçiminde kendiliğinden sürer. "Tamam", "Atla", "Tekrar dinle", harita gibi UI düğmeleri yoktur: eli bırakmak sonucu verir, ekrana dokunmak sinematiği ilerletir, Pamuk'a dokunmak son repliği tekrar ettirir, çocuk 12 sn durursa Pamuk kendiliğinden tekrar eder. Öğretmen menüsü başlıkta Pamuk'a uzun basınca açılır.
- **Her durağın kendi dünyası var.** Dekor (`Scenery`) ve saatin yuvası (`ClockFrameStyle`) durağa özgüdür; saat sahnenin içindeki bir nesnedir. Ardışık sahneler aynı mekaniği tekrarlamaz.

Rehber karakter: **Pamuk** (tek konuşan karakter). Yan karakterler konuşmaz.

## 3. Durak Yapısı

| Durak | Yer | Hikâye anı | Kazanım |
|---|---|---|---|
| 1 | Garaj | Saatin elleri düşmüş, çocuk takar | Akrep kısa/kırmızı, yelkovan uzun/mavi |
| 2 | İlk Hat | Tren yalnız tam saatte kalkar | Tam saatler |
| 3 | Çarklı Köprü | Köprü buçukta iner, çeyrekte zil | Yarım ve çeyrek; akrep iki sayı arasında |
| 4 | Fener Tüneli | Fener 5 dakikada bir yağ ister | 5'er dakika, sonra 1'er; 60 dk = 1 saat |
| 5 | Büyük İstasyon | Aktarma 7:48'de | Saat + dakika, sözlü ifadeler, dijital-analog |
| 6 | Gece Hattı | Bir tam gün süren yolculuk | 24 saat, günün akışı |
| 7 | Pazar Kasabası | Tren haftada bir Cumartesi kalkar | Hafta, günler, "n gün sonra" |
| 8 | Mevsim Vadisi | 12 kasaba = 12 ay | Aylar, gün sayıları, mevsimler, takvim |
| 9 | Kar Dağı Eteği | Karmaşık tarife, kar başlıyor | Birim dönüşümleri, hızlı okuma |
| 10 | Yuva | Kapıdaki büyük saat kilidi | Karışık final |

Her durak aynı iskeleti izler: giriş sinematiği, 2-4 sahne, isteğe bağlı Zaman Kapısı (kamera), hata sahnesi, kapanış ve vagon eşyası. Ayrıntılar `docs/senaryo.md` bölüm 5.

Sınıf ön ayarı: 2. sınıf için 1-3 ve 6-7'nin basit sahneleri; 3. sınıf 1-8; 4. sınıf tümü. Öğretmen kilitleri açabilir.

## 4. Etkileşim Sözlüğü (yeniden kullanılan mekanikler)

1. **Saati Kur:** Hedef (pano, sözlü) verilir, çocuk eli sürükleyip bırakır; bırakış doğruysa dünyadaki nesne tepki verir (kol iner, kapı açılır). İlk yanlış bırakış "henüz değil", sonrakiler yardım merdiveni.
2. **Saati Oku:** Dünyadaki saat gösterilir, üç ahşap tabeladan doğrusuna dokunulur, tabela sesle okunur. Genel biçimi **Seçenek Seç** (`ChooseOptionMechanic`): herhangi bir nesne ve tabelalar (gün sayısı gibi).
3. **Say:** Yelkovan sayıdan sayıya sürüklenir, her adımda sayı söylenir (5'er, 1'er). Saat biçimi **Gün Turu** (`TurnDayMechanic`): akrep sürüklenir, 24 adımda bir gün.
4. **Elleri Tak:** Yerdeki kısa/uzun eller kadrana sürüklenir (Durak 1).
5. **Hangisi?:** Söylenen ele dokunulur (Durak 1).
6. **Zili Çal:** Yelkovan kendi döner (12°/s), hedefe gelince zile ya da saate dokunulur; kaçırınca yelkovan hedefin gerisine alınır; gözlem ve zamanlama (Durak 3).
7. **Sırala:** Kartlar (gün akışı, haftanın günleri, aylar) sıraya dizilir ya da doğru yere sürüklenir (`PlaceCardsMechanic`: kart + yuva, yuva kapasitesi ayarlanabilir; mevsim vagonları gibi çoklu yuvalar için de kullanılır).
8. **Eşleştir:** Dijital-analog (`PickClockMechanic`: hedef dijital, dünyadaki saatlerden doğrusuna dokun), ay-mevsim, 15:00-3 gibi eşlemeler.
9. **Takvim:** Takvim üstünde gün bulma (`CalendarMechanic`: ay sayfası, doğru güne dokun), "n gün sonra". Hafta ve yıl düzeyinde **Taş Yolu** (`StonePathMechanic`): halka dizili gün/ay taşları, yürü (say) ve seç (n gün sonra) modları.
10. **Terazi:** Birim dönüşümü (`BalanceMechanic`: 60 dk kefede 1 saati dengeler; ağırlığa dokun, fazla gelirse kefe düşer).
11. **Hızlı Saat:** Süreli tekrar (`QuickClockMechanic`: kar tanesi sayacı, süre bitince doğru gösterilir ve devam; Durak 9 ve oyun sonu modu).
12. **Zaman Kapısı:** Kamera modu (Bölüm 5).

Her mekanik bir kez yazılır, duraklar yalnız içerik ve görsel bağlam verir.

**Sahne yerleşimleri (`lib/features/story/stages.dart`):** İlk oynamada sahneler aynı hissettirdi (ortada büyük saat, küçük nesne). Yeni kalıp: saat küçülüp dünyanın içine yerleşir, nesne büyür, doğru cevabın ödülü bir olaydır. `SetClockMechanic.stage/afterSuccess` ve `ReadClockMechanic.stage` kancaları bunu sağlar; `CabStage` (küçük saat + büyük kol + kalkan tren), `WagonSigns` (manevra yapan vagonlarda tabelalar), `GateStage` (büyük kapı, tren tünele girer). Kurallar: aynı fiil üst üste en fazla iki tur, üçüncü tur kuralı değiştirir (Pamuk tahmin eder, çocuk doğru/yanlış der); kutlama replikleri döner (`Lines.praise`). Durak 2 prototiptir; beğenilirse diğer duraklara yayılır.

## 5. Kamera / Vücut ile Saat Modu: "Zaman Kapıları"

Hikâyede bazı geçitler yalnız çocuğun kollarıyla saati göstermesiyle açılır. Kamera vücut iskeletini (pose detection) okuyup saati doğrular. **Her Zaman Kapısı'nın sürükleme eşdeğeri vardır**; kamerasız cihazda hikâye aynı akar.

### Teknik yaklaşım
- **Web/PWA:** MediaPipe Pose (JS), Flutter'a `dart:js_interop` ile bağlı (`web/pose.js`, `lib/features/camera/`). Faz 0 bu hedefle kuruldu.
- **Mobil/tablet:** `google_mlkit_pose_detection` (henüz stub).
- Omuz → bilek çizgisinin dikey eksene göre açısı hesaplanır, kadrana çevrilir (`PoseFrame`, `AngleMapper`).

### Hassasiyet sınırı (kritik karar)
- Yelkovan 1 dakikada 6° döner; kolla bu ayrım gerçekçi değil.
- **Kamera modu:** tam saat, yarım, çeyrek ve **5'er dakika** (30° adımlar, tolerans yaklaşık ±12-15°).
- Tam dakika hassasiyeti sürükleme modunda kalır.

### Kol atama ve ilerleme
- Sağ kol = yelkovan (uzun, mavi), sol kol = akrep (kısa, kırmızı). Kamera ayna gibi gösterilir; gövdeye yarı saydam kadran bindirilir.
- Durak 2: yalnız yelkovan kolu. Durak 3'ten itibaren iki kol, tolerans geniş. Durak 5: 5'er dakika.
- 3:30'da akrep 3 ile 4'ün ortasındadır; ilk kapılarda tolerans geniş, sonra bu kural değerlendirilir. Beraberlikte akrebin geçtiği rakam tercih edilir (çocuğun "akrep 3'te" okuması 3:30 sayılır).

### Geri bildirim
- Poz **1,5-2 sn sabit** kalınca doğrulanır (`HoldDetector`).
- Kollar kadranda renkli çizgi olarak canlı görünür; hedef saat hayalet el olarak gösterilir.
- Yanlışta ceza yok; yönlendirme ("Yelkovan biraz daha yukarı!").
- Başarıda kapı açılır, ses, konfeti.

### Zorunlu kısıtlar
- **Gizlilik (KVKK/okul):** Görüntü yalnızca cihazda işlenir, kaydedilmez, sunucuya gitmez. Ekranda ve veli/okul bilgilendirmesinde belirtilir.
- **Kalibrasyon ekranı:** Üst gövde çerçeveye girsin, ~1,5-2 m mesafe, yeterli ışık.
- **Çok kişi:** En yakın kişiyi seç veya tek kişi kilitle.
- Sınıf modu ve ikili mod (biri akrep, biri yelkovan) oyun sonu modunda.
- **Kol Saati mini oyunu** (`lib/features/armclock/`): bireysel, süreli, puanlı; kamera modunun ilk oyunlaştırılmış kullanımı. `ArmClockGame` saf Dart (tur, süre, puan, seri, yıldız), `ArmClockScreen` kamera ya da sürükleme. Haritadaki mor işaretten açılır, en iyi puan `Progress.armClockBest`.

## 6. Pedagojik İlkeler

- Akrep/yelkovan renk, boy ve kalınlığı **her yerde aynı** (`ClockStyle`).
- Somuttan soyuta: önce hikâyedeki olay, sonra sayılar.
- **Yardım basamakları:** yanlışta önce ilgili el parlar, sonra sayılar, en son Pamuk cevabı gösterir.
- Türkçe **sesli okuma** her yazı için zorunlu.
- Bir durak **5-8 dakika**; sahneler arasında kayıt, yarım kalan durak kaldığı sahneden devam eder.
- Ceza yok. Yanlış yapılan sahne sonraki oturumun başında kısa ısınma olarak tekrar gelir (aralıklı tekrar).

## 7. Öğretmen Paneli (ikincil öncelik)

- Öğrenci bazında takıldığı durak/sahne raporu (hazır: `TeacherPanel`, sahne başına hata sayısı)
- Durak kilidini öğretmenin açması (hazır)
- Sınıf düzeyine göre ön ayar (2., 3., 4. sınıf) (hazır: `StationRegistry.forGrade`; 2. sınıf 1-3 ve 6-7, 3. sınıf 1-8)
- MEB kazanımlarıyla eşleme öğretmen tarafından doğrulanır
- Panel başlıkta Pamuk'a uzun basınca açılır; çocuk arayüzü değildir, düğme ve metin serbesttir

## 8. Teknik Kararlar

- **Çatı:** Flutter (mobil + web/PWA), Material 3, `locale: tr`.
- **Görsel stil:** Düz renkli **vektör** animasyon. Sinematikler ve Pamuk için Rive (durum makineli); sahne geçişleri Flutter animasyonları. Arka planlar katmanlı parallaks.
- **Ses:** Önce **TTS** (`flutter_tts`, Türkçe, yavaş hız). Tüm replikler tek listeden (`assets/lines/`) kimlikle okunur; gerçek ses kaydı geldiğinde aynı kimliklerle dosyalar değiştirilir. TTS başlatma ve konuşma çağrıları 3 sn zaman aşımlıdır; motor yoksa oyun donmaz, metin uzunluğu kadar bekler.
- **Efektler ve müzik:** `Sfx` (`lib/shared/audio/sfx.dart`, `audioplayers`). Dosyalar `assets/sfx/<id>.wav`; şimdilik `tool/gen_sfx.py` ile sentezlenir (numpy), gerçek kayıt gelince aynı adla değiştirilir. Dünyadaki nesneler `Cue` ile sarılır (değer değişince ses: kapı → dişli, fener → çan, damla → damla). Merkezi kancalar: el adıma oturunca tık + titreşim (`DraggableClock`), kutlama yıldızlarıyla `success` (`StarBurst`), yanlışta yumuşak `wrong` ve Pamuk sallanır, sahne bitince Pamuk zıplar (`PamukReactor`), durak bitince `cheer`, tren hareket edince düdük + buhar + çuf çuf döngüsü (`CinematicPlayer`). Müzik temaları: sonbahar (1-5), gece (6-7), kış (8-10); parça bir kez çalar, 45 sn susar, yeniden çalar (sürekli döngü pilotta sinir bozucu bulundu, 2026-10-29); öğretmen panelinden efekt ve müzik ayrı ayrı kapatılır. Test ortamında `Sfx.inTest` eklentiyi atlar, yalnızca `log` tutar.
- **Görsel dokunuşlar:** `StarBurst` yıldız + konfeti (`big` durak sonu ve jenerikte, `CinematicPlayer.celebrate`), `SteamPuffs` buhar pufları (kalkış kolu, lokomotif bacası; dururken tembel küçük puflar), kapı ve kilit açılınca içeriden ışık (`GateProp`, `LockProp`), sürüklenen el parlar.
- Sürüklenebilir analog saat: `CustomPainter` + `GestureDetector`; kadran çizimi `lib/shared/widgets/clock_face.dart`.
- Saat/açı mantığı UI'dan ayrı, test edilebilir saf Dart (`lib/core/clock_time.dart`, `lib/core/angle_mapper.dart`).
- Çevrimdışı çalışma; ilerleme cihazda yerel saklanır (ilk sürümde sunucu yok).
- Klasör yapısı: `lib/core` (saat/açı), `lib/features/story` (`StoryFlow` tek akış, `StationPlayer`, sinematikler, dekor/prop, `stations/` içerikler), `lib/features/mechanics` (etkileşim sözlüğü), `lib/features/camera`, `lib/shared/widgets` (saat, Pamuk, tren, dekor), `docs/` (senaryo).
- Akış: `main.dart` → `StoryFlow` (başlık → prolog → yolculuk → `StationPlayer` → ... → son). Rota/menü yok; her şey tek ekranın içinde `AnimatedSwitcher` ile değişir.

## 9. Yol Haritası

**Faz 0: Kamera riski testi (tamamlandı, sınıf denemesi bekliyor)**
- Web'de MediaPipe ile omuz-bilek açısı okuma ve kadran bindirme ekranı hazır.
- Sınıf cihazlarında doğruluk/performans denemesi yapılacak.

**Faz 1: Çekirdek ve ilk üç durak (MVP, oynanabilir; 2026-10-20)**
- Sürüklenebilir analog saat, Elleri Tak / Hangisi? / Say / Saati Kur / Saati Oku / Zili Çal mekanikleri, yardım merdiveni
- Prolog ve Durak 1-3 sinematik ve sahneleri; Pamuk, tren ve üç dekor kodla çizilen vektör (Rive gelince değişecek)
- TTS (`Speech`) ve kimlikli replik listesi (`Lines`), menüsüz tek akış, yolculuk sinematikleri, vagon eşyaları, yerel kayıt, aralıklı tekrar (ısınma)
- Ses efektleri ve müzik eklendi (2026-10-21): sentezlenmiş efektler, üç müzik döngüsü, Pamuk tepkileri
- Kalan: gerçek cihazda ses ve dokunma denemesi, Pamuk'un çizilmiş tasarımı, gerçek ses efekti kayıtları

**Faz 2: Zaman Kapıları**
- Durak 2 ve 3 kapıları (tam saat, buçuk), kalibrasyon ekranı, sürükleme eşdeğeri
- Durak 5 kapısı (5'er dakika)

**Faz 3: Yolculuğun tamamı (başladı)**
- Durak 4 Fener Tüneli hazır (2026-10-21): tünel dekoru, fener yuvası, Say 5'er, Kur 5'er ve 1'er (damla saati)
- Durak 5 Büyük İstasyon hazır (2026-10-21): kubbeli dekor, altın yuva, Eşleştir mekaniği (dijital → analog, `PickClockMechanic`), tur bazlı dakika adımı, sözlü saat, kapının sürükleme eşdeğeri
- Durak 6 Gece Hattı hazır (2026-10-21): yataklı vagon dekoru, gün penceresi (`DayWindow`), Gün Turu (`TurnDayMechanic`), Kart Yerleştir (`PlaceCardsMechanic`), 24 saatlik eşleme, `TurkishTime.spoken24`
- Durak 7 Pazar Kasabası hazır (2026-10-21): arı pazarı dekoru, Taş Yolu (`StonePathMechanic`, halka dizilim, yürü/seç modları), hafta hesapları `lib/core/week.dart`
- Durak 8 Mevsim Vadisi hazır (2026-10-21): vadi dekoru, Seçenek Seç (`ChooseOptionMechanic`), Takvim (`CalendarMechanic`), yumruk tepeleri ve mevsim penceresi, yıl hesapları `lib/core/year.dart`
- Durak 9 Kar Dağı Eteği hazır (2026-10-21): kar dekoru, buz yuvası, Terazi (`BalanceMechanic`), Hızlı Saat (`QuickClockMechanic`), tarife panosu
- Durak 10 Yuva hazır (2026-10-21): zirve ve yuva dekorları, saat kilidi (`LockProp`), beş karışık görev, final sinematiği (`finale.dart`: eşyalar rafa, ilk kar, jenerik)
- Oyun sonu modu hazır (2026-10-21): başlıkta yol haritası (`RouteMap`), durak yeniden oynatma (`StationPlayer.replay`), Hızlı Saat ve Zaman Kapıları (sürükleme) haritadan (`stations/extras.dart`)
- Öğretmen paneli hazır (2026-10-21, `lib/features/teacher/`): öğrenci profilleri (`ProgressStore` öğrenci başına kayıt), sınıf ön ayarı (`StationRegistry.forGrade`), takılınan sahne raporu (`Progress.mistakes`), kilit açma, durağa atlama
- Kol Saati mini oyunu hazır (2026-10-21, `lib/features/armclock/`): süreli, puanlı, kamera ile kollar saat olur; kamerasızda sürükleme eşdeğeri; haritadaki mor işaretten açılır. Kullanıcı kararıyla kamera sınıf denemesinden önce eklendi; toleranslar denemeden sonra ayarlanacak
- Kalan: sınıf modu ve ikili mod (kamera doğrulaması sonrası), MEB kazanım eşlemesinin panele işlenmesi
- Oyun sonu modu, sınıf modu, ikili mod, öğretmen paneli

**Faz 4: Pilot**
- Birkaç öğrenciyle gözlem, takılma noktalarına göre düzeltme (ilk tur 2026-10-29: müzik, tren/kapı boyu, zil, TTS kesilmesi, Durak 6 gün bölümleri, Şubat 29, Durak 10 kilit, kamera hata mesajı; ayrıntı `docs/senaryo.md` son bölüm)
- Gerçek ses kaydıyla TTS'in değiştirilmesi

## 10. Kararlar ve Açık Sorular

Kesinleşen kararlar (2026-10-20):
- Rehber karakter: **Pamuk** (ayı).
- Kapsam: tek oyun **2-4. sınıfın tamamını** kapsar; sınıfa göre kilit.
- Seslendirme: **önce TTS, sonra gerçek ses**; replikler kimlikli tek liste.
- Görsel stil: **vektör**.
- Faz 0 hedefi: web (Chrome); mobil poz kaynağı sonra.

Açık sorular:
- İlk yayın için web (PWA) mi, Android mi öncelikli?
- Rive mi, Lottie mi? (Öneri: Rive, durum makineleri etkileşim için uygun.)
- Pamuk'un görsel tasarımı: kim çizecek, referans tahta ne zaman?

## 11. Claude Code için Çalışma Yönergeleri

- Tüm kullanıcıya dönük metinler **Türkçe**, kod ve değişken adları İngilizce.
- Hikâye ve sahne değişikliklerinde önce `docs/senaryo.md` güncellenir, sonra kod.
- Her yeni özellikte kısa bir plan çıkar, sonra uygula; saat/açı mantığı ve mekanik kuralları için birim test yaz.
- Mekanikleri durak bağımsız yaz; duraklar yalnız içerik ve görsel bağlam versin.
- Çocuklara yönelik UI: büyük dokunma alanları, yüksek kontrast, okunması zorunlu metin yok, her yazının sesli karşılığı.
- **Ekran sınıfları** (`lib/shared/layout.dart`): tasarım yatay ekran içindir. Yükseklik < 480 (yatay telefon) "sıkışık" düzen: `MechanicFrame` tabelaları saatin sağına alır, `SceneScaffold` Pamuk sütununu daraltır, nesneler `Layout.scale` ile küçülür. Dikey telefon (`Layout.phonePortrait`) `OrientationGuard` ile "telefonu yan çevir" sahnesine düşer; tablet dikey serbesttir. Görsel kontrol: `VISUAL=1 flutter test --update-goldens test/visual` ekran görüntülerini `test/visual/goldens/` altına üretir ve taşma raporu yazar (CI'de atlanır).
- Kamera doğruluğu sınıf cihazlarında doğrulanmadan Zaman Kapıları'nı genişletme.
- Görüntü verisini **asla** diske veya ağa yazma.
- Kararsız kaldığın tasarım/pedagoji sorularında Bölüm 10'daki açık sorulara dön ve kullanıcıya sor.
