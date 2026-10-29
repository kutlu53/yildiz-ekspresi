/// Pamuk'un tüm replikleri. Her replik bir kimlik taşır; TTS bu metni okur,
/// gerçek ses kaydı geldiğinde aynı kimlikle dosya eşlenir.
class Line {
  final String id;
  final String text;

  const Line(this.id, this.text);
}

class Lines {
  Lines._();

  // Genel geri bildirim
  static const great = Line('fb.great', 'Harika!');
  static const wellDone = Line('fb.wellDone', 'Aferin, tam öyle!');
  static const notYet = Line('fb.notYet', 'Hmm, henüz değil.');
  static const tryAgain = Line('fb.tryAgain', 'Olsun, bir daha deneyelim.');
  static const showYou = Line('fb.showYou', 'Bak, ben göstereyim.');
  static const hintMinute =
      Line('fb.hintMinute', 'Yelkovana bak, uzun olan.');
  static const hintHour = Line('fb.hintHour', 'Akrebe bak, kısa olan.');
  static const hintNumerals =
      Line('fb.hintNumerals', 'Sayılara bak, hangisini gösteriyor?');
  static const resume = Line('fb.resume', 'Kaldığımız yerden devam ediyoruz!');

  /// Kutlama replikleri; "Harika!" ve "Aferin" yerine sırayla dönerek okunur.
  static const praise = [
    great,
    wellDone,
    Line('fb.praise2', 'Süpersin, makinist!'),
    Line('fb.praise3', 'Bravo!'),
    Line('fb.praise4', 'İşte bu!'),
    Line('fb.praise5', 'Tam isabet!'),
  ];

  // Prolog
  static const prologWake =
      Line('prolog.wake', 'Hııı... Ben Pamuk, uykucu ayı Pamuk. Ne kadar uyumuşum ben böyle?');
  static const prologClock =
      Line('prolog.clock', 'Saatimin elleri düşmüş! Saat kaç, bilmiyorum.');
  static const prologSnow = Line('prolog.snow',
      'Kar gelmeden Kar Dağı\'ndaki yuvama dönmeliyim. Bana yardım eder misin, makinist?');
  static const prologGo =
      Line('prologGo', 'Trenimiz garajda bekliyor. Hadi gidelim!');

  // Durak 1: Garaj
  static const s1Travel = Line('s1.travel', 'İşte garaj! Yıldız Ekspresi burada.');
  static const s1Intro = Line('s1.intro',
      'Bu bizim trenimiz, Yıldız Ekspresi. Ama kabindeki saatin elleri de düşmüş.');
  static const s1AttachFirst =
      Line('s1.attachFirst', 'Önce kısa olanı tak. Kısa olan akrep.');
  static const s1AttachHourDone = Line('s1.attachHourDone',
      'Kısa olan akrep, saati gösterir. Şimdi uzun olanı tak.');
  static const s1AttachMinuteDone = Line('s1.attachMinuteDone',
      'Uzun olan yelkovan, dakikayı gösterir. Saatimiz tamam!');
  static const s1WrongFirst =
      Line('s1.wrongFirst', 'Bu uzun olan, yelkovan. Önce kısa olanı, akrebi.');
  static const s1TapIntro =
      Line('s1.tapIntro', 'Şimdi bakalım hangisi hangisi.');
  static const s1TapHour = Line('s1.tapHour', 'Akrebe dokun.');
  static const s1TapMinute = Line('s1.tapMinute', 'Yelkovana dokun.');
  static const s1TapWrongHour =
      Line('s1.tapWrongHour', 'O yelkovan. Akrep kısa olan.');
  static const s1TapWrongMinute =
      Line('s1.tapWrongMinute', 'O akrep. Yelkovan uzun olan.');
  static const s1Turn = Line('s1.turn',
      'Yelkovanı bir tam tur döndür. Akrebe ne oluyor, izle.');
  static const s1TurnDone = Line('s1.turnDone',
      'Yelkovan bir tur attı, akrep bir sayı ilerledi. Bir saat geçti!');
  static const s1Outro =
      Line('s1.outro', 'Lokomotif çalıştı! Cep saatimi de vagona koyuyorum.');

  // Durak 2: İlk Hat
  static const s2Travel =
      Line('s2.travel', 'Yola çıktık! İlk hat bizi bekliyor.');
  static const s2Intro = Line('s2.intro',
      'Tarifede kocaman bir sekiz yazıyor. Saat sekizde kalkıyormuşuz. Sekiz nasıl olur?');
  static const s2Lever = Line('s2.lever',
      'Tam saatte yelkovan hep on ikide durur. Akrebi sekize getir, bırak.');
  static const s2LeverDone =
      Line('s2.leverDone', 'Saat sekiz! Şimdi büyük kolu aşağı çek.');
  static const s2LeverStuck = Line('s2.leverStuck',
      'Kol kıpırdamıyor. Önce saati sekize kurmalıyız.');
  static const s2Pulled = Line('s2.pulled', 'Düdük çaldı! Kalkıyoruz!');
  static const s2ReadIntro = Line('s2.readIntro',
      'Küçük istasyonda bir yük treni manevra yapıyor; vagonlarda saatler yazılı. İstasyon saatiyle aynı olan vagona dokun.');
  static const s2GuessIntro = Line('s2.guessIntro',
      'Ben de öğrendim, bir deneyeyim. Saati söyleyeceğim; doğruysa "doğru", yanlışsa "yanlış" tabelasına dokun.');
  static const s2GuessDone =
      Line('s2.guessDone', 'Sen gerçek bir makinistsin! Yola devam.');
  static const s2ReadHint = Line('s2.readHint',
      'Yelkovan on ikide, akrep hangi sayıda? O sayı saati söyler.');
  static const s2GateIntro = Line('s2.gateIntro',
      'Bir tünel kapısı! Kapı ancak saat üçü görünce açılıyor.');
  static const s2GateDone = Line('s2.gateDone', 'Kapı açıldı! Geçiyoruz.');
  static const s2Wrong = Line('s2.wrong',
      'Tren kalkmadı... Ben de biraz kestirdim. Tekrar deneyelim.');
  static const s2Outro =
      Line('s2.outro', 'İlk hattı geçtik! Atkımı vagona asıyorum.');

  // Durak 3: Çarklı Köprü
  static const s3Travel =
      Line('s3.travel', 'Suyun sesini duyuyor musun? Çarklı Köprü yaklaşıyor.');
  static const s3Intro = Line('s3.intro',
      'Çarklı Köprü! Bekçi kedi diyor ki köprü yalnız buçukta iniyormuş.');
  static const s3Half = Line('s3.half',
      'Buçuk için yelkovanı altıya getir. Akrebe ne olduğuna dik bak.');
  static const s3HalfDone = Line('s3.halfDone',
      'Bak, akrep iki sayının tam ortasında kaldı. Buçuk böyle olur!');
  static const s3BellIntro = Line('s3.bellIntro',
      'Köprü zili çeyrekte çalınır. Yelkovan dönüyor; tam üçe gelince zile dokun! Kaçırırsan yelkovanı geri alırım, yeniden deneriz.');
  static const s3BellTo = Line('s3.bellTo',
      'Şimdi çeyrek var: yelkovan dokuza gelince dokun.');
  static const s3BellEarly =
      Line('s3.bellEarly', 'Biraz erken, yelkovan daha gelmedi.');
  static const s3BellLate =
      Line('s3.bellLate', 'Geç kaldık, yelkovan geçti. Geri alıyorum, bir daha dene.');
  static const s3BellDone = Line('s3.bellDone', 'Tam zamanında! Zil çaldı.');
  static const s3ReadIntro = Line('s3.readIntro',
      'Bekçi kedi soruyor: köprü saati ne diyor? Doğru tabelaya dokun.');
  static const s3GateIntro = Line('s3.gateIntro',
      'Son kapı. Altı buçuğu kur, kapı açılsın.');
  static const s3Wrong = Line('s3.wrong',
      'Köprü yarı yolda durdu, balıklar bize gülüyor. Tekrar deneyelim.');
  static const s3Outro = Line('s3.outro',
      'Köprüyü geçtik! Bekçi kedi bize zilini hediye etti.');

  // Durak 4: Fener Tüneli
  static const s4Travel = Line('s4.travel',
      'Önümüzde uzun bir tünel var. İçerisi kapkaranlık, fenerimiz hazır mı?');
  static const s4Intro = Line('s4.intro',
      'Fener Tüneli! Fener her beş dakikada bir sönüyor, yağ koymalıyız. Beş dakika ne kadar?');
  static const s4Count = Line('s4.count',
      'Yelkovanı sayıdan sayıya götür. Her sayıda beş dakika geçer, fener parlar.');
  static const s4CountDone = Line('s4.countDone',
      'Altmış dakika, bir tam saat! Yelkovan bir tur attı; bak, kısa akrep de dokuzdan ona geçti. Tünel aydınlandı.');
  static const s4SetIntro = Line('s4.setIntro',
      'Şimdi fenerin yağ saati. Söylediğim dakikaya kur, fener yansın.');
  static const s4SetHint = Line('s4.setHint',
      'Sayıları beşer beşer say: beş, on, on beş...');
  static const s4SetDone = Line('s4.setDone', 'Fener yandı! Tünel biraz daha aydınlık.');
  static const s4DripIntro = Line('s4.dripIntro',
      'Tünelin sonunda bir damla saati var. Her damla bir dakika; yelkovan küçük çizgilerde ilerler.');
  static const s4DripDone =
      Line('s4.dripDone', 'Tam o kadar! Damla damla saymayı da öğrendik.');
  static const s4Wrong = Line('s4.wrong',
      'Fener söndü... Karanlıkta gözlerim parlıyor, görüyor musun? Tekrar deneyelim.');
  static const s4Outro = Line('s4.outro',
      'Tünelden çıktık! Feneri vagona asıyorum, yolumuzu aydınlatsın.');

  // Durak 5: Büyük İstasyon
  static const s5Travel = Line('s5.travel',
      'Ne kalabalık! Büyük İstasyon\'a geliyoruz. Burada aktarma yapacağız.');
  static const s5Intro = Line('s5.intro',
      'Panoda yazıyor: aktarma treni yedi kırk sekizde. Mmm, simit kokusu... Saati sen tut, makinist!');
  static const s5BoardIntro = Line('s5.boardIntro',
      'Panodaki sayıları kadrana kur. İlk sayı akrep, ikinci sayı yelkovan.');
  static const s5BoardFine = Line('s5.boardFine',
      'Şimdi tek tek dakikalar. Yelkovan küçük çizgilerde ilerler.');
  static const s5BoardDone = Line('s5.boardDone', 'Tam panodaki gibi! Düdük çaldı.');
  static const s5BoardHint = Line('s5.boardHint',
      'İlk sayı saat: akrep oraya. İkinci sayı dakika: yelkovan için beşer beşer say.');
  static const s5PlatformIntro = Line('s5.platformIntro',
      'Biletimde saat yazıyor. Üç peronda üç saat var; hangisi biletimle aynı? Ona dokun.');
  static const s5PlatformHint = Line('s5.platformHint',
      'Önce akrebe bak: biletteki ilk sayıyı gösteren saat hangisi?');
  static const s5PlatformDone = Line('s5.platformDone', 'Doğru peron! Tren burada.');
  static const s5SpokenIntro = Line('s5.spokenIntro',
      'Kondüktör saati sözle söylüyor. Söylediğini kur, vagon kapısı açılsın.');
  static const s5SpokenDone = Line('s5.spokenDone', 'Kapı açıldı, binelim!');
  static const s5GateIntro = Line('s5.gateIntro',
      'Son kapı. Dördü yirmi geçeyi göster, geçelim.');
  static const s5Wrong = Line('s5.wrong',
      'Tren kaçtı... Ben simit yiyordum. Panoda yeni tren var, tekrar deneyelim.');
  static const s5Outro = Line('s5.outro',
      'Aktarmayı yaptık! Biletimi vagona koyuyorum, hatıra olsun.');

  // Durak 6: Gece Hattı
  static const s6Travel = Line('s6.travel',
      'Bu hat çok uzun. Yataklı vagona geçelim, yolda uyuyabiliriz.');
  static const s6Intro = Line('s6.intro',
      'Yuvaya kadar bir tam gün sürüyormuş. Bir gün ne kadar? Pencereden bakalım.');
  static const s6WindowIntro = Line('s6.windowIntro',
      'Akrebi sayıdan sayıya götür. Her sayıda bir saat geçer, pencere değişir.');
  static const s6Noon = Line('s6.noon',
      'On iki saat geçti, akrep bir tur attı. Güneş tepede, öğlen oldu!');
  static const s6WindowDone = Line('s6.windowDone',
      'Akrep iki tur attı: yirmi dört saat, bir gün! Yıldızlar yine çıktı.');
  static const s6DayIntro = Line('s6.dayIntro',
      'Benim günüm karışmış. Kartları doğru saate koy; pencere sana yardım eder.');
  static const s6DayDone = Line('s6.dayDone',
      'Günüm düzeldi! Sabah uyanırım, akşam yemek, gece uyku.');
  static const s6FifteenIntro = Line('s6.fifteenIntro',
      'Panoda on beş yazıyor ama kadranda on beş yok! Pencereye bak, doğru kadrana dokun.');
  static const s6FifteenHint = Line('s6.fifteenHint',
      'On ikiden sonra saymaya devam: on üç bir, on dört iki, on beş üç.');
  static const s6Wrong = Line('s6.wrong',
      'Gece yarısı kahvaltı mı? Kaşığım düştü... Bir daha deneyelim.');
  static const s6Outro = Line('s6.outro',
      'Bir gün geçti. Yıldız haritasını vagona asıyorum; gece yolumuzu gösterir.');

  // Durak 7: Pazar Kasabası
  static const s7Travel = Line('s7.travel',
      'Vızıltı duyuyor musun? Arıların pazar kasabasına geliyoruz. Bal kokuyor!');
  static const s7Intro = Line('s7.intro',
      'Tren buradan yalnız Cumartesi kalkıyormuş. Bugün Salı. Cumartesiye kaç gün var?');
  static const s7StonesIntro = Line('s7.stonesIntro',
      'Yoldaki taşlarda günler yazıyor. Beni taş taş yürüt, günleri sayalım.');
  static const s7StonesHint = Line('s7.stonesHint',
      'Benim durduğum taşın hemen yanındaki taşa bas.');
  static const s7StonesDone = Line('s7.stonesDone',
      'Yedi taş, yedi gün: bir hafta. Haftanın sonunda yol başa döner.');
  static const s7BoardIntro = Line('s7.boardIntro',
      'Kasaba panosu karışmış. Günleri sıraya diz: birinci gün Pazartesi, bal günü.');
  static const s7BoardWrong = Line('s7.boardWrong',
      'Arılar güldü, o gün oraya gelmez. Pazartesi, Salı, Çarşamba diye say.');
  static const s7BoardDone = Line('s7.boardDone',
      'Pano düzeldi! Her gün bir olay; Cumartesi de bizim tren.');
  static const s7HuntIntro = Line('s7.huntIntro',
      'Şimdi takvim avı. Söylediğim kadar gün sonra hangi taşa varırım? Ona dokun.');
  static const s7HuntHint = Line('s7.huntHint',
      'Benim taşımdan başla, yanındaki taşları say: bir, iki...');
  static const s7HuntDone = Line('s7.huntDone',
      'Takvim avcısı oldun! Günleri sayınca hangi gün geleceğini biliyoruz.');
  static const s7Wrong = Line('s7.wrong',
      'Yanlış günde garda bekledim, pazar bomboştu. Arılar bana güldü. Tekrar deneyelim.');
  static const s7Outro = Line('s7.outro',
      'Cumartesi geldi, tren kalkıyor! Arılar bana bir kavanoz bal verdi.');

  // Durak 8: Mevsim Vadisi
  static const s8Travel = Line('s8.travel',
      'Bu vadi büyülü: tren burada bir günde bir yıl geçer. Kasabalar aylara takılı kalmış!');
  static const s8Intro = Line('s8.intro',
      'Ocak kasabası karlı, Temmuz kasabası güneşli. On iki kasaba var; bir yıl kaç ay?');
  static const s8TownsIntro = Line('s8.townsIntro',
      'Kasabaların tabelalarında aylar yazıyor. Sıradaki kasabaya bas, ayları sayalım.');
  static const s8TownsHint = Line('s8.townsHint',
      'Benim kasabamın hemen yanındaki tabelaya bas.');
  static const s8TownsDone = Line('s8.townsDone',
      'On iki ay, bir yıl. Yıl da hafta gibi döner: Aralık biter, Ocak başlar.');
  static const s8HousesIntro = Line('s8.housesIntro',
      'Her kasabada bir ev. Yumruğuna bak: tepedeki aylar otuz bir, çukurdakiler otuz gün. Şubat en küçük ev.');
  static const s8HousesHint = Line('s8.housesHint',
      'Sarı tepeye bak: tepede mi, çukurda mı? Tepe otuz bir, çukur otuz.');
  static const s8HousesDone = Line('s8.housesDone',
      'Evleri saydık! Tepeler otuz bir, çukurlar otuz, Şubat yirmi sekiz; dört yılda bir yirmi dokuz.');
  static const s8WagonsIntro = Line('s8.wagonsIntro',
      'Dört vagon, dört mevsim. Ay kartlarını doğru vagona yükle; manzara değişir.');
  static const s8WagonsWrong = Line('s8.wagonsWrong',
      'Kart titreyip geri uçtu! O ay o mevsimde değil. Bere mi taksam, şemsiye mi açsam?');
  static const s8WagonsDone = Line('s8.wagonsDone',
      'Vagonlar doldu: her mevsim üç ay, dört mevsim on iki ay.');
  static const s8CalendarIntro = Line('s8.calendarIntro',
      'Vadinin takvim panosu. Üstte günler, kutularda tarihler.');
  static const s8CalendarHint = Line('s8.calendarHint',
      'Birden başla, sırayla say. Sayının üstündeki sütun hangi gün olduğunu söyler.');
  static const s8CalendarDone = Line('s8.calendarDone',
      'Takvimi okuyabiliyorsun! Artık doğum günümü hiç kaçırmam.');
  static const s8Wrong = Line('s8.wrong',
      'Hmm, yanlış kasabada indim; burası başka bir ay. Tekrar deneyelim.');
  static const s8Outro = Line('s8.outro',
      'Bir yıl geçti! Dört mevsimden birer yaprak topladım, vagona koyuyorum.');

  // Durak 9: Kar Dağı Eteği
  static const s9Travel = Line('s9.travel',
      'Hava soğudu, dağın tepesi bembeyaz. Kar başlamak üzere, acele edelim!');
  static const s9Intro = Line('s9.intro',
      'Tarife karmakarışık: iki saat sonra, yarım gün sonra... Bunlar kaç dakika, kaç saat? Hızlı olmalıyız.');
  static const s9BalanceIntro = Line('s9.balanceIntro',
      'Terazi! Sol kefede büyük birim, sağ kefeye küçükleri koy. Denk gelince kiriş düzelir.');
  static const s9BalanceOver = Line('s9.balanceOver',
      'Fazla geldi, kefe düştü! Son ağırlığı geri alıyorum.');
  static const s9BalanceDone = Line('s9.balanceDone',
      'Üç terazi, üç denge: altmış dakika bir saat, yirmi dört saat bir gün, yedi gün bir hafta.');
  static const s9TimetableIntro = Line('s9.timetableIntro',
      'Tarifede dört tren var. Her satırı çevirelim, en erken treni bulalım.');
  static const s9TimetableHint = Line('s9.timetableHint',
      'Teraziyi hatırla: bir saat altmış dakika, bir gün yirmi dört saat, bir hafta yedi gün.');
  static const s9TimetableDone = Line('s9.timetableDone',
      'En erken tren iki saat sonraki. Bilet aldım, kar yetişemeyecek!');
  static const s9QuickIntro = Line('s9.quickIntro',
      'Kar taneleri eriyor! Her saati kar bitmeden oku. Hazır mısın, makinist?');
  static const s9QuickLate = Line('s9.quickLate',
      'Kar hızlandı, tren bir an durdu! Cama kalp çizdim. Devam.');
  static const s9QuickDone = Line('s9.quickDone',
      'Trene yetiştik! Saatleri rüzgâr gibi okuyorsun.');
  static const s9Wrong = Line('s9.wrong',
      'Hmm, o tren çok geç kalkıyor; kar yağar. Tekrar bakalım.');
  static const s9Outro = Line('s9.outro',
      'Son tren kalkıyor! Yuvanın anahtarını vagona koydum; bir sonraki durak evim.');

  // Durak 10: Yuva
  static const s10Travel = Line('s10.travel',
      'Kar Dağı\'nın tepesi! Yuvam orada, kapıda büyük saat kilidi var.');
  static const s10Intro = Line('s10.intro',
      'Kilidin beş dişlisi var. Her dişli yolda öğrendiğimiz bir şeyi soruyor. Hadi makinist, son görev!');
  static const s10Set = Line('s10.set',
      'Birinci dişli: söylediğim saati kur.');
  static const s10Read = Line('s10.read',
      'İkinci dişli: saati oku, doğru tabelaya dokun.');
  static const s10Day = Line('s10.day',
      'Üçüncü dişli: günüm yine karışmış. Kartları saatlere koy.');
  static const s10Calendar = Line('s10.calendar',
      'Dördüncü dişli: takvim. Kışın başladığı günü bul.');
  static const s10Balance = Line('s10.balance',
      'Beşinci dişli: terazi. Bir gün kaç saat?');
  static const s10Gear = Line('s10.gear',
      'Dişli döndü! Kapı biraz daha açıldı.');
  static const s10Wrong = Line('s10.wrong',
      'Dişli takıldı... Kapı bekliyor. Bir daha deneyelim.');
  static const s10Outro = Line('s10.outro',
      'Beş dişli de döndü, kilit açıldı! Kapı açılıyor...');

  // Final
  static const finalDoor = Line('final.door',
      'İşte yuvam! Sıcacık, tam bıraktığım gibi.');
  static const finalItems = Line('final.items',
      'Saat duvara, atkı askıya, fener rafa, yıldız haritası tavana. Hepsini yolda topladık!');
  static const finalSnow = Line('final.snow',
      'Pencereye bak... İlk kar! Tam zamanında geldik.');
  static const finalThanks = Line('final.thanks',
      'Teşekkürler, makinist. Baharda görüşürüz...');
  static const finalCredits = Line('final.credits',
      'Yıldız Ekspresi. Makinist: sen. Yol arkadaşı: Pamuk. Son.');

  // Oyun sonu modu
  static const extraQuickIntro = Line('extra.quickIntro',
      'Kar bulutu geldi! Kar eriyene kadar saatleri oku. Her seferinde farklı saatler.');
  static const extraQuickDone = Line('extra.quickDone',
      'Kar bulutu geçti! Bir daha oynamak istersen kar tanesine dokun.');
  static const extraGatesIntro = Line('extra.gatesIntro',
      'Üç Zaman Kapısı art arda. Söylediğim saati kur, kapılar açılsın.');
  static const extraBye = Line('extra.bye',
      'Haritaya dönüyoruz. İstediğin durağa dokunabilirsin!');

  static const gradeEnd = Line('end.grade',
      'Bu yılki yolculuğumuz burada bitti. Büyüyünce Kar Dağı\'na kadar gideriz!');

  // Kol Saati mini oyunu
  static const armIntroCamera = Line('arm.introCamera',
      'Kol Saati! Sol kolun akrep, sağ kolun yelkovan. Söylediğim saati kollarınla göster, puan topla.');
  static const armIntroDrag = Line('arm.introDrag',
      'Kol Saati! Söylediğim saati süre bitmeden kur, puan topla. Hazırsan başla.');
  static const armCalibrate = Line('arm.calibrate',
      'Kameradan iki adım geri git, kolların görünsün. Seni görünce başlıyoruz.');
  static const armCameraFallback = Line('arm.cameraFallback',
      'Kamera açılamadı, olsun: aynı oyunu kadranla oynuyoruz.');
  static const armReady = Line('arm.ready', 'Seni gördüm! Hazır ol...');
  static const armTimeout = Line('arm.timeout', 'Süre doldu, sıradaki!');
  static const armDone = Line('arm.done', 'Bir daha oynamak istersen "bir daha"ya dokun.');
  static const armPrivacy = Line('arm.privacy',
      'Görüntü yalnızca bu cihazda işlenir; kaydedilmez, hiçbir yere gönderilmez.');
  static const armDragHint = Line('arm.dragHint',
      'Elleri sürükle, doğru yerde bırak. Hızlı olursan daha çok puan!');

  static const rotatePhone = Line('ui.rotate',
      'Telefonu yan çevir, tren öyle daha iyi görünüyor!');

  // Devamı (duraklar eksikse)
  static const endSoon = Line('end.soon',
      'Yolculuğumuz burada bekliyor. Yakında devam edecek!');
  static const endBye = Line('end.bye', 'Görüşürüz makinist!');
}
