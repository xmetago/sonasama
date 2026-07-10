import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../services/hive_database_service.dart';
import '../providers/dava_provider.dart';
import 'countdown_timer_widget.dart';

// ═══════════════════════════════════════════════════════════════
// 🏛️  CEZALAR + CEZA YÖNETİMİ — Birleşik sağ panel
// ═══════════════════════════════════════════════════════════════

/// [CezalarPage] / [CezaYonetimWidget] için ortak dava özeti modeli.
class CezalarUnifiedDava {
  final String adi;
  final String davali;
  final String davaci;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;

  const CezalarUnifiedDava({
    required this.adi,
    required this.davali,
    this.davaci = '',
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
  });
}

/// Mahkeme renk paleti (mor tonları + kritik aksiyonda kırmızı)
class _MahkemeRenkler {
  static const Color koyu = Color(0xFF26215C); // Başlık şeritleri, koyu zemin
  static const Color ortaKahve = Color(0xFF534AB7); // Vurgu, seçili durumlar
  static const Color altin = Color(0xFFCECBF6); // Kenarlık, ikincil metin
  static const Color kirmizi = Color(0xFFA32D2D); // Yalnızca ceza onayı / kritik butonlar
  static const Color krem = Color(0xFFEEEDFE); // Panel zemini
  static const Color kemik = Color(0xFFF1EFE8); // Liste yüzeyleri, nötr alan
  // ignore: unused_field — palet rezervi (avukat / gizem vurguları için)
  static const Color yesil = Color(0xFF1B4D2E); // Koyu yeşil — avukat
  // ignore: unused_field
  static const Color mor = Color(0xFF2D0B4E); // Mor — gizem
  static const Color gri = Color(0xFF5C5C5C); // Gri — nötr
}

/// Dava kartı + mahkeme temalı ceza yönetimi (tek panel).
class CezalarCezaUnifiedPanel extends StatefulWidget {
  final CezalarUnifiedDava dava;
  final String? davaId;
  final String? userEmail;
  final bool embeddedMiddlePane;
  /// Yargıla / hüküm kartı ile uyumlu açılış zamanı (geri sayım için).
  final DateTime? davaOpenedAt;
  /// Alt sayfa / sheet kapatma: ceza onayından sonra tetiklenir.
  final VoidCallback? onPenaltyApplied;
  /// Üstte kapat düğmeli başlık (DraggableSheet vb.).
  final bool showSheetCloseHeader;

  const CezalarCezaUnifiedPanel({
    super.key,
    required this.dava,
    this.davaId,
    this.userEmail,
    this.embeddedMiddlePane = false,
    this.davaOpenedAt,
    this.onPenaltyApplied,
    this.showSheetCloseHeader = false,
  });

  @override
  State<CezalarCezaUnifiedPanel> createState() => _CezalarCezaUnifiedPanelState();
}

class _CezalarCezaUnifiedPanelState extends State<CezalarCezaUnifiedPanel>
    with TickerProviderStateMixin {
  /// [readyPenalties] içindeki varsayılan hazır ceza (Hüküm kartı / Ceza Ver akışı).
  static const String _defaultHazirCezaName = '🎭 19  Mucizesi';

  /// [ModernHukumCard._kunyeExpanded] ile aynı: `true` iken künye detayı gizli (kapalı).
  bool _cezaKunyeExpanded = true;

  /// Künye alt satırı: "Görev hüküm" alanı genişletilmiş mi.
  bool _kunyedeGorevHukumAlaniAcik = false;

  /// Göreviniz rolü için kayıtlı hüküm var mı (Rol kartı ikon rengi ile uyumlu).
  bool _gorevHukumVar = false;

  /// Görev hükümü kısa önizleme metni.
  String? _gorevHukumOnizleme;

  String activeCategory = 'Hazır Ceza';
  final List<String> categories = ['Hazır Ceza', 'Üyelerden'];

  int? selectedReadyIndex;
  String? selectedMember;
  int? selectedMemberPenaltyIndex;
  String? selectedPenaltyText;
  int? expandedReadyIndex;
  String? expandedMember;
  int? expandedMemberPenaltyIndex;

  int _commentCount = 0;
  int _retweetCount = 0;
  int _likeCount = 0;
  int _dislikeCount = 0;

  final TextEditingController _customTitleCtrl = TextEditingController();
  final TextEditingController _customDescriptionCtrl = TextEditingController();
  final FocusNode _customTitleFocus = FocusNode();
  final FocusNode _customDescriptionFocus = FocusNode();
  bool _isCustomPenaltyValid = false;
  bool _isCustomPenaltySelected = false;
  bool _isPenaltyApplied = false;
  bool _isMahkemeKarariVisible = false;

  TabController? _tabController;
  AnimationController? _coffinAnimationController;
  AnimationController? _gavelAnimController;   // Çekiç sallama animasyonu
  late Animation<double> _gavelAnimation;
  AnimationController? _shakeController;
  /// Aynı ceza metni için titremeyi yalnızca seçim değişince tetiklemek.
  String? _lastShookPenaltyKey;
  bool _isSealTapInProgress = false;

  Map<String, int> _cezaBegenileri = <String, int>{};
  Map<String, bool> _userLikedCezalar = <String, bool>{};

  // ─── Ceza listesi (aynı içerik, zenginleştirilmiş emoji ile) ───
  final List<Map<String, String>> readyPenalties = <Map<String, String>>[
    {'name': '🎭 19  Mucizesi', 'description': ' Edip YÜKSEL in Kurandaki 19 rakamı ile ilgili Mucize hakkında yazdığı makaleye  eleştiri yaz'},
    {'name': '🎭 BERAAT', 'description': ' Bu kardeşimiz AFFOLA!'},
    {'name': '🎭 DELİDİR', 'description': 'Delidir ne yapsa yeridir!'},
    {'name': '🎭 Küçük Emrah Kaderi Yaşasın', 'description': 'Küçük Emrah filmindeki gibi zorlu bir kader yaşaması!'},
    {'name': '📖 Kuranı Baştan Sona Okusun', 'description': 'Kuran-ı Kerim\'i baştan sona okuyup anlaması gerekiyor. Sabır ve iman testi bir arada!'},
    {'name': '🗡️ 10 Kahve Ismarla ', 'description': 'Tanımdaığın 10 kişiye cafe de 10 kahve ısmarlamalısın. Faturayı da sakla'},
    {'name': '🤝 100 Kişiye İyilik Etsin', 'description': "Toplam 100 kişiye iyilik yapması ve bunu belgelemek için fotoğraf çekmesi gerekiyor. Sosyal medya influencer'ı gibi!"},
    {'name': '🐕 Yaşlanınca Sokak Köpekleri Gibi Sokakta Ölsün', 'description': 'Sembolik bir ceza. Kişinin yalnızlığını ve çaresizliğini hissetmesi amaçlanmıştır. (Gerçek değil, merak etmeyin!)'},
    {'name': '💍 Evlenmek Nasip Olmasın', 'description': 'Evlilik konusunda zorluklar yaşaması. Bekarlık sultanlıktır diyenler için mükemmel ceza!'},
    {'name': '🏝️ Kendini Devredışı Bıraksın', 'description': 'Kendini toplumdan izole etmesi. Bir nevi sosyal tatil!'},
    {'name': '💪 Sövme', 'description': 'Sembolik olarak ağır bir ceza. Gerçek değilon tane küfür ye!'},
    {'name': '😅 Küçük Emrah Gibi Sürüne', 'description': 'Zorlu bir hayat yaşaması. Emrah hayranları için ilham verici!'},
    {'name': '🏛️ İktidardan Sopa Yiye', 'description': 'Sosyal ve politik zorluklar yaşaması. Demokrasinin acı derslerini bizzat öğrensin!'},
    {'name': '🐱 Sokak Kedisi Besleme', 'description': '30 kediyi besleme sorumluluğu alması. Bir ay  hafta boyunca!'},
    {'name': '🍚 40 Yetimi Doyurma', 'description': '40 yetimi doyurma görevi alması. Hem ceza hem sevap — çok çok verimli!'},
    {'name': '📵 Tüm Sosyal Medya Hesapları Silinsin', 'description': "1 ay boyunca Sosyal medya hesaplarını sildiği için kullanamaycak.Yeni hesapları 1 ay geçince açabilecek. Dijital ölüm!"},
    {'name': '🍞 2 gün oruç tutsun', 'description': 'İslami kurallara uyarak'},
    {'name': '📚 Bir yıl boyunca Her Gün 10 Sayfa Kitap Okusun', 'description': 'Her gün en az 10 sayfa kitap okuma zorunluluğu. Ülkemizin yeni aydın adayı!'},
    {'name': '🌐 1 Ay Boyunca İnternetsiz Yaşasın', 'description': 'Bir ay boyunca internet kullanmaması. Neandertaller de hayatta kaldı, o da kalar!'},
    {'name': '😬 Tüm Günahlarını Sosyal Medyada İtiraf Etsin', 'description': 'Günahlarını sosyal medyada itiraf etmesi. Reality show formatında ruhani arınma!'},
    {'name': '🏃 1 ay boyunca her Gün 5 Km Koşu Yapsın', 'description': 'Her gün 5 kilometre koşu yapması. Marathon sezonu açık!'},
    {'name': '📱 1 Hafta Telefon Kullanmasın', 'description': 'Bir hafta boyunca telefon kullanmaması. 1998 yılına hoş geldiniz!'},
    {'name': '💸 Bir maaşını Hayır Kurumuna Bağışlasın', 'description': 'Bu ayki maaşını  hayır kurumuna bağışlaması. Zengin ruhlu, fakir cebi!'},
    // Hafif Cezalar
    {'name': '👻 Sanal Mesafe', 'description': '1 hafta  boyunca  sosyal medya ve  telefon dahil kimseye görünme. Aynı mahallede en yakın  arkadaşını bile arayıp sorma.'},
    {'name': '🍫 Kumbara Fonu', 'description': 'Kişiye, istediği bir çikolata veya dondurma türünü alacak kadar sembolik bir miktar (en az 10 Dolar) ödeyeceksiniz. Afiyet olsun!'},
    {'name': '🧹 Temizlik Operasyonu', 'description': 'Bulunduğunuz sokakta, yürüyüş yaparken en az 10 çöp toplayıp çöp kutusuna atacaksınız. Selfie ile kanıtlayacaksınız.'},
    {'name': '🧶 Kişisel Gelişim Molası', 'description': 'İki hafta boyunca günde 15 dakika, nasıl yapılır videoları izleyecek veya bir hobi edinmeye çalışacaksınız. Örgü örmek serbest.'},
    {'name': '🎭 Nazik Telafi Görevi', 'description': 'Yanlış anlaşılmaya neden olduğunuz kişiye, samimi bir özür mesajı yazacak ve onu güldürecek bir internet videosu paylaşacaksınız.'},
    {'name': '🏠 Evdeki Kaşif Modu', 'description': '1 hafta sonu boyunca evden sadece acil durumlarda çıkabilirsiniz. Bu süreyi evde unuttuğunuz bir beceriyi geliştirerek geçireceksiniz.'},
    {'name': '🎵 Trafik Canavarılığı İlanı', 'description': 'Trafikte yaptığınız kabalığın kefareti olarak, arabanızın içinde, yüksek sesle 10 dakika klasik müzik dinleyeceksiniz.'},
    {'name': '🎟️ TOKATLA', 'description': 'Yastığını 19 defa tokatla'},
    {'name': '🍬 Manevi Çikolata Tazmini', 'description': 'Kişinin kalbini kırdıysanız, gönlünü almak için bir kutu kaliteli çikolata alacaksınız.'},
    {'name': '🧊 Buzdolabı Hacizi', 'description': 'Buzdolabını 3 gün açmayacaksın'},
    // Orta Şiddetli
    {'name': '📵 Mola Zili', 'description': '48 saatlik bir "dijital detoks" cezası aldınız. Tüm sosyal medya ve anlık mesajlaşma uygulamalarından uzak kalacaksınız.'},
    {'name': '👟 Sigara İçmek Yasak', 'description': 'Bir hafta boyunca, sigara içmeyeceksin.'},
    {'name': '💬 Sohbet Grubu Sürgünü', 'description': '3 gün boyunca en sevdiğiniz WhatsApp veya Discord grubundan atılacaksınız.'},
    {'name': '🍫 Sevdiklerinden Mahrum Kalma Cezası', 'description': 'Bir hafta boyunca en sevdiğiniz atıştırmalıktan uzak duracaksınız. Dürüst olun: cips mi çikolata mı?'},
    // Ağır Cezalar
    {'name': '📺 Sonsuz Dizi Kuyruğu', 'description': 'İzleme listenizdeki tüm dizileri bitirene kadar yeni bir diziye başlayamayacaksınız. Gerçek bir müebbet!'},
    {'name': '🤳 Sosyal Medya İdamı', 'description': 'En komik ve utanç verici selfieniz, bir yakınınızın sosyal medya hesabından 24 saatliğine paylaşılacak.'},
    {'name': '🔋 Pil Bitirme Cezası', 'description': 'Telefonunuzun şarjı %5\'in altına düşene kadar oyun oynamaya veya video izlemeye devam edeceksiniz.'},
    {'name': '🎤 Dikensiz Kazık', 'description': 'Bir parti oyununda konuşma yaparken en az 5 dakika boyunca ayakta sabit bir şekilde duracaksınız.'},
    {'name': '🌶️ Acılı Soslu Cezalandırma', 'description': 'Yemeğinize, dayanabildiğiniz en acı sosu ekleyip hepsini bitireceksiniz. Gözlerinizden yaşlar gelmesi, cezanın bir parçasıdır.'},
    {'name': '🍌 Muz Soyma Performansı', 'description': 'Tek bir muzu, kabuğu hiç parçalanmadan mükemmel şekilde soymaya çalışacaksınız. Başarısız olursanız, muzu kabuğuyla yemek zorunda kalacaksınız.'},
    {'name': '🔧 HAVLA ', 'description': 'hAV hAV DİYE DİYE İNLE !'},
    // ─── Önceki 28 tanem (senin favorilerin) ───
    {'name': '☕ 10 Kişiye Kahve Ismarla', 'description': 'Tanımadığın 10 kişiye kahve ısmarla ve “Günün güzel geçsin” de. Faturayı sakla!'},
    {'name': '❤️ 20 Kişiye İçten İlgi Göster', 'description': '20 farklı kişiye samimi bir iltifat veya “Seni gördüğüme sevindim” mesajı at.'},
    {'name': '📸 Pozitif Selfie Görevi', 'description': 'Herkesle gülümseyerek 15 selfie çek ve “Bugün de güzel bir gün” yazıp paylaş.'},
    {'name': '🤝 5 Kişiye Küçük Bir İyilik Yap', 'description': '5 kişiye (tanıdığın/tanımadığın) minik bir iyilik yap ve fotoğrafını kanıt olarak at.'},
    {'name': '🌸 Çiçek Dağıtma Cezası', 'description': '5 tane papatya/çiçek alıp sokaktaki 5 kişiye “Gülümse, dünya güzel” de.'},
    {'name': '📖 Bir Kitabı Birlikte Okuma', 'description': 'Bir arkadaşınla aynı kitabı aynı anda oku ve her bölüm sonunda yorumlaş.'},
    {'name': '🎤 3 Kişiye Kompliman Şarkısı', 'description': '3 kişiye telefonla arayıp kısa bir kompliman şarkısı söyle (acımasızca eğlenceli!).'},
    {'name': '🍪 Kurabiye İkramı', 'description': 'Evde kurabiye yap, 8 kişiye dağıt ve “Senin için yaptım” de.'},
    {'name': '🧳 Mahalle Gezisi', 'description': 'Mahallende 10 kişiye “Merhaba, nasılsın?” diye sor ve sohbet başlat.'},
    {'name': '📬 Pozitif Mektup', 'description': '3 kişiye el yazısıyla “Seni düşündüm, iyi ki varsın” mektubu yaz.'},
    {'name': '🎲 Oyun Gecesi Düzenle', 'description': 'En az 4 kişiyi çağır, basit bir oyun gecesi düzenle (ceza = ev sahibi olmak).'},
    {'name': '🌳 Bir Fidan Dik', 'description': 'Bir fidan dik (ya da saksıda büyüt) ve “Geleceğimize yeşil kattım” diye paylaş.'},
    {'name': '📣 Teşekkür Turu', 'description': 'Gün içinde 10 kişiye “Bana yaptığın için teşekkürler” de.'},
    {'name': '🍲 3 Kişiye Yemek İkramı', 'description': 'Evde yaptığın yemeğin 3 porsiyonunu komşuya/arkadaşa götür.'},
    {'name': '🕺 Dans Et ve Paylaş', 'description': '1 dakika komik bir dans videosu çek ve “Herkes dans etsin!” diye etiketle.'},
    {'name': '📚 Kitap Değiş-Tokuşu', 'description': '3 kişiye kitabını ver, onlarınkini al ve “Birlikte okuduk” diye paylaş.'},
    {'name': '🌈 Günlük Güzellik Avı', 'description': 'Günde 5 güzel şeyi fotoğrafla ve “Hayat güzel” diye paylaş.'},
    {'name': '🤗 Sarılma Görevi', 'description': 'Güvenli 5 kişiye sarıl ve “Sarılmak bedava” yazısını paylaş.'},
    {'name': '🎨 Ortak Resim Yap', 'description': 'Bir arkadaşınla aynı kâğıda resim çiz ve bitmiş hali paylaş.'},
    {'name': '☀️ Sabah Motivasyon Mesajı', 'description': '10 kişiye sabah “Bugün harika olacak!” mesajı at.'},
    {'name': '🧩 Bulmaca Çözme Partisi', 'description': '3-4 kişiyle online/offline bulmaca çöz ve “Birlikte daha zevkli” de.'},
    {'name': '🎁 Sürpriz Hediye', 'description': '1 kişiye 5 TL’lik küçük bir sürpriz (çikolata, not vs.) hazırla.'},
    {'name': '📻 Radyo Sunucusu Ol', 'description': '1 dakikalık sesli mesajla “Herkese pozitif enerji” yayınla.'},
    {'name': '🌍 Dünya Güzelliği Paylaş', 'description': 'Başka bir şehir/ülkeden bir güzellik fotoğrafı paylaş ve “Dünya ne kadar güzel” yaz.'},
    {'name': '🍓 Meyve Paylaşımı', 'description': 'Bir sepet meyve alıp 6 kişiye dağıt ve “Paylaştıkça çoğalır” de.'},
    {'name': '🪴 Bitki Bakımı Zinciri', 'description': 'Birine bitki ver, o da başkasına versin ve zinciri devam ettirin.'},
    {'name': '😄 Gülümsetme Görevi', 'description': 'Sokakta 10 kişiye sadece gülümse ve tepkilerini not et.'},
    {'name': '❤️ Sosyal Medya Temizliği Yerine: Pozitif Yorum', 'description': '10 kişinin eski postuna güzel bir yorum yaz.'},

    // ─── YENİ 86 TANEM (toplam 114) ───
    {'name': '🌟 15 Kişiye Günaydın Dene', 'description': '15 kişiye sabah “Günaydın, bugün harika şeyler olacak!” mesajı at.'},
    {'name': '🧡 Komşuya Çay Ikramı', 'description': 'Komşularından 4 kişiye çay/kahve ikram et ve sohbet et.'},
    {'name': '📲 Sesli Mesaj Zinciri', 'description': '5 kişiye sesli mesaj atıp “Senin sesini duymak güzel” de.'},
    {'name': '🎉 Doğum Günü Kutlama Turu', 'description': 'Arkadaşlarının doğum günlerini hatırlayıp 3 kişiye sürpriz kutlama yap.'},
    {'name': '🚶‍♂️ Yürüyüş Arkadaşı Bul', 'description': '2 kişiyle yürüyüşe çık ve “Birlikte yürümek ne güzel” diye paylaş.'},
    {'name': '🍎 Sağlıklı Atıştırmalık Paylaş', 'description': 'Evde yaptığın meyve tabağını 6 kişiye dağıt.'},
    {'name': '🖼️ Anı Fotoğrafı Çek', 'description': '5 farklı grupla hatıra fotoğrafı çekip “Birlikte güzeliz” yaz.'},
    {'name': '📝 Teşekkür Defteri', 'description': '3 kişiye el yazısıyla teşekkür notu yaz ve ver.'},
    {'name': '🎈 Balonla Sürpriz', 'description': '5 balon alıp sokaktaki çocuklara dağıt ve gülümset.'},
    {'name': '🧘‍♀️ Grup Nefes Egzersizi', 'description': '3-4 kişiyle 2 dakikalık ortak nefes alıp “Huzur paylaştık” de.'},
    {'name': '📖 Hikaye Anlatma Çemberi', 'description': '4 kişiyle kısa hikaye anlatma oyunu oyna.'},
    {'name': '🌼 Çiçek Sulama Görevi', 'description': 'Parktaki veya sokağındaki çiçekleri sulayıp “Doğaya teşekkür” de.'},
    {'name': '🍫 Çikolata Paylaşma Zinciri', 'description': '1 kutu çikolata alıp 8 kişiye dağıt ve zinciri devam ettir.'},
    {'name': '🎵 Şarkı Söyleme Challenge', 'description': '3 arkadaşınla aynı şarkıyı aynı anda sesli mesajla söyle.'},
    {'name': '🛍️ Alışverişte Yardım', 'description': 'Market sırasındaki 2 kişiye “Ben yardım edeyim” de.'},
    {'name': '📧 Eski Arkadaşa Özlem Mesajı', 'description': 'Uzun zamandır görüşmediğin 4 kişiye “Seni özledim” mesajı at.'},
    {'name': '🌞 Güneşli Gün Paylaşımı', 'description': 'Güneşli bir fotoğraf çekip 10 kişiye “Güneş gibi gülümse” de.'},
    {'name': '🧩 Ortak Puzzle Tamamlama', 'description': 'Online 3 kişiyle aynı puzzle’ı tamamla ve sonucu paylaş.'},
    {'name': '🍵 Çay Saati Düzenle', 'description': 'Evde mini çay saati kur, 5 kişiyi davet et.'},
    {'name': '📬 Kartpostal Gönder', 'description': '3 kişiye el yapımı kartpostal gönder.'},
    {'name': '🤳 Grup Selfie Maratonu', 'description': '10 farklı insanla selfie çek ve “Birlikteyiz” yaz.'},
    {'name': '🌱 Tohum Dağıt', 'description': '10 kişiye çiçek tohumu ver ve “Birlikte büyütelim” de.'},
    {'name': '🎭 Komik Taklit Görevi', 'description': '3 kişiye komik bir taklit videosu gönder ve güldür.'},
    {'name': '🧴 Hijyen İkramı', 'description': 'El dezenfektanı alıp 6 kişiye “Sağlığın için” de.'},
    {'name': '📚 Kitap Okuma Kulübü', 'description': '2 arkadaşınla mini okuma kulübü kur.'},
    {'name': '🌈 Gökkuşağı Fotoğrafı', 'description': 'Gökkuşağı renklerinde 7 fotoğraf çekip “Hayat rengarenk” yaz.'},
    {'name': '🍉 Yaz Meyvesi Paylaş', 'description': 'Karpuz/kavun kesip 5 komşuya dağıt.'},
    {'name': '🪑 Oturma Yeri Bırak', 'description': 'Toplu taşımada 3 kişiye yer ver ve gülümse.'},
    {'name': '🎙️ Podcast Dinlet', 'description': 'Sevdiğin 1 dakikalık podcast’i 4 kişiye sesli mesajla gönder.'},
    {'name': '🧦 Çorap İkramı', 'description': 'Eğlenceli desenli 5 çift çorap alıp dağıt.'},
    {'name': '📸 Pozitif Yorum Bombası', 'description': '10 kişinin son 3 postuna güzel yorum yap.'},
    {'name': '🌍 Bir Ülke Hakkında Güzellik Paylaş', 'description': 'Bir ülkenin güzel bir yönünü 5 kişiye anlat.'},
    {'name': '🍪 Kurabiye Postası', 'description': 'Kurabiye yapıp kargoyla 3 arkadaşa gönder.'},
    {'name': '🕯️ Mum Yakma Töreni', 'description': '3 kişiyle online mum yakıp “Işık paylaştık” de.'},
    {'name': '📖 Şiir Paylaşımı', 'description': 'Kısa bir şiiri 6 kişiye sesli mesajla oku.'},
    {'name': '🌟 Yıldız Sayma', 'description': 'Gece 4 kişiyle yıldız sayma oyunu oyna.'},
    {'name': '🧴 El Kremi Hediyesi', 'description': 'Küçük el kremi alıp 5 kişiye “Ellerin yumuşasın” de.'},
    {'name': '🎨 Boyama Sayfası Paylaş', 'description': 'Boyama sayfası çizip 4 kişiye gönder.'},
    {'name': '🍵 Bitki Çayı İkramı', 'description': 'Evde bitki çayı demleyip 6 kişiye sun.'},
    {'name': '📬 Teşekkür Kartı Zinciri', 'description': '3 kişiye teşekkür kartı gönder, onlar da devam etsin.'},
    {'name': '🧘‍♂️ Grup Meditasyon', 'description': '3-4 kişiyle 3 dakikalık ortak meditasyon.'},
    {'name': '🌺 Çiçekli Not', 'description': '5 kişiye çiçekli el yazısı not bırak.'},
    {'name': '🎵 Playlist Paylaş', 'description': 'Pozitif bir playlist yapıp 8 kişiye gönder.'},
    {'name': '🛒 Market Yardım Görevi', 'description': 'Market alışverişi yapan 2 kişiye poşet taşıma yardımı yap.'},
    {'name': '📸 Anı Albümü', 'description': 'Eski fotoğraflardan 5 tanesini arkadaşlara hatırlat.'},
    {'name': '🍄 Mantar Avı (sembolik)', 'description': 'Doğada mantar fotoğrafı çekip “Doğayla bağ kurduk” paylaş.'},
    {'name': '🧁 Cupcake Dağıt', 'description': 'Cupcake yapıp 7 kişiye dağıt.'},
    {'name': '📲 Sesli Günlük', 'description': '1 dakikalık “Bugün ne için mutluyum” sesli mesajı 5 kişiye at.'},
    {'name': '🌳 Ağaç Sarılma', 'description': 'Parkta bir ağaca sarıl ve fotoğrafını “Doğaya sevgim” diye paylaş.'},
    {'name': '🎟️ Sinema Bilet Hediyesi', 'description': '1 arkadaşına sinema bileti sürprizi yap (sembolik).'},
    {'name': '🧦 Çorap Eşleştirme Oyunu', 'description': '4 kişiyle karışık çorap eşleştirme oyunu oyna.'},
    {'name': '📖 Masal Okuma', 'description': 'Çocuklara veya arkadaşlara kısa masal oku.'},
    {'name': '🌟 Yıldız Tozu Paylaş', 'description': 'Simli yıldız çıkartma alıp 10 kişiye dağıt.'},
    {'name': '🍯 Bal İkramı', 'description': 'Küçük bal kavanozu alıp 5 kişiye “Tatlı günler” de.'},
    {'name': '🪄 Sihirli Kelime Görevi', 'description': 'Herkese “Lütfen” ve “Teşekkürler”i 20 kez söyle.'},
    {'name': '📸 Ayna Selfiesi', 'description': 'Aynada kendine gülümseyip 5 kişiye “Sen de gülümse” gönder.'},
    {'name': '🌈 Renkli Gün', 'description': 'Her renkte 1 fotoğraf çekip “Hayatım rengarenk” paylaş.'},
    {'name': '🍫 Sıcak Çikolata Paylaş', 'description': 'Kışın sıcak çikolata yapıp 4 komşuya götür.'},
    {'name': '🧩 Emoji Hikayesi', 'description': 'Emoji’lerle 3 kişiye hikaye anlat.'},
    {'name': '🌍 Selamlaşma Turu', 'description': 'Sokakta 15 kişiye sadece “Merhaba” de ve gülümse.'},
    {'name': '📬 Gizli Hayran Notu', 'description': '3 kişiye anonim “Seni takdir ediyorum” notu bırak.'},
    {'name': '🎨 Parmak Boyama', 'description': '4 kişiyle parmak boyama etkinliği yap.'},
    {'name': '🍵 Çay Molası', 'description': 'İş yerinde 3 kişiye çay molası ısmarla.'},
    {'name': '🕺 Dans Challenge', 'description': '1 dans videosu çekip 6 kişiyi etiketle.'},
    {'name': '📖 Günlük Şükran', 'description': '5 kişiye “Bugün şükrettiğin 3 şey” sor.'},
    {'name': '🌼 Çiçekli Kahvaltı', 'description': 'Kahvaltı sofrasına çiçek koyup fotoğraf paylaş.'},
    {'name': '🤳 Video Selamlaşma', 'description': '5 kişiye kısa video selam gönder.'},
    {'name': '🧴 El Losyonu Hediyesi', 'description': 'Küçük losyon alıp 6 kişiye “Ellerin yumuşasın” de.'},
    {'name': '📚 Mini Kütüphane', 'description': '3 kitap verip “Okuduktan sonra başkasına ver” de.'},
    {'name': '🌞 Sabah Sporu Daveti', 'description': '2 arkadaşı sabah yürüyüşüne davet et.'},
    {'name': '🍪 Kurabiye Postası 2', 'description': 'Kurabiye yapıp kargoyla 4 kişiye gönder.'},
    {'name': '🎤 Karaoke Tekli', 'description': '1 şarkı karaokesi yapıp 3 kişiye sesli at.'},
    {'name': '🪴 Saksı Hediyesi', 'description': 'Küçük saksı çiçeği alıp 5 kişiye ver.'},
    {'name': '📸 Pozitif Hikaye Paylaş', 'description': 'Güzel bir anını 8 kişiye anlat.'},
    {'name': '🌍 Barış Selamı', 'description': '10 kişiye “Dünya barışa” mesajı at.'},
    {'name': '🧡 Kalp Notu', 'description': '10 kişiye kalp şeklinde not bırak.'},
    {'name': '🍉 Yaz Pikniği', 'description': 'Mini piknik düzenleyip 4 kişiyi davet et.'},
    {'name': '📖 Şiir Duşu', 'description': 'Kısa şiirleri 5 kişiye sesli oku.'},
    {'name': '🌟 İyi Geceler Turu', 'description': '10 kişiye “İyi geceler, yarın harika olsun” mesajı at.'},
    {'name': '🧩 Birlikte Yapboz', 'description': 'Online 4 kişiyle yapboz tamamla.'},
    {'name': '🌸 Gülümse ve Geç', 'description': 'Sokakta 20 kişiye sadece gülümse.'},
    {'name': '❤️ Pozitif Enerji Bombası', 'description': '15 kişiye “Pozitif enerji gönderiyorum” mesajı at.'},
  ];

  final Map<String, Map<String, dynamic>> _staticMemberPenalties = <String, Map<String, dynamic>>{
    'whodoom': {
      'avatar': 'W',
      'hashtag': '#whoBOOM',
      'penalties': <String>[
        '🎭 Küçük emrah kaderi yaşasın',
        '📖 Kuranı baştan sona okusun',
        '🗡️ Ya ölüm ya istiklal desin',
      ],
    },
    'nasrullah_keskin': {
      'avatar': 'N',
      'hashtag': '#nasrullahBOOM',
      'penalties': <String>[
        '🤝 100 kişiye iyilik etsin',
        '🐕 Yaşlanınca sokak köpekleri gibi sokakta ölsün',
        '💍 Evlenmek nasip olmasın',
        '🏝️ Kendini devredışı bıraksın',
      ],
    },
    'cheguevera_del': {
      'avatar': 'C',
      'hashtag': '#chegueveraBOOM',
      'penalties': <String>[
        '💪 Öldürülesiye dövme',
        '😅 Küçük Emrah gibi sürüne',
        '🏛️ İktidardan sopa yiye',
        '🐱 30 kedi besleme',
        '🍚 40 yetimi doyurma',
      ],
    },
  };

  final Map<String, Map<String, dynamic>> _customMemberPenalties = <String, Map<String, dynamic>>{};

  Map<String, Map<String, dynamic>> get memberPenalties {
    final Map<String, Map<String, dynamic>> combined = <String, Map<String, dynamic>>{};
    combined.addAll(_staticMemberPenalties);
    for (final entry in _customMemberPenalties.entries) {
      if (combined.containsKey(entry.key)) {
        final existingPenalties = combined[entry.key]!['penalties'] as List<String>;
        final newPenalties = entry.value['penalties'] as List<String>;
        combined[entry.key]!['penalties'] = <String>[...existingPenalties, ...newPenalties];
      } else {
        combined[entry.key] = entry.value;
      }
    }
    return combined;
  }

  void _applyDefaultHazirCezaSelection() {
    final int idx = readyPenalties.indexWhere(
      (Map<String, String> penalty) => penalty['name'] == _defaultHazirCezaName,
    );
    if (idx == -1) {
      return;
    }
    selectedReadyIndex = idx;
    expandedReadyIndex = idx;
    selectedPenaltyText = readyPenalties[idx]['name'];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _applyDefaultHazirCezaSelection();

    _coffinAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _gavelAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _gavelAnimation = Tween<double>(begin: 0, end: 0.12).animate(
      CurvedAnimation(parent: _gavelAnimController!, curve: Curves.easeInOut),
    );

    _ensureShakeController();

    _customTitleCtrl.addListener(_onCustomPenaltyChanged);
    _customDescriptionCtrl.addListener(_onCustomPenaltyChanged);
    _loadCezaBegenileri();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGorevHukumOnizleme());
  }

  @override
  void didUpdateWidget(covariant CezalarCezaUnifiedPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.davaId != widget.davaId ||
        oldWidget.dava.mevkii != widget.dava.mevkii ||
        oldWidget.dava.adi != widget.dava.adi) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadGorevHukumOnizleme());
    }
  }

  Future<void> _loadCezaBegenileri() async {
    try {
      final begeniler = await HiveDatabaseService.getAllCezaBegenileri();
      final userEmail = widget.userEmail ?? '';
      final userLiked = <String, bool>{};
      for (final cezaName in begeniler.keys) {
        final isLiked = await HiveDatabaseService.isCezaLikedByUser(cezaName, userEmail);
        userLiked[cezaName] = isLiked;
      }
      setState(() {
        _cezaBegenileri = begeniler;
        _userLikedCezalar = userLiked;
      });
    } catch (e) {
      debugPrint('❌ Ceza beğenileri yüklenirken hata: $e');
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _coffinAnimationController?.dispose();
    _gavelAnimController?.dispose();
    _shakeController?.dispose();
    _customTitleCtrl.dispose();
    _customDescriptionCtrl.dispose();
    _customTitleFocus.dispose();
    _customDescriptionFocus.dispose();
    super.dispose();
  }

  void _onCustomPenaltyChanged() {
    final titleLength = _customTitleCtrl.text.trim().length;
    final descriptionLength = _customDescriptionCtrl.text.trim().length;
    setState(() {
      _isCustomPenaltyValid =
          titleLength >= 3 && titleLength <= 100 && descriptionLength >= 15 && descriptionLength <= 400;
    });
  }

  void _selectReady(int index) {
    final penalty = readyPenalties[index];
    final cezaName = penalty['name']!;
    setState(() {
      expandedReadyIndex = (expandedReadyIndex == index) ? null : index;
      selectedReadyIndex = index;
      selectedMemberPenaltyIndex = null;
      selectedMember = null;
      selectedPenaltyText = cezaName;
      expandedMember = null;
      expandedMemberPenaltyIndex = null;
      _isCustomPenaltySelected = false;
      _isMahkemeKarariVisible = false;
    });
  }

  void _navigateReadyPenalty(int delta) {
    if (readyPenalties.isEmpty) return;
    final int currentIndex = selectedReadyIndex ?? (delta < 0 ? readyPenalties.length - 1 : 0);
    final int nextIndex = (currentIndex + delta + readyPenalties.length) % readyPenalties.length;
    final Map<String, String> penalty = readyPenalties[nextIndex];
    final String cezaName = penalty['name']!;

    setState(() {
      activeCategory = 'Hazır Ceza';
      selectedReadyIndex = nextIndex;
      expandedReadyIndex = nextIndex;
      selectedPenaltyText = cezaName;
      selectedMemberPenaltyIndex = null;
      selectedMember = null;
      expandedMember = null;
      expandedMemberPenaltyIndex = null;
      _isCustomPenaltySelected = false;
      _isMahkemeKarariVisible = false;
    });
  }

  Map<String, String>? get _selectedReadyPenalty {
    final int? index = selectedReadyIndex;
    if (index == null || index < 0 || index >= readyPenalties.length) {
      return null;
    }
    return readyPenalties[index];
  }

  int? get _selectedReadyPenaltyCode {
    final int? index = selectedReadyIndex;
    if (index == null) return null;
    return index + 1;
  }

  IconData _resolveSelectedPenaltyIcon() {
    final String? title = _selectedReadyPenalty?['name'] ?? selectedPenaltyText;
    if (title == null || title.isEmpty) return MdiIcons.coffin;

    if (title.contains('📖')) return MdiIcons.bookOpenVariant;
    if (title.contains('🗡️')) return MdiIcons.swordCross;
    if (title.contains('🤝')) return MdiIcons.handshake;
    if (title.contains('🐕') || title.contains('🐱')) return MdiIcons.paw;
    if (title.contains('💍')) return MdiIcons.ring;
    if (title.contains('🏝️')) return MdiIcons.island;
    if (title.contains('💪')) return MdiIcons.dumbbell;
    if (title.contains('🏛️')) return MdiIcons.bank;
    if (title.contains('🍚') || title.contains('🍞')) return MdiIcons.food;
    if (title.contains('📵') || title.contains('📱')) return MdiIcons.cellphoneOff;
    if (title.contains('📚')) return MdiIcons.bookEducation;
    if (title.contains('🌐')) return MdiIcons.webOff;
    if (title.contains('🏃')) return MdiIcons.runFast;
    if (title.contains('💸')) return MdiIcons.cashFast;
    if (title.contains('🎭')) return MdiIcons.dramaMasks;
    return MdiIcons.coffin;
  }

  String? _resolveSelectedPenaltyEmoji() {
    final String? title = _selectedReadyPenalty?['name'] ?? selectedPenaltyText;
    if (title == null || title.isEmpty) return null;
    final List<String> parts = title.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;
    final String first = parts.first;
    return first.runes.length <= 4 ? first : null;
  }

  void _selectMemberPenalty(String member, int idx) {
    final penaltyText = memberPenalties[member]!['penalties'][idx] as String;
    setState(() {
      if (expandedMember == member && expandedMemberPenaltyIndex == idx) {
        expandedMember = null;
        expandedMemberPenaltyIndex = null;
      } else {
        expandedMember = member;
        expandedMemberPenaltyIndex = idx;
      }
      selectedMember = member;
      selectedMemberPenaltyIndex = idx;
      selectedReadyIndex = null;
      selectedPenaltyText = penaltyText;
      expandedReadyIndex = null;
      _isMahkemeKarariVisible = false;
    });
  }

  void _saveCustomPenalty() {
    final title = _customTitleCtrl.text.trim();
    if (_isCustomPenaltyValid) {
      final userEmail = widget.userEmail ?? 'guest';
      final userName = userEmail.split('@').first;
      setState(() {
        selectedPenaltyText = title;
        selectedReadyIndex = null;
        selectedMemberPenaltyIndex = null;
        selectedMember = null;
        _isCustomPenaltySelected = true;
        if (_customMemberPenalties.containsKey(userEmail)) {
          final existingPenalties = _customMemberPenalties[userEmail]!['penalties'] as List<String>;
          if (!existingPenalties.contains(title)) {
            existingPenalties.add(title);
          }
        } else {
          final avatar = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
          _customMemberPenalties[userEmail] = {
            'avatar': avatar,
            'hashtag': '#${userName}BOOM',
            'penalties': <String>[title],
          };
        }
        _isMahkemeKarariVisible = false;
      });
      _showMahkemeSnackBar(
        context,
        '⚖️ Cezanız mahkeme arşivine işlendi ve "Üyelerden" bölümüne nakledildi!',
        Colors.green.shade700,
      );
    }
  }

  void _updateCustomPenalty() {
    final title = _customTitleCtrl.text.trim();
    final oldTitle = selectedPenaltyText;
    if (_isCustomPenaltyValid && _isCustomPenaltySelected && !_isPenaltyApplied) {
      final userEmail = widget.userEmail ?? 'guest';
      setState(() {
        selectedPenaltyText = title;
        if (_customMemberPenalties.containsKey(userEmail)) {
          final penalties = _customMemberPenalties[userEmail]!['penalties'] as List<String>;
          final index = penalties.indexOf(oldTitle ?? '');
          if (index != -1) penalties[index] = title;
        }
      });
      _showMahkemeSnackBar(
        context,
        '📜 Ceza metni yeniden kaleme alındı. Arşiv güncellendi!',
        Colors.blue.shade700,
      );
    }
  }

  Future<void> _toggleCezaBegeni(String cezaName) async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      _showMahkemeSnackBar(context, '🔑 Beğeni için giriş yapmanız gerekiyor!', Colors.orange.shade700);
      return;
    }
    try {
      await HiveDatabaseService.toggleCezaBegeni(cezaName, widget.userEmail!);
      await _loadCezaBegenileri();
    } catch (e) {
      _showMahkemeSnackBar(context, '❌ Beğeni güncellenirken hata oluştu.', _MahkemeRenkler.kirmizi);
    }
  }

  /// Mahkeme temalı SnackBar
  void _showMahkemeSnackBar(BuildContext ctx, String mesaj, Color renk) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.gavel, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mesaj,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: renk,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// Hive gruplanmış hüküm haritasından görev (mevkii) metnini çözer.
  String? _resolveHukumTextFromMaps(String normalizedRole, Map<String, String> rolHukumleri) {
    String? hukumText = rolHukumleri[normalizedRole];

    if (hukumText == null || hukumText.trim().isEmpty) {
      final String withoutKarari = normalizedRole.replaceAll(' Kararı', '').trim();
      if (withoutKarari.isNotEmpty && withoutKarari != normalizedRole) {
        hukumText = rolHukumleri[withoutKarari];
      }
    }

    if (hukumText == null || hukumText.trim().isEmpty) {
      final String searchTerm = normalizedRole.toLowerCase();
      for (final MapEntry<String, String> entry in rolHukumleri.entries) {
        if (entry.key.toLowerCase().contains(searchTerm) || searchTerm.contains(entry.key.toLowerCase())) {
          hukumText = entry.value;
          break;
        }
      }
    }

    final String? t = hukumText?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  Future<void> _loadGorevHukumOnizleme() async {
    final String? did = widget.davaId?.trim();
    final String role = widget.dava.mevkii.trim();
    if (did == null || did.isEmpty || role.isEmpty) {
      if (mounted) {
        setState(() {
          _gorevHukumVar = false;
          _gorevHukumOnizleme = null;
        });
      }
      return;
    }
    try {
      final Map<String, Map<String, dynamic>> grouped =
          await HiveDatabaseService.getHukumlerByDavaIdGrouped(did, davaAdi: widget.dava.adi);
      final Map<String, String> rolHukumleri = <String, String>{};
      for (final MapEntry<String, Map<String, dynamic>> e in grouped.entries) {
        final String text = (e.value['hukumText'] as String?)?.trim() ?? '';
        if (text.isNotEmpty) {
          rolHukumleri[e.key] = text;
        }
      }
      final String? full = _resolveHukumTextFromMaps(role, rolHukumleri);
      if (!mounted) {
        return;
      }
      setState(() {
        _gorevHukumVar = full != null && full.isNotEmpty;
        if (full == null || full.isEmpty) {
          _gorevHukumOnizleme = null;
        } else if (full.length > 360) {
          _gorevHukumOnizleme = '${full.substring(0, 360)}…';
        } else {
          _gorevHukumOnizleme = full;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _gorevHukumVar = false;
          _gorevHukumOnizleme = null;
        });
      }
    }
  }

  /// [ModernHukumCard._buildRoleDialogButton] ile aynı ikon; metin kadar kompakt satır sonu.
  Widget _buildKunyeSekizHukumTrailing() {
    final Color iconColor = _gorevHukumVar ? Colors.green.shade700 : Colors.brown;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onSekizHukumTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(MdiIcons.fileCheckOutline, size: 22, color: iconColor),
              const SizedBox(width: 4),
              Text(
                '8-HÜKÜM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.green.shade800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKunyeGorevHukumSatir() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _kunyedeGorevHukumAlaniAcik = !_kunyedeGorevHukumAlaniAcik),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Row(
                        children: <Widget>[
                          AnimatedRotation(
                            turns: _kunyedeGorevHukumAlaniAcik ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            child: Icon(Icons.expand_more, size: 20, color: Colors.grey.shade700),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Görevinize ait hüküm',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildKunyeSekizHukumTrailing(),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _kunyedeGorevHukumAlaniAcik
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Material(
                    color: const Color(0xFFF7FAF8),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SelectableText(
                        _gorevHukumOnizleme ??
                            (widget.davaId == null || widget.davaId!.trim().isEmpty
                                ? 'Bu dava için hüküm kaydı yüklemek üzere dava kimliği gerekir. Yargıla ekranındaki görev rozetinden devam edin.'
                                : 'Bu görev için henüz kayıtlı hüküm metni bulunamadı veya yükleniyor…'),
                        style: TextStyle(fontSize: 13, height: 1.45, color: Colors.grey.shade900),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _onSekizHukumTap() async {
    final String? did = widget.davaId?.trim();
    if (did == null || did.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hüküm yazmak için Yargıla sayfasında "Göreviniz" rozetine dokunun.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final String normalizedRole = widget.dava.mevkii.trim();
    if (normalizedRole.isEmpty) {
      if (!mounted) return;
      _showMahkemeSnackBar(context, 'Görev bilgisi bulunamadı.', Colors.orange.shade700);
      return;
    }

    try {
      final Map<String, Map<String, dynamic>> grouped =
          await HiveDatabaseService.getHukumlerByDavaIdGrouped(did, davaAdi: widget.dava.adi);

      final Map<String, String> rolHukumleri = <String, String>{};
      final Map<String, String> rolUserEmails = <String, String>{};
      final Map<String, String> rolCreatedAts = <String, String>{};

      for (final MapEntry<String, Map<String, dynamic>> e in grouped.entries) {
        final Map<String, dynamic> m = e.value;
        final String text = (m['hukumText'] as String?)?.trim() ?? '';
        if (text.isEmpty) continue;
        rolHukumleri[e.key] = text;
        rolUserEmails[e.key] = (m['userEmail'] as String?)?.trim() ?? '';
        rolCreatedAts[e.key] = (m['createdAt'] as String?)?.trim() ?? '';
      }

      if (!mounted) return;
      await _showHukumReadOnlyDialog(
        context,
        normalizedRole: normalizedRole,
        rolHukumleri: rolHukumleri,
        rolUserEmails: rolUserEmails,
        rolCreatedAts: rolCreatedAts,
      );
      if (mounted) {
        await _loadGorevHukumOnizleme();
      }
    } catch (e) {
      debugPrint('❌ Hükümler yüklenirken hata: $e');
      if (mounted) {
        _showMahkemeSnackBar(context, 'Hükümler yüklenirken hata oluştu.', _MahkemeRenkler.kirmizi);
      }
    }
  }

  /// [actigim_davalar_page] / rol kartı ile aynı mantık: normalize anahtar, alternatif ve fuzzy eşleşme.
  Future<void> _showHukumReadOnlyDialog(
    BuildContext dialogContext, {
    required String normalizedRole,
    required Map<String, String> rolHukumleri,
    required Map<String, String> rolUserEmails,
    required Map<String, String> rolCreatedAts,
  }) async {
    final String? hukumText = _resolveHukumTextFromMaps(normalizedRole, rolHukumleri);

    if (hukumText == null || hukumText.trim().isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text('Hüküm bulunamadı: $normalizedRole'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final String finalHukumText = hukumText;

    String actualKey = normalizedRole;
    if (!rolUserEmails.containsKey(normalizedRole)) {
      final String withoutKarari = normalizedRole.replaceAll(' Kararı', '').trim();
      if (rolUserEmails.containsKey(withoutKarari)) {
        actualKey = withoutKarari;
      } else {
        for (final MapEntry<String, String> entry in rolHukumleri.entries) {
          if (entry.value == finalHukumText) {
            actualKey = entry.key;
            break;
          }
        }
      }
    }

    final String userEmail = rolUserEmails[actualKey] ?? '';
    final String createdAt = rolCreatedAts[actualKey] ?? '';
    String displayName = 'Bilinmeyen Yargıç';
    if (userEmail.isNotEmpty) {
      final user = HiveDatabaseService.getRegistrationByEmail(userEmail);
      displayName = user?.judgeName ?? userEmail.split('@').first;
    }

    String formattedDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final DateTime? date = DateTime.tryParse(createdAt);
        if (date != null) {
          formattedDate =
              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        }
      } catch (_) {
        formattedDate = createdAt;
      }
    }

    return showDialog<void>(
      context: dialogContext,
      builder: (BuildContext ctx) {
        final double screenHeight = MediaQuery.of(ctx).size.height;
        final double maxHeight = screenHeight * 0.8;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
              maxWidth: MediaQuery.of(ctx).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: <Color>[Colors.green.shade50, Colors.blue.shade50],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Icon(MdiIcons.fileCheck, color: Colors.green.shade700, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    normalizedRole,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (displayName.isNotEmpty || formattedDate.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 4),
                                    Text(
                                      displayName.isNotEmpty && formattedDate.isNotEmpty
                                          ? '$displayName • $formattedDate'
                                          : displayName.isNotEmpty
                                              ? displayName
                                              : formattedDate,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        finalHukumText,
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applyPenalty() {
    if (selectedPenaltyText == null) {
      _showMahkemeSnackBar(context, '⚖️ Sayın yargıç, lütfen önce bir ceza seçiniz!', _MahkemeRenkler.kirmizi);
      return;
    }

    // Çekiç animasyonu
    _gavelAnimController?.forward(from: 0).then((_) => _gavelAnimController?.reverse());

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _MahkemeRenkler.krem,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _MahkemeRenkler.altin, width: 2),
            boxShadow: [
              BoxShadow(
                color: _MahkemeRenkler.koyu.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık şeridi (koyu mor)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: _MahkemeRenkler.koyu,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    RotationTransition(
                      turns: _gavelAnimation,
                      child: const Text('🔨', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'MAHKEMENİN KARARI',
                        style: TextStyle(
                          color: _MahkemeRenkler.altin,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // İçerik
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      '"Mahkeme-i Kübra"nın tarafsız kararı:',
                      style: TextStyle(
                        fontSize: 12,
                        color: _MahkemeRenkler.gri,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _MahkemeRenkler.kemik,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _MahkemeRenkler.altin.withOpacity(0.5)),
                      ),
                      child: Text(
                        '"$selectedPenaltyText"',
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _MahkemeRenkler.ortaKahve,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '...cezasının uygulanmasına oy birliğiyle karar verilmiştir.\nBu karar kesindir, temyize gidilmez! 🔨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: _MahkemeRenkler.gri,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Butonlar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _MahkemeRenkler.gri,
                          side: const BorderSide(color: _MahkemeRenkler.gri),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('İtiraz Et'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          if (widget.davaId != null && widget.davaId!.isNotEmpty &&
                              widget.userEmail != null && widget.userEmail!.isNotEmpty &&
                              selectedPenaltyText != null) {
                            try {
                              final davaProvider = Provider.of<DavaProvider>(context, listen: false);
                              await davaProvider.updateCezaForDava(
                                davaId: widget.davaId!,
                                userEmail: widget.userEmail!,
                                cezaText: selectedPenaltyText!,
                              );
                            } catch (e) {
                              debugPrint('❌ Ceza kaydedilirken hata: $e');
                            }
                          }
                          if (!context.mounted) {
                            return;
                          }
                          setState(() => _isPenaltyApplied = true);
                          _showMahkemeSnackBar(
                            context,
                            '🔨 KARAR TESCIL EDİLDİ! Ceza mahkeme arşivine işlendi.',
                            _MahkemeRenkler.kirmizi,
                          );
                          widget.onPenaltyApplied?.call();
                          if (widget.onPenaltyApplied == null) {
                            Navigator.of(context).pop(true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _MahkemeRenkler.kirmizi,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 4,
                        ),
                        child: const Text(
                          '⚖️ Onayla!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedMiddlePane) {
      return _buildMainPanel(scrollController: null);
    }
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (BuildContext context, ScrollController scrollController) {
        return _buildMainPanel(scrollController: scrollController);
      },
    );
  }

  Widget _buildMainPanel({ScrollController? scrollController}) {
    return Container(
      decoration: BoxDecoration(
        color: _MahkemeRenkler.krem,
        borderRadius: widget.embeddedMiddlePane
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: <Widget>[
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildDavaSummaryCard(),
                _buildCoffinWhoBoomRow(),
                _buildSelectedPenaltyDetailActionCard(),
                _buildMahkemeKarariPreviewCard(),
                if (widget.showSheetCloseHeader) _buildHeader(),
              ],
            ),
          ),
          const Spacer(),
          _buildSimpleInfoFooter(),
          _buildSocialCountersRow(),
        ],
      ),
    );
  }

  /// [ModernHukumCard._buildDavaInfo] ile aynı künye davranışı (profil / beğeni satırı yok).
  Widget _buildDavaSummaryCard() {
    final CezalarUnifiedDava d = widget.dava;
    final Color accentGreen = Colors.green.shade700;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCE7E1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _cezaKunyeExpanded = !_cezaKunyeExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '|| Dava Künyesi ||',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: Color(0xFF1B2A23),
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _cezaKunyeExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: Icon(Icons.expand_more, color: Colors.grey.shade600, size: 26),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstCurve: Curves.easeOutCubic,
                  secondCurve: Curves.easeInCubic,
                  sizeCurve: Curves.easeInOutCubic,
                  duration: const Duration(milliseconds: 280),
                  crossFadeState:
                      _cezaKunyeExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _buildCezaKunyeInfoRow('Göreviniz', d.mevkii, MdiIcons.briefcaseOutline, accentGreen),
                        const Divider(height: 20),
                        _buildCezaKunyeInfoRow('Dava Adı', d.adi, MdiIcons.gavel, accentGreen),
                        const Divider(height: 20),
                        _buildCezaKunyeInfoRow('Davacı', d.davaci, MdiIcons.account, accentGreen),
                        const Divider(height: 20),
                        _buildCezaKunyeInfoRow('Davalı', d.davali, MdiIcons.accountOutline, accentGreen),
                        const Divider(height: 20),
                        _buildCezaKunyeCountdownSection(),
                      ],
                    ),
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
                _buildKunyeGorevHukumSatir(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCezaKunyeDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  Widget _buildCezaKunyeInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '—' : value,
                softWrap: true,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCezaKunyeCountdownSection() {
    final DateTime? openedAt = widget.davaOpenedAt;
    final String openedAtText =
        openedAt != null ? _formatCezaKunyeDateTime(openedAt) : 'Açılış tarihi bulunamadı';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(MdiIcons.timerAlertOutline, size: 20, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Dava Açılış Tarihi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    openedAtText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  if (openedAt == null && widget.dava.kalanSure.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      widget.dava.kalanSure,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (openedAt != null)
              CountdownTimerWidget(
                startTime: openedAt,
                totalDuration: const Duration(hours: 168),
                showHourglass: true,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCezaTitleCodeRow() {
    final Map<String, String>? selectedReadyPenalty = _selectedReadyPenalty;
    final int? selectedCode = _selectedReadyPenaltyCode;
    final String? selectedTitle = selectedReadyPenalty?['name'] ?? selectedPenaltyText;
    final String? selectedDescription = selectedReadyPenalty?['description'];
    final bool hasSelection = selectedTitle != null && selectedTitle.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasSelection ? _MahkemeRenkler.yesil.withValues(alpha: 0.35) : Colors.grey.shade300,
            width: 1.2,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Seçtiğin Ceza',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _MahkemeRenkler.ortaKahve,
                      letterSpacing: .2,
                    ),
                  ),
                ),
                if (selectedCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _MahkemeRenkler.yesil.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'CezaNo: $selectedCode',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: _MahkemeRenkler.koyu,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasSelection ? selectedTitle! : '— henüz ceza seçilmedi —',
              softWrap: true,
              style: TextStyle(
                fontSize: hasSelection ? 17 : 13,
                fontWeight: hasSelection ? FontWeight.w800 : FontWeight.w500,
                color: hasSelection ? _MahkemeRenkler.koyu : Colors.grey.shade600,
                height: 1.32,
              ),
            ),
            if (selectedDescription != null && selectedDescription.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                selectedDescription,
                softWrap: true,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoffinWhoBoomRow() {
    final IconData selectedIcon = _resolveSelectedPenaltyIcon();
    final String? selectedEmoji = _resolveSelectedPenaltyEmoji();
    final int? selectedCode = _selectedReadyPenaltyCode;
    final String selectedDisplayName = _selectedReadyPenalty?['name'] ?? '#whoBOOM';
    final bool hasSelection = _selectedReadyPenalty != null || selectedPenaltyText != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasSelection ? _MahkemeRenkler.yesil.withValues(alpha: 0.35) : Colors.grey.shade300,
            width: 1.2,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    '📜 Seçtiğin Ceza',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _MahkemeRenkler.ortaKahve,
                      letterSpacing: .2,
                    ),
                  ),
                ),
                if (selectedCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _MahkemeRenkler.yesil.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'CezaNo: $selectedCode',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: _MahkemeRenkler.koyu,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F2FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _coffinAnimationController != null
                        ? RotationTransition(
                            turns: _coffinAnimationController!,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: selectedEmoji != null
                                  ? Text(
                                      selectedEmoji,
                                      key: ValueKey<String>(selectedEmoji),
                                      style: const TextStyle(fontSize: 46),
                                    )
                                  : Icon(
                                      selectedIcon,
                                      key: ValueKey<IconData>(selectedIcon),
                                      size: 52,
                                      color: _MahkemeRenkler.ortaKahve,
                                    ),
                            ),
                          )
                        : selectedEmoji != null
                            ? Text(selectedEmoji, style: const TextStyle(fontSize: 46))
                            : Icon(selectedIcon, size: 52, color: _MahkemeRenkler.ortaKahve),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 74,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.arrow_left, color: Colors.green, size: 28),
                          onPressed: () => _navigateReadyPenalty(-1),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              selectedDisplayName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_right, color: Colors.green, size: 28),
                          onPressed: () => _navigateReadyPenalty(1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _goToSelectedTab() {
    if (selectedPenaltyText == null || selectedPenaltyText!.trim().isEmpty) {
      _showMahkemeSnackBar(context, 'Önce bir ceza seçmelisiniz.', _MahkemeRenkler.kirmizi);
      return;
    }
    setState(() => _isMahkemeKarariVisible = true);
    _showMahkemeSnackBar(context, 'Mahkeme kararı açıldı. Resmi mühür ile cezayı kesinleştirin.', Colors.green.shade700);
  }

  void _cancelSelectedPenalty() {
    setState(() {
      selectedPenaltyText = null;
      selectedReadyIndex = null;
      expandedReadyIndex = null;
      selectedMemberPenaltyIndex = null;
      selectedMember = null;
      expandedMember = null;
      expandedMemberPenaltyIndex = null;
      _isCustomPenaltySelected = false;
      _isMahkemeKarariVisible = false;
      _isPenaltyApplied = false;
    });
    _showMahkemeSnackBar(context, 'Seçili ceza iptal edildi.', _MahkemeRenkler.kirmizi);
  }

  void _ensureShakeController() {
    _shakeController ??= AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _triggerShake() {
    if (_isSealTapInProgress) {
      return;
    }
    _ensureShakeController();
    _shakeController!.forward(from: 0.0);
  }

  Future<void> _handleSealTap() async {
    if (_isSealTapInProgress || _isPenaltyApplied) {
      return;
    }
    if (selectedPenaltyText == null || selectedPenaltyText!.trim().isEmpty) {
      _showMahkemeSnackBar(context, 'Önce bir ceza seçmelisiniz.', _MahkemeRenkler.kirmizi);
      return;
    }

    _ensureShakeController();
    setState(() => _isSealTapInProgress = true);
    _shakeController!.repeat(period: const Duration(milliseconds: 120));

    try {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) {
        return;
      }
      _shakeController!
        ..stop()
        ..value = 0.0;
      await _finalizePenaltyWithSeal();
    } finally {
      if (mounted) {
        _shakeController!
          ..stop()
          ..value = 0.0;
        setState(() => _isSealTapInProgress = false);
      }
    }
  }

  /// Mahkeme önizlemesi görünürken ceza seçimi değişince mühür ikonunu bir kez titretir.
  void _scheduleSealShakeIfNeeded(String? selected, bool hasSelection) {
    if (!hasSelection || _isPenaltyApplied) {
      _lastShookPenaltyKey = null;
      return;
    }
    final String key = selected!.trim();
    if (_lastShookPenaltyKey == key) {
      return;
    }
    _lastShookPenaltyKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final String? current = selectedPenaltyText?.trim();
      if (current == null || current.isEmpty || _isPenaltyApplied) {
        return;
      }
      if (current != key) {
        return;
      }
      _triggerShake();
    });
  }

  Future<void> _finalizePenaltyWithSeal() async {
    if (selectedPenaltyText == null || selectedPenaltyText!.trim().isEmpty) {
      _showMahkemeSnackBar(context, 'Önce bir ceza seçmelisiniz.', _MahkemeRenkler.kirmizi);
      return;
    }
    if (_isPenaltyApplied) {
      _showMahkemeSnackBar(context, 'Ceza zaten resmi mühür ile kesinleştirildi.', Colors.green.shade700);
      return;
    }

    if (widget.davaId != null && widget.davaId!.isNotEmpty &&
        widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      try {
        final davaProvider = Provider.of<DavaProvider>(context, listen: false);
        await davaProvider.updateCezaForDava(
          davaId: widget.davaId!,
          userEmail: widget.userEmail!,
          cezaText: selectedPenaltyText!,
        );
      } catch (e) {
        debugPrint('❌ Ceza kaydedilirken hata: $e');
      }
    }

    if (!mounted) return;
    setState(() => _isPenaltyApplied = true);
    _showMahkemeSnackBar(context, '🔴 Resmi mühür vuruldu. Ceza verilmiş olarak kaydedildi.', _MahkemeRenkler.kirmizi);
    widget.onPenaltyApplied?.call();
    if (widget.onPenaltyApplied == null) {
      Navigator.of(context).pop(true);
    }
  }

  Widget _buildSelectedPenaltyDetailActionCard() {
    final Map<String, String>? selectedReadyPenalty = _selectedReadyPenalty;
    final String? selectedTitle = selectedReadyPenalty?['name'] ?? selectedPenaltyText;
    final String? selectedDescription = selectedReadyPenalty?['description'];
    final bool hasSelection = selectedTitle != null && selectedTitle.trim().isNotEmpty;
    final String detailText;
    if (hasSelection && selectedDescription != null && selectedDescription.trim().isNotEmpty) {
      detailText = selectedDescription;
    } else if (hasSelection) {
      detailText = 'Bu ceza için detay açıklaması bulunmuyor.';
    } else {
      detailText = 'Detay açıklamasını görmek için önce bir ceza seçiniz.';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasSelection ? _MahkemeRenkler.altin.withValues(alpha: 0.45) : Colors.grey.shade300,
            width: 1.2,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Seçilen Ceza Ayrıntılı Açıklama',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: hasSelection ? _MahkemeRenkler.koyu : _MahkemeRenkler.gri,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                detailText,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: hasSelection ? Colors.grey.shade900 : Colors.grey.shade600,
                  fontStyle: hasSelection ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: hasSelection ? _goToSelectedTab : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.red,
                      disabledBackgroundColor: Colors.green.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMahkemeKarariPreviewCard() {
    if (!_isMahkemeKarariVisible) {
      return const SizedBox.shrink();
    }

    _ensureShakeController();

    final String? selected = selectedPenaltyText;
    final bool hasSelection = selected != null && selected.trim().isNotEmpty;
    _scheduleSealShakeIfNeeded(selected, hasSelection);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD2CCBB), width: 1.2),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                // Kırmızı yerine ciddi bir koyu mavi/lacivert tonu eklendi
                color: Color(0xFF0D1B2A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Text(
                '📜 MAHKEME KARARI',
                textAlign: TextAlign.center,
                style: TextStyle(

                  color: _MahkemeRenkler.altin, // Altın rengi bu koyu mavi üzerinde çok şık duracaktır
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: <Widget>[
                  Text(
                    hasSelection
                        ? '"$selected"\ncezasının uygulanmasına karar verilmiştir.'
                        : '— henüz bir ceza seçilmedi —',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: hasSelection ? 14 : 12.5,
                      fontWeight: hasSelection ? FontWeight.w700 : FontWeight.w500,
                      color: hasSelection ? _MahkemeRenkler.ortaKahve : _MahkemeRenkler.gri,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: hasSelection && !_isPenaltyApplied && !_isSealTapInProgress
                        ? _handleSealTap
                        : null,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: Opacity(
                        opacity: hasSelection ? 1 : 0.5,
                        child: MouseRegion(
                          onEnter: (_) {
                            if (!mounted) {
                              return;
                            }
                            if (hasSelection && !_isPenaltyApplied && !_isSealTapInProgress) {
                              _triggerShake();
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                _isPenaltyApplied
                                    ? 'Mühürlendi'
                                    : (_isSealTapInProgress ? 'Mühürleniyor...' : 'Mühürle'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: hasSelection
                                      ? const Color(0xFF8B0000)
                                      : Colors.grey.shade500,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AnimatedBuilder(
                                animation: _shakeController!,
                                builder: (BuildContext context, Widget? child) {
                                  final double offset =
                                      sin(_shakeController!.value * pi * 4) * 3;
                                  return Transform.translate(
                                    offset: Offset(
                                      hasSelection && !_isPenaltyApplied
                                          ? offset
                                          : 0,
                                      0,
                                    ),
                                    child: child,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: hasSelection
                                        ? const Color(0xFFF5F2EB)
                                        : const Color(0xFFEBE8E2),
                                    boxShadow: const <BoxShadow>[
                                      BoxShadow(
                                        color: Color(0x18000000),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                        offset: Offset(0, 0),
                                      ),
                                      BoxShadow(
                                        color: Color(0x30000000),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/muhur_icon.png',
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.contain,
                                    color: hasSelection
                                        ? null
                                        : Colors.grey.withOpacity(0.5),
                                    colorBlendMode: hasSelection
                                        ? null
                                        : BlendMode.modulate,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: hasSelection ? _cancelSelectedPenalty : null,
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: hasSelection
                            ? const Color(0xFF7D2A34)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialCountersRow() {
    return const SizedBox.shrink();
  }

  Widget _buildSimpleInfoFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Text(
        _isMahkemeKarariVisible
            ? (_isPenaltyApplied
                ? 'Karar resmi olarak mühürlendi. Bu kullanıcı artık ceza veremez.'
                : 'İnsanlar arasında hükmettiğinizde adâletle hükmedin. Kesinleştirmek için mühre dokun.')
            : 'Mahkeme kararı alanı, sadece "SEÇ" butonuna bastıktan sonra görünür.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          color: _MahkemeRenkler.gri.withValues(alpha: 0.9),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _socialCounter(IconData icon, int count, VoidCallback onTap) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(icon: Icon(icon, color: Colors.green, size: 20), onPressed: onTap),
        Text('$count', style: const TextStyle(color: Colors.green, fontSize: 13)),
      ],
    );
  }

  // ─── BAŞLIK (yalnızca sheet modunda) ─────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_MahkemeRenkler.koyu, _MahkemeRenkler.ortaKahve],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: widget.embeddedMiddlePane
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(bottom: BorderSide(color: _MahkemeRenkler.altin, width: 1.5)),
      ),
      child: Row(
        children: [
          // Çekiç + rozet
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _MahkemeRenkler.altin.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _MahkemeRenkler.altin.withOpacity(0.4)),
            ),
            child: const Text('⚖️', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ceza Yönetimi',
                  style: TextStyle(
                    color: _MahkemeRenkler.altin,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Mahkeme-i Kübra — Adalet hâkim!',
                  style: TextStyle(
                    color: _MahkemeRenkler.altin.withValues(alpha: 0.82),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // Kapat butonu
          InkWell(
            onTap: () => Navigator.of(context).pop(false),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _MahkemeRenkler.ortaKahve.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB BAR ─────────────────────────────────────────────────
  Widget _buildTabBar() {
    if (_tabController == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: _MahkemeRenkler.koyu,
        border: const Border(bottom: BorderSide(color: _MahkemeRenkler.altin, width: 1)),
      ),
      child: TabBar(
        controller: _tabController!,
        labelColor: _MahkemeRenkler.altin,
        unselectedLabelColor: Color(0xFF8B87B0),
        indicatorColor: _MahkemeRenkler.altin,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        tabs: const <Widget>[
          Tab(icon: Text('⚖️', style: TextStyle(fontSize: 16)), text: 'Ceza Seç'),
          Tab(icon: Text('✍️', style: TextStyle(fontSize: 16)), text: 'Özel Ceza'),
          Tab(icon: Text('📜', style: TextStyle(fontSize: 16)), text: 'Seçilen'),
        ],
      ),
    );
  }

  // ─── CEZA SEÇİMİ TAB ─────────────────────────────────────────
  Widget _buildCezaSecimiTab(ScrollController? scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Kategori seçici — levha görünümü
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _MahkemeRenkler.kemik,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _MahkemeRenkler.altin.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(color: _MahkemeRenkler.koyu.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _buildCategoryButton('Hazır Ceza', 0)),
                const SizedBox(width: 8),
                Expanded(child: _buildCategoryButton('Üyelerden', 1)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Ceza listesi — parşömen tarzı kağıt
          Container(
            decoration: BoxDecoration(
              color: _MahkemeRenkler.kemik,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _MahkemeRenkler.altin.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(color: _MahkemeRenkler.koyu.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            // Küçük başlık şeridi
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    color: _MahkemeRenkler.koyu,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          activeCategory == 'Hazır Ceza' ? '📋 Resmi Ceza Listesi' : '👥 Üye Kararları',
                          softWrap: true,
                          style: const TextStyle(
                            color: _MahkemeRenkler.altin,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                activeCategory == 'Hazır Ceza' ? _buildReadyList() : _buildMembersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String label, int index) {
    final bool isActive = activeCategory == label;
    return GestureDetector(
      onTap: () {
        if (activeCategory == label) {
          return;
        }
        setState(() {
          activeCategory = label;
          if (label == 'Üyelerden') {
            selectedReadyIndex = null;
            expandedReadyIndex = null;
            selectedMemberPenaltyIndex = null;
            selectedMember = null;
            expandedMember = null;
            expandedMemberPenaltyIndex = null;
          } else {
            selectedMemberPenaltyIndex = null;
            selectedMember = null;
            expandedMember = null;
            expandedMemberPenaltyIndex = null;
            _applyDefaultHazirCezaSelection();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? _MahkemeRenkler.ortaKahve : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _MahkemeRenkler.altin : _MahkemeRenkler.altin.withOpacity(0.3),
          ),
        ),
        child: Text(
          isActive ? '● $label' : label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? _MahkemeRenkler.altin : _MahkemeRenkler.ortaKahve,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildReadyList() {
    final List<Map<String, String>> sortedPenalties = List<Map<String, String>>.from(readyPenalties);
    sortedPenalties.sort((a, b) {
      final aLikes = _cezaBegenileri[a['name']!] ?? 0;
      final bLikes = _cezaBegenileri[b['name']!] ?? 0;
      if (aLikes != bLikes) return bLikes.compareTo(aLikes);
      return readyPenalties.indexOf(a).compareTo(readyPenalties.indexOf(b));
    });

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedPenalties.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: _MahkemeRenkler.altin.withOpacity(0.2)),
      itemBuilder: (BuildContext context, int index) {
        final penalty = sortedPenalties[index];
        final cezaName = penalty['name']!;
        final originalIndex = readyPenalties.indexOf(penalty);
        final bool selected = selectedReadyIndex == originalIndex;
        final int likeCount = _cezaBegenileri[cezaName] ?? 0;
        final bool isLiked = _userLikedCezalar[cezaName] ?? false;
        final bool isExpanded = expandedReadyIndex == originalIndex;
        final String? description = penalty['description'];

        return Column(
          children: <Widget>[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectReady(originalIndex),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected ? _MahkemeRenkler.ortaKahve.withValues(alpha: 0.12) : Colors.transparent,
                  ),
                  child: Row(
                    children: <Widget>[
                      // Sıra numarası — mühür görünümü
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? _MahkemeRenkler.ortaKahve : _MahkemeRenkler.altin.withOpacity(0.15),
                          border: Border.all(
                            color: selected ? _MahkemeRenkler.ortaKahve : _MahkemeRenkler.altin.withOpacity(0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (index + 1).toString(),
                            style: TextStyle(
                              color: selected ? Colors.white : _MahkemeRenkler.ortaKahve,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cezaName,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? _MahkemeRenkler.ortaKahve : _MahkemeRenkler.koyu,
                            height: 1.3,
                          ),
                        ),
                      ),
                      // Beğeni butonu
                      GestureDetector(
                        onTap: () => _toggleCezaBegeni(cezaName),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLiked ? _MahkemeRenkler.ortaKahve.withValues(alpha: 0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isLiked ? _MahkemeRenkler.ortaKahve : _MahkemeRenkler.altin.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(isLiked ? '❤️' : '🤍', style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 3),
                              Text(
                                likeCount.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isLiked ? _MahkemeRenkler.ortaKahve : _MahkemeRenkler.gri,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: _MahkemeRenkler.altin.withOpacity(0.7),
                        size: 18,
                      ),
                      if (selected) ...[
                        const SizedBox(width: 4),
                        Text(
                          _isPenaltyApplied ? '🔒' : '🔓',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Açılır açıklama — parşömen altına yazılmış gibi
            if (isExpanded && description != null && description.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 52, right: 14, bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _MahkemeRenkler.kemik,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _MahkemeRenkler.altin.withOpacity(0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📜', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        description,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _MahkemeRenkler.ortaKahve,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMembersList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: memberPenalties.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (BuildContext context, int index) {
        final String member = memberPenalties.keys.elementAt(index);
        final Map<String, dynamic> memberData = memberPenalties[member]!;
        final List<String> penalties = memberData['penalties'] as List<String>;

        return Container(
          decoration: BoxDecoration(
            color: _MahkemeRenkler.kemik,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _MahkemeRenkler.altin.withOpacity(0.4)),
          ),
          child: ExpansionTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _MahkemeRenkler.ortaKahve,
                border: Border.all(color: _MahkemeRenkler.altin, width: 1.5),
              ),
              child: Center(
                child: Text(
                  memberData['avatar'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _MahkemeRenkler.altin, fontSize: 15),
                ),
              ),
            ),
            title: Text(
              member,
              softWrap: true,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _MahkemeRenkler.koyu),
            ),
            subtitle: Text(
              memberData['hashtag'] as String,
              softWrap: true,
              style: const TextStyle(fontSize: 11, color: _MahkemeRenkler.gri),
            ),
            iconColor: _MahkemeRenkler.altin,
            collapsedIconColor: _MahkemeRenkler.altin,
            children: <Widget>[
              ...penalties.asMap().entries.map((MapEntry<int, String> entry) {
                final int idx = entry.key;
                final String txt = entry.value;
                final bool selected = (selectedMember == member && selectedMemberPenaltyIndex == idx);
                final bool isExpanded = (expandedMember == member && expandedMemberPenaltyIndex == idx);

                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectMemberPenalty(member, idx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: selected ? _MahkemeRenkler.ortaKahve.withValues(alpha: 0.12) : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              if (_coffinAnimationController != null)
                                RotationTransition(
                                  turns: _coffinAnimationController!,
                                  child: const Text('⚰️', style: TextStyle(fontSize: 16)),
                                )
                              else
                                const Text('⚰️', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  txt,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                    color: selected ? _MahkemeRenkler.ortaKahve : _MahkemeRenkler.koyu,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: _MahkemeRenkler.altin.withOpacity(0.7),
                                size: 16,
                              ),
                              if (selected)
                                Text(
                                  _isPenaltyApplied ? '🔒' : '🔓',
                                  style: const TextStyle(fontSize: 14),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Container(
                        margin: const EdgeInsets.only(left: 42, right: 14, bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _MahkemeRenkler.kemik,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _MahkemeRenkler.altin.withOpacity(0.4)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🪶', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$txt — Bu ceza üye tarafından mahkemeye sunulmuştur. Karar üyeye aittir!',
                                softWrap: true,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _MahkemeRenkler.ortaKahve,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ─── ÖZEL CEZA TAB ───────────────────────────────────────────
  Widget _buildOzelCezaTab(ScrollController? scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Hikayeveri giriş banner'ı
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _MahkemeRenkler.kemik,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _MahkemeRenkler.altin.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                const Text('✍️', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                const Text(
                  'Kalemin Gücü Seninle!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _MahkemeRenkler.ortaKahve,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mahkeme listesinde bulamazsanız, kendi cezanızı yaratan büyük hâkim sizsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: _MahkemeRenkler.gri, height: 1.5),
                ),
                if (_isCustomPenaltySelected && !_isPenaltyApplied) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade400),
                    ),
                    child: const Text(
                      '✏️ Ceza seçildi — düzenlenebilir',
                      style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Başlık girişi
          _buildOzelCezaLabel('1. Ceza Başlığını Yaz', '🏷️'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _customTitleCtrl,
            focusNode: _customTitleFocus,
            maxLines: 4,
            maxLength: 100,
            hint: _isPenaltyApplied ? 'Ceza mühürlendi, artık değişmez!' : 'Ör: Mahkûmu Serinletme Cezası',
          ),
          const SizedBox(height: 14),

          // Açıklama girişi
          _buildOzelCezaLabel('2. Ceza Açıklamasını Yaz', '📝'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _customDescriptionCtrl,
            focusNode: _customDescriptionFocus,
            maxLines: 6,
            maxLength: 400,
            hint: _isPenaltyApplied
                ? 'Ceza mühürlendi, artık değişmez!'
                : 'Mahkeme kaydına geçmesi için detaylı açıklama yazın (en az 15 karakter)...',
          ),
          const SizedBox(height: 14),

          // Sayaç + buton satırı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Sayaçlar
              Wrap(
                spacing: 6,
                children: [
                  _buildSayac('Başlık', _customTitleCtrl.text.length, 3, 100),
                  _buildSayac('Açıklama', _customDescriptionCtrl.text.length, 15, 400),
                ],
              ),
              // Buton
              if (_isCustomPenaltySelected && !_isPenaltyApplied)
                _buildMahkemeButton(
                  label: '🔄 Güncelle',
                  onPressed: _isCustomPenaltyValid ? _updateCustomPenalty : null,
                  color: Colors.blue.shade700,
                )
              else
                _buildMahkemeButton(
                  label: '📋 Kaydet',
                  onPressed: _isCustomPenaltyValid && !_isPenaltyApplied ? _saveCustomPenalty : null,
                  color: _MahkemeRenkler.ortaKahve,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOzelCezaLabel(String text, String emoji) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            softWrap: true,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _MahkemeRenkler.ortaKahve,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required int maxLines,
    required int maxLength,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _isPenaltyApplied ? _MahkemeRenkler.kemik.withOpacity(0.5) : _MahkemeRenkler.kemik,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _MahkemeRenkler.altin.withOpacity(0.5)),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        minLines: maxLines > 4 ? 4 : 1,
        maxLength: maxLength,
        enabled: !_isPenaltyApplied,
        readOnly: _isPenaltyApplied,
        style: const TextStyle(fontSize: 13, color: _MahkemeRenkler.koyu, height: 1.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _MahkemeRenkler.gri, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildSayac(String label, int current, int min, int max) {
    final bool ok = current >= min && current <= max;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? Colors.green.withOpacity(0.08) : _MahkemeRenkler.kemik,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ok ? Colors.green.shade400 : _MahkemeRenkler.altin.withOpacity(0.4)),
      ),
      child: Text(
        '$label: $current/$max',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: ok ? Colors.green.shade700 : _MahkemeRenkler.gri,
        ),
      ),
    );
  }

  Widget _buildMahkemeButton({
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? color : _MahkemeRenkler.gri.withOpacity(0.3),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: onPressed != null ? 3 : 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  // ─── SEÇİLEN CEZA TAB ────────────────────────────────────────
  Widget _buildSecilenCezaTab(ScrollController? scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Parşömen efektli ceza belgesi
          Container(
            decoration: BoxDecoration(
              color: _MahkemeRenkler.kemik,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _MahkemeRenkler.altin, width: 2),
              boxShadow: [
                BoxShadow(color: _MahkemeRenkler.koyu.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                // Üst başlık şeridi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: _MahkemeRenkler.koyu,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('⚖️ ', style: TextStyle(fontSize: 18)),
                      Text(
                        'MAHKEME KARARI',
                        style: TextStyle(
                          color: _MahkemeRenkler.altin,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tarih satırı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mahkeme-i Kübra',
                        style: TextStyle(fontSize: 11, color: _MahkemeRenkler.gri, fontStyle: FontStyle.italic),
                      ),
                      Text(
                        _formatDate(),
                        style: const TextStyle(fontSize: 11, color: _MahkemeRenkler.gri),
                      ),
                    ],
                  ),
                ),
                Divider(color: _MahkemeRenkler.altin.withOpacity(0.4), thickness: 1),
                // Ceza metni
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'İşbu belge ile,',
                        style: TextStyle(fontSize: 12, color: _MahkemeRenkler.gri, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        selectedPenaltyText != null
                            ? '"$selectedPenaltyText"'
                            : '— henüz bir ceza seçilmedi —',
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: selectedPenaltyText != null ? 16 : 13,
                          fontWeight: selectedPenaltyText != null ? FontWeight.bold : FontWeight.normal,
                          color: selectedPenaltyText != null ? _MahkemeRenkler.ortaKahve : _MahkemeRenkler.gri,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (selectedPenaltyText != null)
                        const Text(
                          'cezasının uygulanmasına karar verilmiştir.\nBu karar kesin ve değiştirilemez!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: _MahkemeRenkler.gri, fontStyle: FontStyle.italic, height: 1.5),
                        ),
                    ],
                  ),
                ),
                Divider(color: _MahkemeRenkler.altin.withOpacity(0.4), thickness: 1),
                // Mühür
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: _MahkemeRenkler.ortaKahve, width: 1.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🔴 RESMİ MÜHÜR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _MahkemeRenkler.ortaKahve,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Durum bilgisi
          if (selectedPenaltyText == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade400),
              ),
              child: const Row(
                children: [
                  Text('⚠️', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"Ceza Seç" veya "Özel Ceza" sekmesinden bir ceza belirleyiniz.',
                      style: TextStyle(fontSize: 12, color: _MahkemeRenkler.ortaKahve, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    return '${now.day}.${now.month}.${now.year}';
  }

  // ─── ALT AKSİYON BUTONLARI ───────────────────────────────────
  Widget _buildBottomActions() {
    final bool hasSelection = selectedPenaltyText != null && selectedPenaltyText!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: _MahkemeRenkler.kemik,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _MahkemeRenkler.altin.withValues(alpha: 0.55), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _MahkemeRenkler.koyu.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: const BoxDecoration(
                color: _MahkemeRenkler.koyu,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Text(
                '⚖️ KARAR İŞLEMLERİ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _MahkemeRenkler.altin,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Vazgeç'),
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _MahkemeRenkler.gri,
                        side: BorderSide(color: _MahkemeRenkler.gri.withValues(alpha: 0.8)),
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: hasSelection ? _applyPenalty : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _MahkemeRenkler.kirmizi,
                        disabledBackgroundColor: _MahkemeRenkler.kirmizi.withValues(alpha: 0.35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: hasSelection ? 6 : 0,
                        shadowColor: _MahkemeRenkler.kirmizi.withValues(alpha: 0.35),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('🔨', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text(
                            'CEZA UYGULA!',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!hasSelection)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(
                  'Karar işlemi için önce bir ceza seçiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: _MahkemeRenkler.gri.withValues(alpha: 0.92),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
