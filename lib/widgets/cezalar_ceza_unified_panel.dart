import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/dava_provider.dart';
import '../services/ceza_muhur.dart';
import '../services/dava_hukum_eligibility_service.dart';
import '../services/hive_database_service.dart';
import '../theme/seyir_tokens.dart';
import 'cezalar_unified_dava.dart';
import 'countdown_timer_widget.dart';

export 'cezalar_unified_dava.dart' show CezalarUnifiedDava;

part 'cezalar_mahkeme_renkler.dart';

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
  /// Testlerde kayıt hatasını taklit etmek için. Boşsa [DavaProvider] yazılır.
  final CezaKaydedici? cezaKaydedici;

  const CezalarCezaUnifiedPanel({
    super.key,
    required this.dava,
    this.davaId,
    this.userEmail,
    this.embeddedMiddlePane = false,
    this.davaOpenedAt,
    this.onPenaltyApplied,
    this.showSheetCloseHeader = false,
    this.cezaKaydedici,
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

  int? selectedReadyIndex;
  String? selectedPenaltyText;

  bool _isPenaltyApplied = false;
  bool _isMahkemeKarariVisible = false;
  DateTime? _sealedAt;
  String? _sealError;

  AnimationController? _coffinAnimationController;
  AnimationController? _shakeController;
  bool _isSealTapInProgress = false;
  final GlobalKey _kararBoundaryKey = GlobalKey();

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

  void _applyDefaultHazirCezaSelection() {
    final int idx = readyPenalties.indexWhere(
      (Map<String, String> penalty) => penalty['name'] == _defaultHazirCezaName,
    );
    if (idx == -1) {
      return;
    }
    selectedReadyIndex = idx;
    selectedPenaltyText = readyPenalties[idx]['name'];
  }

  @override
  void initState() {
    super.initState();
    _applyDefaultHazirCezaSelection();

    _coffinAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _ensureShakeController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedCeza();
      _loadGorevHukumOnizleme();
    });
  }

  @override
  void didUpdateWidget(covariant CezalarCezaUnifiedPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.davaId != widget.davaId ||
        oldWidget.userEmail != widget.userEmail) {
      _loadSavedCeza();
    }
    if (oldWidget.davaId != widget.davaId ||
        oldWidget.dava.mevkii != widget.dava.mevkii ||
        oldWidget.dava.adi != widget.dava.adi) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadGorevHukumOnizleme());
    }
  }

  Future<void> _loadSavedCeza() async {
    final String davaId = widget.davaId?.trim() ?? '';
    final String email = widget.userEmail?.trim() ?? '';
    if (davaId.isEmpty || email.isEmpty) {
      return;
    }
    final CezaKaydi? kayit = await HiveDatabaseService.getCezaKaydi(
      davaId: davaId,
      userEmail: email,
    );
    if (!mounted || kayit == null || !kayit.isSealed) {
      return;
    }
    setState(() => _applySealedKayit(kayit));
  }

  void _applySealedKayit(CezaKaydi kayit) {
    selectedPenaltyText = kayit.text;
    _sealedAt = kayit.sealedAt;
    _isPenaltyApplied = true;
    _isMahkemeKarariVisible = true;
    _sealError = null;
    final int idx = readyPenalties.indexWhere(
      (Map<String, String> penalty) => penalty['name'] == kayit.text,
    );
    selectedReadyIndex = idx == -1 ? null : idx;
  }

  @override
  void dispose() {
    _coffinAnimationController?.dispose();
    _shakeController?.dispose();
    super.dispose();
  }

  void _navigateReadyPenalty(int delta) {
    if (_isPenaltyApplied || readyPenalties.isEmpty) {
      return;
    }
    final int currentIndex = selectedReadyIndex ?? (delta < 0 ? readyPenalties.length - 1 : 0);
    final int nextIndex = (currentIndex + delta + readyPenalties.length) % readyPenalties.length;
    final Map<String, String> penalty = readyPenalties[nextIndex];
    final String cezaName = penalty['name']!;

    setState(() {
      selectedReadyIndex = nextIndex;
      selectedPenaltyText = cezaName;
      _isMahkemeKarariVisible = false;
      _sealError = null;
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

  /// Mahkeme temalı SnackBar
  void _showMahkemeSnackBar(BuildContext ctx, String mesaj, Color renk) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.gavel, color: SeyirPalette.of(ctx).onSolid(renk), size: 18),
            const SizedBox(width: SeyirTokens.space2),
            Expanded(
              child: Text(
                mesaj,
                style: TextStyle(
                  fontSize: SeyirTokens.typeBody,
                  fontWeight: FontWeight.w500,
                  color: SeyirPalette.of(ctx).onSolid(renk),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: renk,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: SeyirTokens.radiusMdAll),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(
          horizontal: SeyirTokens.space4,
          vertical: SeyirTokens.space2,
        ),
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
    final Color iconColor = _gorevHukumVar
        ? _MahkemeRenkler.accent(context)
        : SeyirPalette.of(context).textSecondary;
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
                  color: _MahkemeRenkler.accent(context),
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
                            child: Icon(Icons.expand_more, size: 20, color: SeyirPalette.of(context).textSecondary),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Görevinize ait hüküm',
                              style: TextStyle(
                                fontSize: SeyirTokens.typeCaption,
                                fontWeight: FontWeight.w600,
                                color: SeyirPalette.of(context).textPrimary,
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
                    color: SeyirPalette.of(context).surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SelectableText(
                        _gorevHukumOnizleme ??
                            (widget.davaId == null || widget.davaId!.trim().isEmpty
                                ? 'Bu dava için hüküm kaydı yüklemek üzere dava kimliği gerekir. Yargıla ekranındaki görev rozetinden devam edin.'
                                : 'Bu görev için henüz kayıtlı hüküm metni bulunamadı veya yükleniyor…'),
                        style: TextStyle(fontSize: 13, height: 1.45, color: SeyirPalette.of(context).textPrimary),
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
      _showMahkemeSnackBar(context, 'Görev bilgisi bulunamadı.', _MahkemeRenkler.warning(context));
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
        _showMahkemeSnackBar(context, 'Hükümler yüklenirken hata oluştu.', _MahkemeRenkler.danger(context));
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
          backgroundColor: _MahkemeRenkler.warning(dialogContext),
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
              color: SeyirPalette.of(ctx).card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SeyirPalette.of(ctx).border),
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
                            Icon(MdiIcons.fileCheck, color: _MahkemeRenkler.accent(ctx), size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    normalizedRole,
                                    style: TextStyle(
                                      fontSize: SeyirTokens.typeTitle,
                                      fontWeight: FontWeight.bold,
                                      color: _MahkemeRenkler.accent(ctx),
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
                                        fontSize: SeyirTokens.typeCaption,
                                        color: SeyirPalette.of(context).textSecondary,
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
                        color: SeyirPalette.of(ctx).textSecondary,
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
                        color: SeyirPalette.of(ctx).surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SeyirPalette.of(ctx).border),
                      ),
                      child: Text(
                        finalHukumText,
                        style: TextStyle(fontSize: SeyirTokens.typeBody, height: 1.5, color: SeyirPalette.of(ctx).textPrimary),
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
        color: SeyirPalette.of(context).surface,
        borderRadius: widget.embeddedMiddlePane
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: AnimatedSize(
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
            ),
          ),
          _buildSimpleInfoFooter(),
          _buildSocialCountersRow(),
        ],
      ),
    );
  }

  /// [ModernHukumCard._buildDavaInfo] ile aynı künye davranışı (profil / beğeni satırı yok).
  Widget _buildDavaSummaryCard() {
    final CezalarUnifiedDava d = widget.dava;
    final Color accentGreen = _MahkemeRenkler.accent(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SeyirTokens.space1,
        SeyirTokens.space2,
        SeyirTokens.space1,
        SeyirTokens.space1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: SeyirPalette.of(context).card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SeyirPalette.of(context).border),
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
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: SeyirPalette.of(context).textPrimary,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _cezaKunyeExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: Icon(Icons.expand_more, color: SeyirPalette.of(context).textSecondary, size: 26),
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
                style: TextStyle(fontSize: SeyirTokens.typeCaption, fontWeight: FontWeight.w600, color: SeyirPalette.of(context).textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '—' : value,
                softWrap: true,
                style: TextStyle(fontSize: SeyirTokens.typeBody, fontWeight: FontWeight.bold, color: SeyirPalette.of(context).textPrimary),
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
            Icon(MdiIcons.timerAlertOutline, size: 20, color: _MahkemeRenkler.warning(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Dava Açılış Tarihi',
                    style: TextStyle(
                      fontSize: SeyirTokens.typeCaption,
                      fontWeight: FontWeight.w600,
                      color: SeyirPalette.of(context).textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    openedAtText,
                    style: TextStyle(
                      fontSize: SeyirTokens.typeBody,
                      fontWeight: FontWeight.bold,
                      color: SeyirPalette.of(context).textPrimary,
                    ),
                  ),
                  if (openedAt == null && widget.dava.kalanSure.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      widget.dava.kalanSure,
                      style: TextStyle(
                        fontSize: SeyirTokens.typeCaption,
                        fontWeight: FontWeight.w600,
                        color: SeyirPalette.of(context).foreground(SeyirTokens.sectionPeople),
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

  Widget _buildCoffinWhoBoomRow() {
    final SeyirPalette palette = SeyirPalette.of(context);
    final Color accent = _MahkemeRenkler.accent(context);
    final IconData selectedIcon = _resolveSelectedPenaltyIcon();
    final String? selectedEmoji = _resolveSelectedPenaltyEmoji();
    final int? selectedCode = _selectedReadyPenaltyCode;
    final String selectedDisplayName =
        _selectedReadyPenalty?['name'] ?? selectedPenaltyText ?? '#whoBOOM';
    final bool hasSelection = selectedDisplayName.trim().isNotEmpty &&
        selectedDisplayName != '#whoBOOM';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space4,
        vertical: SeyirTokens.space1,
      ),
      child: Container(
        padding: const EdgeInsets.all(SeyirTokens.space3),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: SeyirTokens.radiusMdAll,
          border: Border.all(
            color: hasSelection ? palette.tintBorder(SeyirTokens.brand) : palette.border,
          ),
          boxShadow: palette.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '📜 Seçtiğin Ceza',
                    style: palette.body(weight: FontWeight.w800, color: accent),
                  ),
                ),
                if (selectedCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SeyirTokens.space2,
                      vertical: SeyirTokens.space1,
                    ),
                    decoration: BoxDecoration(
                      color: palette.brandSoft,
                      borderRadius: BorderRadius.circular(SeyirTokens.radiusXl),
                    ),
                    child: Text(
                      'CezaNo: $selectedCode',
                      style: palette.caption(
                        weight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: SeyirTokens.space2),
            Row(
              children: <Widget>[
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: SeyirTokens.radiusMdAll,
                  ),
                  child: Center(
                    child: _coffinAnimationController != null
                        ? RotationTransition(
                            turns: _coffinAnimationController!,
                            child: AnimatedSwitcher(
                              duration: SeyirTokens.motion,
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
                                      color: accent,
                                    ),
                            ),
                          )
                        : selectedEmoji != null
                            ? Text(
                                selectedEmoji,
                                style: const TextStyle(fontSize: 46),
                              )
                            : Icon(selectedIcon, size: 52, color: accent),
                  ),
                ),
                const SizedBox(width: SeyirTokens.space3),
                Expanded(
                  child: Container(
                    height: 74,
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: SeyirTokens.radiusMdAll,
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Önceki ceza',
                          icon: Icon(
                            Icons.arrow_left,
                            color: _isPenaltyApplied ? palette.textMuted : accent,
                            size: 28,
                          ),
                          onPressed: _isPenaltyApplied
                              ? null
                              : () => _navigateReadyPenalty(-1),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              selectedDisplayName,
                              textAlign: TextAlign.center,
                              style: palette.title(),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sonraki ceza',
                          icon: Icon(
                            Icons.arrow_right,
                            color: _isPenaltyApplied ? palette.textMuted : accent,
                            size: 28,
                          ),
                          onPressed: _isPenaltyApplied
                              ? null
                              : () => _navigateReadyPenalty(1),
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
    if (_isPenaltyApplied) {
      return;
    }
    if (selectedPenaltyText == null || selectedPenaltyText!.trim().isEmpty) {
      _showMahkemeSnackBar(
        context,
        'Önce bir ceza seçmelisiniz.',
        _MahkemeRenkler.danger(context),
      );
      return;
    }
    setState(() {
      _isMahkemeKarariVisible = true;
      _sealError = null;
    });
    _showMahkemeSnackBar(
      context,
      'Mahkeme kararı açıldı. Resmi mühür ile cezayı kesinleştirin.',
      _MahkemeRenkler.accent(context),
    );
  }

  void _cancelSelectedPenalty() {
    if (_isPenaltyApplied) {
      return;
    }
    setState(() {
      selectedPenaltyText = null;
      selectedReadyIndex = null;
      _isMahkemeKarariVisible = false;
      _sealError = null;
    });
    _showMahkemeSnackBar(
      context,
      'Seçili ceza iptal edildi.',
      _MahkemeRenkler.danger(context),
    );
  }

  Future<CezaMuhurKilit> _readSealLock() async {
    bool altiRolTamam = false;
    bool temyizPenceresiAcik = false;
    final String davaId = widget.davaId?.trim() ?? '';
    if (davaId.isNotEmpty) {
      try {
        altiRolTamam =
            await DavaHukumEligibilityService.hasSixPanelFinalized(davaId);
        final Map<String, dynamic>? opened =
            HiveDatabaseService.getOpenedDavaById(davaId);
        temyizPenceresiAcik =
            DavaHukumEligibilityService.isAppealJudgeWindowActive(opened);
      } catch (e) {
        debugPrint('Mühür kilidi okunamadı: $e');
      }
    }
    return CezaMuhurKilit.degerlendir(
      gorev: widget.dava.mevkii,
      openedAt: widget.davaOpenedAt,
      now: DateTime.now(),
      altiRolTamam: altiRolTamam,
      temyizPenceresiAcik: temyizPenceresiAcik,
    );
  }

  Future<bool> _confirmSeal() async {
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        final SeyirPalette palette = SeyirPalette.of(ctx);
        return AlertDialog(
          title: Text('Emin misin?', style: palette.headline()),
          content: Text(
            'Bu cezayı mühürlersen karar kesinleşir.',
            style: palette.body(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Mühürle'),
            ),
          ],
        );
      },
    );
    return onay == true;
  }

  void _markSealFailed(String mesaj) {
    setState(() {
      _isPenaltyApplied = false;
      _sealError = mesaj;
    });
    _showMahkemeSnackBar(
      context,
      '$mesaj Tekrar dene.',
      _MahkemeRenkler.danger(context),
    );
  }

  Future<void> _handleSealTap() async {
    if (_isSealTapInProgress || _isPenaltyApplied) {
      return;
    }
    if (selectedPenaltyText == null || selectedPenaltyText!.trim().isEmpty) {
      _showMahkemeSnackBar(
        context,
        'Önce bir ceza seçmelisiniz.',
        _MahkemeRenkler.danger(context),
      );
      return;
    }

    final CezaMuhurKilit kilit = await _readSealLock();
    if (!mounted) {
      return;
    }
    if (kilit.kilitli) {
      _showMahkemeSnackBar(
        context,
        kilit.neden ?? 'Mühür henüz açılamaz.',
        _MahkemeRenkler.warning(context),
      );
      return;
    }

    final bool onay = await _confirmSeal();
    if (!onay || !mounted) {
      return;
    }

    _ensureShakeController();
    setState(() {
      _isSealTapInProgress = true;
      _sealError = null;
    });
    await HapticFeedback.lightImpact();
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

  void _ensureShakeController() {
    _shakeController ??= AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  Future<void> _finalizePenaltyWithSeal() async {
    final String text = selectedPenaltyText?.trim() ?? '';
    if (text.isEmpty) {
      _showMahkemeSnackBar(
        context,
        'Önce bir ceza seçmelisiniz.',
        _MahkemeRenkler.danger(context),
      );
      return;
    }
    if (_isPenaltyApplied) {
      return;
    }

    final String davaId = widget.davaId?.trim() ?? '';
    final String email = widget.userEmail?.trim() ?? '';
    if (davaId.isEmpty || email.isEmpty) {
      _markSealFailed('Dava veya kullanıcı bilgisi eksik. Mühür kaydedilemedi.');
      return;
    }

    final DateTime sealedAt = DateTime.now();
    bool saved = false;
    try {
      final CezaKaydedici? kaydedici = widget.cezaKaydedici;
      if (kaydedici != null) {
        saved = await kaydedici(
          davaId: davaId,
          userEmail: email,
          cezaText: text,
          sealedAt: sealedAt,
        );
      } else {
        final DavaProvider davaProvider =
            Provider.of<DavaProvider>(context, listen: false);
        saved = await davaProvider.updateCezaForDava(
          davaId: davaId,
          userEmail: email,
          cezaText: text,
          sealedAt: sealedAt,
        );
      }
    } catch (e) {
      debugPrint('❌ Ceza kaydedilirken hata: $e');
      saved = false;
    }

    if (!mounted) {
      return;
    }
    if (!saved) {
      _markSealFailed('Mühür kaydedilemedi.');
      return;
    }

    setState(() {
      _isPenaltyApplied = true;
      _sealedAt = sealedAt;
      _sealError = null;
      _isMahkemeKarariVisible = true;
    });
    _showMahkemeSnackBar(
      context,
      'Resmi mühür vuruldu. Ceza kaydedildi.',
      _MahkemeRenkler.accent(context),
    );
    widget.onPenaltyApplied?.call();
  }

  Future<void> _shareSealedDecision() async {
    try {
      final RenderObject? object =
          _kararBoundaryKey.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) {
        throw StateError('Karar görüntüsü hazır değil');
      }
      final ui.Image image = await object.toImage(pixelRatio: 3);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) {
        throw StateError('PNG üretilemedi');
      }
      final Directory dir = await getApplicationDocumentsDirectory();
      final String safeId = (widget.davaId ?? 'karar')
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final File file = File('${dir.path}/mahkeme_karari_$safeId.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      if (!mounted) {
        return;
      }
      try {
        await Share.shareXFiles(
          <XFile>[
            XFile(
              file.path,
              mimeType: 'image/png',
              name: 'mahkeme_karari.png',
            ),
          ],
          text: 'Mahkeme kararı: ${selectedPenaltyText ?? ''}',
        );
      } catch (shareError) {
        debugPrint('Paylaşım açılamadı, dosya kaydedildi: $shareError');
        if (!mounted) {
          return;
        }
        _showMahkemeSnackBar(
          context,
          'Karar görüntüsü belgelere kaydedildi.',
          _MahkemeRenkler.accent(context),
        );
      }
    } catch (e) {
      debugPrint('Karar görüntüsü oluşturulamadı: $e');
      if (!mounted) {
        return;
      }
      _showMahkemeSnackBar(
        context,
        'Görüntü kaydedilemedi. Tekrar dene.',
        _MahkemeRenkler.danger(context),
      );
    }
  }

  Widget _buildSelectedPenaltyDetailActionCard() {
    final SeyirPalette palette = SeyirPalette.of(context);
    final Color accent = _MahkemeRenkler.accent(context);
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
      padding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space4,
        vertical: SeyirTokens.space2,
      ),
      child: Container(
        padding: const EdgeInsets.all(SeyirTokens.space3),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: SeyirTokens.radiusMdAll,
          border: Border.all(
            color: hasSelection ? palette.tintBorder(SeyirTokens.brand) : palette.border,
          ),
          boxShadow: palette.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Seçilen Ceza Ayrıntılı Açıklama',
              style: palette.body(
                weight: FontWeight.w800,
                color: hasSelection ? palette.textPrimary : palette.textSecondary,
              ),
            ),
            const SizedBox(height: SeyirTokens.space2),
            Container(
              padding: const EdgeInsets.all(SeyirTokens.space2),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: SeyirTokens.radiusSmAll,
                border: Border.all(color: palette.border),
              ),
              child: Text(
                detailText,
                style: palette.body(
                  color: hasSelection ? palette.textPrimary : palette.textSecondary,
                ).copyWith(
                  fontStyle: hasSelection ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: SeyirTokens.space2),
            ElevatedButton(
              onPressed: hasSelection && !_isPenaltyApplied ? _goToSelectedTab : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: _MahkemeRenkler.onAccent(context),
                disabledBackgroundColor: palette.surfaceMuted,
                disabledForegroundColor: palette.textMuted,
                minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space2),
                shape: const RoundedRectangleBorder(borderRadius: SeyirTokens.radiusMdAll),
                elevation: 0,
              ),
              child: Text(
                'OK',
                style: palette.title(
                  weight: FontWeight.w800,
                  color: hasSelection && !_isPenaltyApplied
                      ? _MahkemeRenkler.onAccent(context)
                      : palette.textMuted,
                ),
              ),
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

    final SeyirPalette palette = SeyirPalette.of(context);
    final Color accent = _MahkemeRenkler.accent(context);
    final Color header = _MahkemeRenkler.header(context);
    final Color onHeader = _MahkemeRenkler.onHeader(context);
    final String? selected = selectedPenaltyText;
    final bool hasSelection = selected != null && selected.trim().isNotEmpty;
    final String? description = _selectedReadyPenalty?['description']?.trim();
    final bool canSeal = hasSelection && !_isPenaltyApplied && !_isSealTapInProgress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SeyirTokens.space4,
        0,
        SeyirTokens.space4,
        SeyirTokens.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RepaintBoundary(
            key: _kararBoundaryKey,
            child: Container(
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: SeyirTokens.radiusMdAll,
                border: Border.all(color: palette.border),
                boxShadow: palette.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SeyirTokens.space3,
                      vertical: SeyirTokens.space2,
                    ),
                    decoration: BoxDecoration(
                      color: header,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(SeyirTokens.radiusMd),
                      ),
                    ),
                    child: Text(
                      '📜 MAHKEME KARARI',
                      textAlign: TextAlign.center,
                      style: palette.headline(color: onHeader),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(SeyirTokens.space3),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'Seçilen ceza',
                          style: palette.caption(weight: FontWeight.w700),
                        ),
                        const SizedBox(height: SeyirTokens.space2),
                        Text(
                          hasSelection
                              ? '"$selected"\ncezasının uygulanmasına karar verilmiştir.'
                              : '— henüz bir ceza seçilmedi —',
                          textAlign: TextAlign.center,
                          style: palette.body(
                            weight: hasSelection ? FontWeight.w700 : FontWeight.w500,
                            color: hasSelection ? accent : palette.textSecondary,
                          ).copyWith(fontStyle: FontStyle.italic),
                        ),
                        if (description != null && description.isNotEmpty) ...<Widget>[
                          const SizedBox(height: SeyirTokens.space2),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: palette.body(),
                          ),
                        ],
                        if (_isPenaltyApplied) ...<Widget>[
                          const SizedBox(height: SeyirTokens.space3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SeyirTokens.space3,
                              vertical: SeyirTokens.space2,
                            ),
                            decoration: BoxDecoration(
                              color: palette.brandSoft,
                              borderRadius: BorderRadius.circular(SeyirTokens.radiusXl),
                              border: Border.all(color: accent),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Image.asset(
                                  'assets/images/muhur_icon.png',
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: SeyirTokens.space2),
                                Text(
                                  'Mühürlendi',
                                  style: palette.title(color: accent),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: SeyirTokens.space2),
                          Text(
                            _sealedAt == null
                                ? 'Mühür tarihi kayıtlı değil'
                                : 'Mühür: ${_formatCezaKunyeDateTime(_sealedAt!)}',
                            textAlign: TextAlign.center,
                            style: palette.caption(),
                          ),
                        ],
                        const SizedBox(height: SeyirTokens.space4),
                        GestureDetector(
                          key: const Key('ceza-muhurle'),
                          onTap: canSeal ? _handleSealTap : null,
                          behavior: HitTestBehavior.opaque,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: SeyirTokens.tapTarget,
                              minHeight: SeyirTokens.tapTarget,
                            ),
                            child: Opacity(
                              opacity: hasSelection ? 1 : 0.5,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    _isPenaltyApplied
                                        ? 'Mühürlendi'
                                        : (_isSealTapInProgress ? 'Mühürleniyor...' : 'Mühürle'),
                                    textAlign: TextAlign.center,
                                    style: palette.body(
                                      weight: FontWeight.w800,
                                      color: hasSelection ? accent : palette.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: SeyirTokens.space2),
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
                                      padding: const EdgeInsets.all(SeyirTokens.space2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: palette.surfaceMuted,
                                        boxShadow: palette.cardShadow,
                                      ),
                                      child: Image.asset(
                                        'assets/images/muhur_icon.png',
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.contain,
                                        color: hasSelection
                                            ? null
                                            : palette.textMuted.withValues(alpha: 0.5),
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
                        if (_sealError != null && !_isPenaltyApplied) ...<Widget>[
                          const SizedBox(height: SeyirTokens.space2),
                          Text(
                            _sealError!,
                            textAlign: TextAlign.center,
                            style: palette.body(color: SeyirTokens.reject),
                          ),
                          TextButton(
                            onPressed: _isSealTapInProgress ? null : _finalizePenaltyWithSeal,
                            child: const Text('Tekrar dene'),
                          ),
                        ],
                        if (!_isPenaltyApplied) ...<Widget>[
                          const SizedBox(height: SeyirTokens.space1),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: 'Seçimi kapat',
                              onPressed: hasSelection ? _cancelSelectedPenalty : null,
                              icon: Icon(
                                Icons.close,
                                color: hasSelection ? accent : palette.textMuted,
                              ),
                              style: IconButton.styleFrom(
                                minimumSize: const Size(
                                  SeyirTokens.tapTarget,
                                  SeyirTokens.tapTarget,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isPenaltyApplied)
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: _shareSealedDecision,
                icon: const Icon(Icons.ios_share),
                label: const Text('Paylaş'),
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialCountersRow() {
    return const SizedBox.shrink();
  }

  Widget _buildSimpleInfoFooter() {
    final SeyirPalette palette = SeyirPalette.of(context);
    final String metin;
    if (_isMahkemeKarariVisible && _isPenaltyApplied) {
      metin = 'Karar mühürlendi. Seçim kilitli; görüntüyü paylaşabilirsin.';
    } else if (_isMahkemeKarariVisible) {
      metin = 'İnsanlar arasında hükmettiğinizde adâletle hükmedin. Kesinleştirmek için mühre dokun.';
    } else {
      metin = 'Mahkeme kararı alanı, sadece OK ile açılır.';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SeyirTokens.space4,
        SeyirTokens.space1,
        SeyirTokens.space4,
        SeyirTokens.space3,
      ),
      child: Text(
        metin,
        textAlign: TextAlign.center,
        style: palette.caption().copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildHeader() {
    final SeyirPalette palette = SeyirPalette.of(context);
    final Color header = _MahkemeRenkler.header(context);
    final Color onHeader = _MahkemeRenkler.onHeader(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space4,
        vertical: SeyirTokens.space3,
      ),
      decoration: BoxDecoration(
        color: header,
        borderRadius: widget.embeddedMiddlePane
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(SeyirTokens.radiusXl)),
        border: Border(bottom: BorderSide(color: palette.tintBorder(SeyirTokens.brand))),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(SeyirTokens.space2),
            decoration: BoxDecoration(
              color: palette.brandSoft,
              borderRadius: SeyirTokens.radiusMdAll,
              border: Border.all(color: palette.tintBorder(SeyirTokens.brand)),
            ),
            child: Text('⚖️', style: palette.headline()),
          ),
          const SizedBox(width: SeyirTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Ceza Yönetimi',
                  style: palette.headline(color: onHeader),
                ),
                Text(
                  'Mahkeme-i Kübra — Adalet hâkim!',
                  style: palette.caption(color: onHeader).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kapat',
            onPressed: () => Navigator.of(context).pop(_isPenaltyApplied),
            icon: Icon(Icons.close, color: onHeader),
            style: IconButton.styleFrom(
              backgroundColor: palette.brandSoft,
              minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
            ),
          ),
        ],
      ),
    );
  }
}
