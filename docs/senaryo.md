# Yıldız Ekspresi: Senaryo ve Sahne Listesi

> Oyunun hikâye ve sahne tasarımı. Teknik yönergeler için `CLAUDE.md`. Bu dosya
> tasarım kararlarının kaynağıdır; bir sahne değişirse önce burası güncellenir.

## 1. Omurga

**Tek cümle:** Kış uykusunu kaçıran ayı Pamuk'u, ilk kar yağmadan önce
Yıldız Ekspresi ile Kar Dağı'ndaki yuvasına götürmek.

**Neden saat?** Tren tarifeyle çalışır, Pamuk saati bilmez ve her an
uyuyakalır. Çocuk makinist çırağıdır: saati okuyan ve kuran tek kişi odur.
Hedef bir yer değil, bir **an**dır; bu yüzden her zaman birimi hikâyenin
ilerlemesi için gereklidir.

**Duygusal çekirdek:** Çocuk öğrenen değil, **öğreten** konumundadır. Pamuk
sorar, çocuk gösterir. Yanlışta Pamuk üzülmez, uyur ya da komik bir şey yapar;
"bir daha deneyelim" der.

**Görünür ilerleme:**
- Harita üstünde tren durak durak ilerler.
- Gökyüzü her durakta biraz daha kışa döner ("kar sayacı").
- Pamuk'un vagonuna her durakta bir eşya eklenir; finalde hepsi yuvada görünür.

## 2. Karakterler

| Karakter | Rol | Notlar |
|---|---|---|
| **Pamuk** | Rehber ve yol arkadaşı. Uykucu, iyimser, bal düşkünü ayı. | Saati bilmez; bölüm ilerledikçe öğrenir ve çocuğa söylediklerini tekrar eder. Tek konuşan karakter. Kısa cümleler, hep sesli. |
| **Çocuk (oyuncu)** | Makinist çırağı. | Sessiz kahraman; adı sorulmaz. Ekranda şapkası ve eli görünür. |
| **Yan karakterler** | Köprü bekçisi kedi, istasyon simitçisi, pazar arıları. | Konuşmaz, mimik ve sesle tepki verir. Her durakta en fazla bir tane. |

Pamuk'un ses kimliği: yavaş, sıcak, biraz esneyen. TTS'te düşük hız, sonra
gerçek ses kaydıyla değiştirilecek. Tüm replikler `assets/lines/` altında
tek bir listede tutulur; TTS ve ses kaydı aynı kimlikleri kullanır.

## 3. Sahne dili (her durakta aynı iskelet)

1. **Giriş sinematiği (10-20 sn):** Tren yaklaşır, sorun görsel olarak
   gösterilir, Pamuk tek cümle söyler. Atlanabilir.
2. **Sahneler (2-4 adet):** Her biri tek bir etkileşim. Saat, ekrandaki bir
   nesnedir (istasyon saati, fener, köprü çarkı). Çocuk dokununca dünya tepki
   verir: düdük, köprü, ışık.
3. **Zaman Kapısı (2. duraktan itibaren, isteğe bağlı):** Kamera modu.
   Çocuk kollarıyla saati gösterir, kapı açılır. Kamerasız cihazda aynı kapı
   kadranı sürükleyerek açılır.
4. **Hata sahnesi:** Yanlış cevap hikâyede bir olaydır (tren bekler, Pamuk
   horlar). Ceza yok. Yardım basamakları: önce ilgili el parlar, sonra
   sayılar, sonra Pamuk cevabı gösterir.
5. **Kapanış (5-10 sn):** Tren kalkar, vagona eşya eklenir, harita ilerler.

Kurallar:
- **Menü ve düğme yok.** Başlıkta Pamuk'a dokunmak hikâyeyi başlatır; sonrası
  kendiliğinden akar. Eli bırakmak sonucu verir, ekrana dokunmak sinematiği
  ilerletir, Pamuk'a dokunmak son repliği tekrar ettirir, çocuk 12 sn durursa
  Pamuk kendiliğinden tekrar eder. Uygulama yeniden açılınca kaldığı sahneden
  sürer ("Kaldığımız yerden devam ediyoruz!").
- **Her durağın kendi dekoru var** (garaj içi, açık hat, nehir köprüsü) ve
  saat o dünyanın nesnesidir (kabin paneli, istasyon direği, köprü kulesi).
  Ardışık iki sahne aynı mekaniği aynı görünümle tekrarlamaz.
- Ekranda okunması gereken metin **yok**; her yazı sesle de verilir.
- Bir durak 5-8 dakika. Sahneler arasında kayıt alınır; yarım kalan durak
  kaldığı sahneden devam eder.
- Yanlış yapılan sahne, sonraki oturumun başında kısa bir "ısınma" olarak
  tekrar gelir (aralıklı tekrar).

## 4. Prolog (30 sn)

Sonbahar. Yapraklar uçuşur. Küçük bir gar. Bankta uyuyan Pamuk esneyerek
uyanır, cebinden saatini çıkarır: **elleri düşmüş.** Ufukta Kar Dağı, tepesi
beyazlanmaya başlamış. Pamuk: *"Kar gelmeden eve dönmeliyim... ama saat kaç
bilmiyorum."* Çocuğun eli ve makinist şapkası kadraja girer. Pamuk saati
çocuğa uzatır. Başlık: **Yıldız Ekspresi**.

## 5. Duraklar

### Durak 1: Garaj — "Elleri Tak"
**Kazanım:** Akrep kısa ve saati gösterir, yelkovan uzun ve dakikayı gösterir.
Renk ve boy her yerde aynı (akrep kırmızı, yelkovan mavi).

- **Giriş:** Garajdaki eski lokomotif. Kabindeki büyük saatin elleri yerde.
- **Sahne 1 – Cep saati:** Yerde iki el: kısa kırmızı, uzun mavi. Çocuk
  ikisini merkeze sürükler. Pamuk: *"Kısa olan akrep, saati gösterir. Uzun olan
  yelkovan, dakikayı."*
- **Sahne 2 – Hangisi?:** Pamuk sorar: *"Akrebe dokun."* / *"Yelkovana dokun."*
  Üç kez, sıra değişir. Doğruda el parlar ve ismini söyler.
- **Sahne 3 – Kabindeki saat:** Çocuk yelkovanı bir tam tur döndürür; akrebin
  yavaşça bir sayı ilerlediğini izler. Pamuk: *"Yelkovan bir tur attı, akrep
  bir sayı ilerledi. Bir saat geçti!"* (Gözlem, soru yok.)
- **Hata:** Elleri ters takarsa saat tıkırdar, el kayıp yere düşer, Pamuk
  güler: *"Bu uzun olan, yelkovan. Tekrar deneyelim."*
- **Kapanış:** Lokomotif buhar çıkarır, ilk düdük. **Vagon eşyası:** Pamuk'un
  cep saati.

### Durak 2: İlk Hat — "Tren Tam Saatte Kalkar"
**Kazanım:** Tam saatler (yelkovan 12'de, akrep sayıyı gösterir). Kadranı
okuma ve kurma.

- **Giriş:** Tarife panosunda kocaman "8". Pamuk: *"Saat sekizde kalkıyormuş.
  Sekiz nasıl olur?"*
- **Sahne 1 – Kalkış kolu:** Kabin saati; yelkovan 12'de kilitli, çocuk yalnız
  akrebi 8'e sürükler. Kol iner, tren kalkar.
- **Sahne 2 – Yoldaki istasyonlar:** Tren üç küçük istasyondan geçer. Her
  istasyon saati bir tam saat gösterir, çocuk perondaki üç ahşap tabeladan
  doğrusuna dokunur. Pamuk tabelayı sesli okur.
- **Sahne 3 / Zaman Kapısı:** Tünel kapısı. "Saat üçü göster!" Kadranı kurunca
  (ya da kamerada sol kol 3'te, sağ kol 12'de) kapı kanatları yana kayar. İlk
  kapıda yalnız yelkovan kolu ile başlanır, akrep kolu sonraki duraklarda
  eklenir. (Önceki taslaktaki "tarife yarışı" kalkışla aynı his olduğu için
  çıkarıldı.)
- **Hata:** Tren kalkmaz, Pamuk horlar, başına bir kuş konar.
- **Kapanış:** **Vagon eşyası:** Pamuk'un atkısı.
- **Dinamik sahneler (2026-10-21, prototip):** İlk oynamada sahneler
  birbirinin aynı hissettirdi (ortada kocaman saat, küçük nesne). Bu durak
  yeni kalıbın prototipi; beğenilirse diğer duraklara yayılır.
  - Sahne 1: Saat kabin paneline gömülü ve küçük, sağda **büyük kalkış kolu**,
    altta bekleyen tren (`CabStage`). Saati kurmak yetmez: çocuk kolu aşağı
    **çeker**; saat yanlışken kol kıpırdamaz ("önce saati kur"). Kol inince
    düdük, buhar ve tren kadrajdan çıkar; sahne tren gidince biter.
  - Sahne 2: Tabelalar durmaz; manevra yapan bir **yük treninin vagonlarına**
    yazılıdır (`WagonSigns`), vagonlar ileri geri salınır, çocuk doğru vagona
    dokunur. İki tur.
  - Sahne 3 (yeni, "Pamuk'un tahmini"): roller döner; Pamuk saati söyler,
    çocuk **doğru/yanlış** tabelasıyla onu düzeltir. Bir doğru, bir yanlış.
  - Sahne 4 / Zaman Kapısı: büyük kapı (`GateStage`); doğru kurulunca
    kanatlar açılır, içeriden ışık dolar, tren tünele girip kaybolur.
  - Kutlama replikleri altı çeşit, sırayla döner ("Harika!" tekrarı kalktı).
  - Mekaniklere eklenen kancalar: `SetClockMechanic.stage/afterSuccess`,
    `ReadClockMechanic.stage` (sahne yerleşimi durak bağımsızdır).

### Durak 3: Çarklı Köprü — "Buçuk ve Çeyrek"
**Kazanım:** Yarım saat (buçuk), çeyrek geçiyor, çeyrek var. Buçukta akrebin
iki sayı arasında olması.

- **Giriş:** Nehir üstünde büyük çarklı köprü, kapalı. Köprü bekçisi kedi
  saatini gösterir: köprü yalnız "buçuk"ta iner.
- **Sahne 1 – Buçuk:** Çocuk yelkovanı 6'ya sürükler. Akrep kendiliğinden iki
  sayının **ortasına** kayar; Pamuk: *"Bak, akrep üç ile dördün arasında kaldı.
  Üç buçuk!"* Köprü iner.
- **Sahne 2 – Zili Çal (çeyrek):** Köprü saatinin yelkovanı kendi kendine
  döner. Pamuk: *"Yelkovan üçe gelince zile dokun!"* Çocuk izler, tam çeyrekte
  dokunur; erken ya da geç dokunursa Pamuk söyler, yelkovan dönmeye devam eder.
  İkinci tur "çeyrek var" için 9. Sürüklemeden farklı bir his: gözlem ve
  zamanlama.
- **Sahne 3 – Oku:** Köprü saatleri: dört saat, dört kart (tam, buçuk, çeyrek
  geçe, çeyrek kala). Seçilen kart sesle okunur.
- **Zaman Kapısı:** "Altı buçuğu göster!" İki kol birlikte: ilk kez akrep kolu
  eklenir, tolerans geniş.
- **Hata:** Köprü yarı yolda durur, tren bekler, balıklar zıplar.
- **Kapanış:** **Vagon eşyası:** Bekçi kedinin verdiği zil.

### Durak 4: Fener Tüneli — "Beşer Beşer"
**Kazanım:** Yelkovanı 5'er dakika sayma; sonra 1'er dakika; 1 saat = 60 dk.

- **Giriş:** Uzun karanlık tünel. Fener beş dakikada bir sönüyor. Pamuk:
  *"Her beş dakikada yağ koymalıyız. Beş dakika ne kadar?"*
- **Sahne 1 – Say:** Çocuk yelkovanı sayıdan sayıya sürükler; her sayıda fener
  parlar ve Pamuk sayar: *"beş, on, on beş..."* 60'ta tünel aydınlanır:
  *"Altmış dakika, bir saat!"*
- **Sahne 2 – Kur:** Pamuk söyler: "yirmi dakika geçiyor", "kırk beş dakika
  geçiyor"; çocuk kurar. Feneri yakmak için doğru kurulum gerekir.
- **Sahne 3 – Damla saati:** Tünel sonunda su saati; her damla bir dakika,
  yelkovan küçük çizgilerde ilerler. "Üç dakika daha" gibi ince kurulumlar.
- **Hata:** Fener söner, ekran kararır, Pamuk'un gözleri karanlıkta parlar ve
  güler; fener yeniden yanar.
- **Kapanış:** **Vagon eşyası:** Fener.
- **Uygulama notu (2026-10-21):** Sahne 1 Say mekaniği (fener her adımda biraz
  daha parlar), Sahne 2 Saati Kur 5'er adım (üç tur: 20, 45, 35; yardım
  merdiveninin sayı basamağı "beşer beşer say" der), Sahne 3 Saati Kur 1'er
  adım (damla saati sürüklerken damla sayar; "üç dakika daha" gibi göreli
  istemler). Zaman Kapısı bu durakta yok; kapı Durak 5'te 5'er dakikayla gelir.

### Durak 5: Büyük İstasyon — "Yedi Kırk Sekiz"
**Kazanım:** Saat ve dakikayı birlikte okuma ve kurma (3:25, 7:48), "kaça
çeyrek var" ifadeleri, dijital-analog eşleme.

- **Giriş:** Kalabalık, kubbeli istasyon. Dev pano: aktarma treni **7:48**'de.
  Pamuk simitçiye dalmış. Çocuk saati tutmalı.
- **Sahne 1 – Panodan kadrana:** Dijital saat verilir, çocuk analogu kurar.
  Önce 5'in katları, sonra tek dakikalar.
- **Sahne 2 – Hangi peron?:** Üç peronda üç analog saat; Pamuk'un bileti
  dijital. Doğru peronu seç.
- **Sahne 3 – Sözlü saat:** Pamuk söyler: "dokuza çeyrek var", "ikiyi yirmi
  geçiyor"; çocuk kurar.
- **Zaman Kapısı:** 5'er dakika hassasiyeti: "dördü yirmi geçeyi göster".
- **Hata:** Tren kaçar; Pamuk simit yerken utangaç bakar; sonraki tren panoda
  belirir, tekrar.
- **Kapanış:** **Vagon eşyası:** Bilet.
- **Uygulama notu (2026-10-21):** Sahne 1 Saati Kur, pano hedefi gösterir;
  ilk iki tur 5'er (3:25, 10:40), son iki tur 1'er dakika (7:48, 1:52) ve
  tur başında "şimdi tek tek dakikalar" repliği. Sahne 2 yeni **Eşleştir**
  mekaniği (`PickClockMechanic`): bilet dijital, üç peron saati analog;
  çeldiriciler akrep-yelkovan yer değiştirmiş ve yalnız dakikası farklı
  saatler. Sahne 3 sözlü istemler `TurkishTime.spoken` ile üretilir (dokuza
  çeyrek var, ikiyi yirmi geçiyor, beşe on var); vagon kapısı açılır. Zaman
  Kapısı'nın sürükleme eşdeğeri (4:20) hazır; kamera eşdeğeri Faz 2.

### Durak 6: Gece Hattı — "Bir Tam Gün"
**Kazanım:** Gün 24 saattir; sabah, öğle, akşam, gece; günün akışı; 24 saatlik
dijital gösterim.

- **Giriş:** Tren bir gün boyunca gidecek. Pencereden sabah ışığı. Pamuk:
  *"Yuvaya kadar bir tam gün sürüyormuş. Bir gün ne kadar?"*
- **Sahne 1 – Pencere:** Çocuk kabin saatini döndürdükçe pencere manzarası
  değişir: güneş doğar, tepeye çıkar, batar, yıldızlar. Akrep iki tam tur
  attığında Pamuk: *"Yirmi dört saat, bir gün!"*
- **Sahne 2 – Pamuk'un günü:** Etkinlik kartları (uyanma, kahvaltı, oyun,
  öğle yemeği, akşam yemeği, uyku) doğru saate sürüklenir; manzara doğrular.
- **Sahne 3 – On beş mi üç mü?:** Dijital 15:00 ile analog 3 eşlenir;
  "öğleden sonra üç" ifadesi. Sabah 3 ile akşam 3 arasındaki fark pencereden
  görülür.
- **Hata:** Pamuk gece yarısı kahvaltı etmeye kalkar, kaşığı düşer, uyur.
- **Kapanış:** **Vagon eşyası:** Yıldız haritası.
- **Uygulama notu (2026-10-21):** Dekor yataklı vagon içi (`Scenery.cabin`),
  pencere ayrı bir nesne (`DayWindow`: saate göre gökyüzü, güneş/ay yayı,
  yıldızlar). Sahne 1 **Gün Turu** mekaniği (`TurnDayMechanic`): akrep 6'dan
  başlar, 12. adımda "öğlen oldu", 24'te biter. Sahne 2 **Kart Yerleştir**
  mekaniği (`PlaceCardsMechanic`, Sırala/Eşleştir'in kart biçimi): altı
  etkinlik kartı, altı yuva (küçük pencere + kadran); yanlışta Pamuk "sabah
  yedi, uyku?" der. Sahne 3 Eşleştir: pano 24 saatlik (15:00, 20:00, 03:00),
  pencere günün bölümünü gösterir, tur başı ve sonu özel sözlü açıklama.

### Durak 7: Pazar Kasabası — "Haftada Bir"
**Kazanım:** Hafta 7 gündür, günlerin sırası, "3 gün sonra" hesabı, haftalık
tekrar eden olaylar.

- **Giriş:** Arıların pazar kasabası. Tren buradan yalnız **Cumartesi** kalkar.
  Pamuk: *"Bugün Salı. Cumartesiye kaç gün var?"*
- **Sahne 1 – Gün taşları:** Yol boyunca yedi taş, günler yazılı ve sesli.
  Çocuk Pamuk'u taş taş yürütür, günleri sayar.
- **Sahne 2 – Kasaba panosu:** Her günün bir olayı (Pazartesi bal, Çarşamba
  çiçek...). Dağınık kartları sıraya diz.
- **Sahne 3 – Takvim Avcısı:** "Bugün Perşembe ise 2 gün sonra?" sorularını
  taşlar üstünde cevapla. Haftanın döngüsel olduğu görülür (Pazar'dan sonra
  yine Pazartesi).
- **Hata:** Pamuk yanlış günde garda bekler, pazar boş, arılar güler.
- **Kapanış:** **Vagon eşyası:** Bal kavanozu.
- **Uygulama notu (2026-10-21):** Bu durakta saat yok. Yedi taş **halka**
  biçiminde dizilir (`StonePathMechanic`), böylece Pazar'dan sonra yine
  Pazartesi'nin geldiği görülür; Pamuk taşın üstünde durur. Sahne 1 yürüme
  modu: Salı'dan Cumartesi'ye 4 adım, sonra Cumartesi'den tam tur 7 adım
  ("yedi gün, bir hafta"). Sahne 2 Kart Yerleştir: yedi gün kartı (olay
  simgeli) yedi sıra yuvasına; yuva sesli "birinci gün, bal günü". Sahne 3
  seçme modu: "n gün sonra" taşına dokununca Pamuk taş taş zıplar, yol
  sayılarak okunur; 7 gün sonra aynı gün turu haftanın döngüsünü pekiştirir.
  Hafta hesapları saf Dart `Week` sınıfında.

### Durak 8: Mevsim Vadisi — "On İki Kasaba"
**Kazanım:** Yıl 12 aydır, ayların isim ve sırası, gün sayıları (31/30/28),
mevsimler, takvim okuma.

- **Giriş:** Büyülü vadi: tren bir günde bir yıl geçer. Her kasaba bir aya
  takılı kalmıştır; Ocak kasabası karlı, Temmuz kasabası güneşli.
- **Sahne 1 – Kasabaları geç:** Tren 12 kasabadan sırayla geçer; her kasabada
  ismi söylenir, tabela parlar. Sonra karışık tabelalar sıraya dizilir.
- **Sahne 2 – Hangi evde kaç gün:** Her kasabada bir ev, pencerelerinde
  gün sayısı. Yumruk tepeleri görseliyle 31/30 ayırt edilir; Şubat'ın küçük
  evi 28.
- **Sahne 3 – Mevsim vagonları:** Dört vagon (ilkbahar, yaz, sonbahar, kış);
  ay kartları doğru vagona yüklenir. Manzara yüklenen mevsime göre değişir.
- **Sahne 4 – Takvim:** Vadinin takvim panosu: "Pamuk'un doğum günü 14 Mart,
  hangi gün?" gibi okuma soruları.
- **Hata:** Yanlış mevsime yüklenen kart titreyip geri uçar, Pamuk şemsiye
  açar ya da bere takar.
- **Kapanış:** **Vagon eşyası:** Dört mevsimden birer yaprak.
- **Uygulama notu (2026-10-21):** Sahne 1 Taş Yolu'nun 12 tabelalı hâli:
  çocuk sıradaki kasabaya basarak ayları sayar (sıra böyle öğrenilir; "karışık
  tabelaları sıraya dizme" 12 kart çocuk ekranına sığmadığı için
  çıkarıldı, sıra bilgisi mevsim vagonlarında ve takvimde yeniden kullanılır).
  Sahne 2 **Seçenek Seç** mekaniği (`ChooseOptionMechanic`): yumruk tepeleri
  görseli (`KnuckleHills`), seçili ayın tepesinde ev, doğru cevapta pencerede
  gün sayısı belirir; altı ay sorulur (Ocak, Nisan, Şubat, Temmuz, Ağustos,
  Kasım; Temmuz-Ağustos çift tepe). Sahne 3 Kart Yerleştir, dört vagon
  kapasite 3; mevsim penceresi (`SeasonWindow`) son yüklenen mevsimi gösterir.
  Sahne 4 **Takvim** mekaniği (`CalendarMechanic`): ay sayfası, doğru güne
  dokunulur; 14 Mart (Cumartesi), Kasım'ın ilk Pazartesi'si (6), Şubat'ın son
  günü (28). Ay/mevsim/takvim hesapları saf Dart `Year` sınıfında.

### Durak 9: Kar Dağı Eteği — "Son Tren"
**Kazanım:** Birimler arası dönüşüm (1 saat = 60 dk, 1 gün = 24 saat, 1 hafta
= 7 gün, 1 yıl = 12 ay / 365 gün) ve hızlı okuma.

- **Giriş:** Kar başlamak üzere. Tarife karmaşık: "2 saat sonra", "yarım gün
  sonra". Pamuk: *"Bunlar kaç dakika, kaç saat? Hızlı olmalıyız."*
- **Sahne 1 – Terazi:** İki kefeli terazi; bir kefede "1 saat", diğerine
  dakika ağırlıkları konur; 60'ta dengelenir. Aynı şekilde gün-saat,
  hafta-gün.
- **Sahne 2 – Tarife:** Tarife satırları dönüştürülerek doğru tren seçilir.
- **Sahne 3 – Hızlı Saat:** Kar tanesi sayacı: süre bitmeden saatleri oku
  (süreli tekrar modu, 2-4. duraklardan karışık).
- **Hata:** Kar hızlanır, tren bir an durur, Pamuk nefesiyle camı buğular ve
  kalp çizer; tekrar.
- **Kapanış:** **Vagon eşyası:** Yuvanın anahtarı.
- **Uygulama notu (2026-10-21):** Sahne 1 **Terazi** mekaniği
  (`BalanceMechanic`): ağırlıklara dokununca sağ kefeye gider, toplam sesle
  söylenir, fazla gelince kefe düşer ve son ağırlık geri alınır; üç tur
  (60 dk, 24 saat, 7 gün). Sahne 2 Seçenek Seç ile tarife panosu
  (`TimetableProp`): dört satır çevrilir, en erken tren seçilir. Sahne 3
  **Hızlı Saat** mekaniği (`QuickClockMechanic`): kar tanesi sayacı 10 sn,
  sekiz saat (tam, çeyrek, 5'er karışık), süre bitince doğru tabela gösterilir
  ve devam edilir; sonunda doğru sayısı söylenir, ceza yok. Oyun sonu modu bu
  mekaniği yeniden kullanacak.

### Durak 10: Yuva — "Büyük Saat Kilidi"
**Kazanım:** Tüm kazanımların karışık uygulaması.

- **Giriş:** Kar Dağı'nın tepesinde Pamuk'un yuvası; kapıda büyük bir saat
  kilidi. Her dişli bir önceki durağın görevini ister.
- **Sahne:** Beş dişli, beş karışık görev (kur, oku, gün akışı, takvim,
  dönüşüm). Her dişli dönünce kapı biraz açılır.
- **Final sinematiği (30-40 sn):** Kapı açılır, Pamuk vagondaki eşyaları
  yuvaya taşır (saat duvara, atkı askıya, fener rafa, yıldız haritası
  tavana). Pencereden ilk kar. Pamuk esner: *"Teşekkürler, makinist. Baharda
  görüşürüz."* Uyur. Çocuk treni yıldızların altında geri sürer. Jenerik.

- **Uygulama notu (2026-10-21):** Zirve dekoru (`Scenery.summit`) kapıdaki
  kilidi gösterir; her sahnenin üstünde `LockProp` (beş dişli, dönenler altın,
  kapı dişli sayısı kadar aralanır). Beş dişli: Saati Kur (5:00, 9:30, 2:45),
  Saati Oku (tam, çeyrek, 5'er), Kart Yerleştir (dört etkinlik), Takvim
  (21 Aralık, kışın başlangıcı), Terazi (1 gün = 24 saat). Final sinematiği
  `finale.dart`: yuva içi dekor (`Scenery.den`), toplanan eşyalar rafta tek
  tek belirir, pencerede ilk kar, Pamuk uyur, tren yıldızların altında
  Pamuk'suz geri döner, jenerik (başlık, "Makinist: Sen", "Son"). Jenerik
  sesle de okunur.

**Mini oyun: Kol Saati (2026-10-21).** Hikâyeden bağımsız, bireysel,
süreli ve puanlı. Başlıktaki haritada hep görünen mor "kol" işaretinden
açılır. Kamera varsa (web/Chrome) çocuk kollarıyla saati gösterir: sol kol
akrep, sağ kol yelkovan; kamera yoksa ya da izin verilmezse aynı oyun kadranı
sürükleyerek oynanır. Akış: kalibrasyon (iki kol görününce 1,2 sn sonra
başlar) → 3-2-1 → 10 tur: Pamuk saati söyler, süre çubuğu erir, poz 1,5 sn
sabit kalınca puan (100 + kalan süre bonusu 0-100 + seri bonusu 25/tur, en
çok 100); süre dolunca ceza yok, sıradaki. Turlar kolaydan zora: 3 tam saat,
3 buçuk, 2 çeyrek, 2 beşer dakika; toleranslar seviyeye göre 22°→13°, her
oynayışta saatler değişir. Sonuç: puan, 0-3 yıldız, en iyi puan (öğrenci
başına kayıt). Gizlilik satırı ekranda: görüntü yalnızca cihazda işlenir.
Kod: `lib/features/armclock/` (saf mantık `ArmClockGame`, ekran
`ArmClockScreen`). Kamera doğruluğu sınıfta denenmediği için toleranslar
ilk gözlemden sonra ayarlanacak.

**Oyun sonu modu:** Harita üstünde istenen durak yeniden oynanır; "Hızlı
Saat" ve "Zaman Kapıları" bağımsız olarak açılır (sınıf modu için).

- **Uygulama notu (2026-10-21):** Harita başlık ekranındadır (`RouteMap`):
  kıvrımlı ray üstünde on durak işareti (ödül simgeleri), tren tamamlanan
  durakta durur. Kilitli duraklar soluk ve dokunulmaz; sıradaki durağa
  dokunmak hikâyeyi sürdürür, tamamlanmış durağa dokunmak onu baştan
  oynatır (ilerlemeye yazılmaz, ödül verilmez, hatalar ısınmaya eklenmez).
  Hikâye bitince haritada kar tanesi (Hızlı Saat: her açılışta farklı on
  saat) ve kapı (Zaman Kapıları: üç kapı, sürükleme eşdeğeri; kamera Faz 2)
  belirir. Menü yoktur; harita dünyanın parçasıdır.

## 6. Sınıf düzeyine göre kullanım

| Sınıf | Önerilen duraklar | Not |
|---|---|---|
| 2 | Prolog, 1-3, 6-7 (basit sahneler) | Dakika sahneleri kilitli, öğretmen açabilir |
| 3 | 1-8 | Durak 4-5 tam hassasiyet |
| 4 | Tümü, Hızlı Saat ve Zaman Kapıları | Dönüşüm ve final |

MEB kazanımlarıyla birebir eşleme öğretmen panelinde öğretmen tarafından
doğrulanacak; bu belge pedagojik sırayı tanımlar.

- **Uygulama notu (2026-10-21):** Öğretmen paneli (`TeacherPanel`) başlıkta
  Pamuk'a uzun basınca açılır: öğrenci profilleri (her öğrencinin kendi
  kaydı), sınıf ön ayarı (2: duraklar 1-3 ve 6-7; 3: 1-8; 4/Tümü: 1-10),
  ilerleme ve "takılınan sahneler" raporu (sahne başına hata sayısı), tüm
  kilitleri açma, durağa atlama, kamera testi. Sınıf ön ayarı duraklar
  atlar (2. sınıfta 3'ten 6'ya); sınıfın son durağı bitince Pamuk "bu yılki
  yolculuk burada bitti" der, Yuva ve final yalnız tam yolculukta gelir.
  Haritada ön ayar dışındaki duraklar kilitli görünür.

## 7. Görsel ve ses stili

- **Vektör animasyon.** Düz renkli, kalın hatlı, yuvarlak formlar. Pamuk ve
  tren ana varlıklar; arka planlar katmanlı parallaks.
- Renk paleti: sıcak sonbahar tonlarından soğuk kış tonlarına durak durak
  geçiş. Akrep kırmızı ve yelkovan mavi bu paletten bağımsız, hep aynı.
- Sinematikler Rive (vektör, durum makineli) ile yapılır; sahne geçişleri
  Flutter animasyonları.
- Ses: önce TTS (Türkçe, yavaş hız), replikler tek listeden okunur. Gerçek
  ses kaydı geldiğinde aynı kimliklerle dosyalar değiştirilir. Efektler:
  düdük, buhar, zil, dişli, kar. Müzik: duraklara göre tema varyasyonları.
