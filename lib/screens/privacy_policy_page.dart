import 'package:flutter/material.dart';

/// Gizlilik Politikası sayfası. Metin parametre ile alınabilir.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikamız'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 15, color: Colors.black),
              children: [
                const TextSpan(
                  text: 'WhoBoom Gizlilik Politikası (Twitter Gizlilik Politikası ile Uyumlu Şekilde Uyarlanmıştır)\n\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: '1. Genel Kapsam\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Bu Gizlilik Politikası, whoBoom.com ve bağlı tüm hizmetler (mobil uygulamalar, API, web hizmetleri vb.) için geçerlidir.\n\n',
                ),
                const TextSpan(
                  text: '2. Toplanan Veriler\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'ÜTB (Üye Tanımlayıcı Bilgiler): Ad, soyad, e-posta adresi, telefon numarası, profil fotoğrafı.\n\nUTB Dışı Veriler: IP adresi, cihaz bilgisi, işletim sistemi, tarayıcı türü, ziyaret süresi, konum verisi, kullanıcı etkileşimi.\n\n',
                ),
                const TextSpan(
                  text: '3. Çerezler ve Takip Teknolojileri\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'WhoBoom, kullanıcı deneyimini geliştirmek ve oturumları yönetmek amacıyla çerezler kullanır.\n\nÜçüncü taraflar (ör. reklam ortakları) da tarayıcınıza çerez yerleştirebilir.\n\nTakip pikselleri, oturum belirteçleri ve benzeri teknolojiler kullanılabilir.\n\n',
                ),
                const TextSpan(
                  text: '4. Verilerin Kullanım Amaçları\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Hizmet sağlama ve kişiselleştirme.\n\nGüvenlik ve dolandırıcılığı önleme.\n\nReklam ve içerik optimizasyonu.\n\nPlatform gelişimi ve kullanıcı deneyimi analizi.\n\n',
                ),
                const TextSpan(
                  text: '5. Bilgi Paylaşımı\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Yetkili iş ortakları ve hizmet sağlayıcılarla.\n\nHukuki gereklilikler durumunda resmi makamlarla.\n\nKullanıcının açık rızasıyla üçüncü taraflarla.\n\n',
                ),
                const TextSpan(
                  text: '6. Kişisel Bilgilerin Korunması\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Veri şifreleme, erişim kontrolü ve düzenli güvenlik testleri uygulanmaktadır.\n\nFiziksel, teknik ve idari önlemler ile veri güvenliği sağlanır.\n\n',
                ),
                const TextSpan(
                  text: '7. Kullanıcı Kontrolü ve Hakları\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Kullanıcılar; erişim, düzeltme, silme, itiraz ve veri taşınabilirliği haklarına sahiptir.\n\nHesap silindikten sonra yasal zorunluluklar gereği bazı veriler tutulabilir.\n\n',
                ),
                const TextSpan(
                  text: '8. Uluslararası Veri Aktarımı\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Veriler, Avrupa Birliği, Amerika Birleşik Devletleri ve diğer ülkelerdeki sunuculara aktarılabilir.\n\nUluslararası transferlerde Avrupa Komisyonu\'nun Standart Sözleşme Maddeleri uygulanır.\n\n',
                ),
                const TextSpan(
                  text: '9. Veri İhlali Bildirimi\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Veri ihlali durumunda, yasal süreler içinde kullanıcı ve yetkili otoriteler bilgilendirilir.\n\n',
                ),
                const TextSpan(
                  text: '10. Yasal Sorumluluk Reddi\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Kullanıcı tarafından paylaşılan içeriklerden yalnızca kullanıcı sorumludur.\n\nÜçüncü taraf bağlantı ve uygulamalardan doğan sonuçlardan WhoBoom sorumlu tutulamaz.\n\n',
                ),
                const TextSpan(
                  text: '11. Üçüncü Taraf Siteler ve Reklamcılar\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Reklam gösteriminde üçüncü kişi sağlayıcılar kullanılabilir.\n\nBu sağlayıcıların gizlilik politikaları geçerlidir; WhoBoom bu uygulamalardan sorumlu değildir.\n\n',
                ),
                const TextSpan(
                  text: '12. Veri Saklama Süresi\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Veriler, amaç gerçekleşene kadar veya yasal yükümlülükler süresince saklanır.\n\nKullanıcı hesabı silinse dahi bazı veriler yasal yükümlülük kapsamında tutulabilir.\n\n',
                ),
                const TextSpan(
                  text: '13. Çocukların Gizliliği\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: '13 yaş altındaki kişilerin platformu kullanması yasaktır.\n\nReşit olmayan kullanıcıların bilgileri tespit edilirse silinir.\n\n',
                ),
                const TextSpan(
                  text: '14. Gizlilik Politikası Güncellemeleri\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Politika değişiklikleri, güncellenmiş tarih ile web sitesinde yayınlanır.\n\nKullanımın devamı, değişikliklerin kabulü anlamına gelir.\n\n',
                ),
                const TextSpan(
                  text: '15. İletişim Bilgisi\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Sorular ve talepler için: privacy@whoboom.com\n\n',
                ),
                const TextSpan(
                  text: '16. Amaç ve Bağlayıcılık\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Bu politika, WhoBoom ile kullanıcı arasındaki yasal çerçeveyi tanımlar.\n\nKullanıcı, hizmetin eğlence amaçlı olduğunu ve paylaşımlarından doğan sonuçlardan sorumlu olduğunu kabul eder.\n\n',
                ),
                const TextSpan(
                  text: '17. Gizlilik Şikayetleri\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Kullanıcı, yerel veri koruma yasalarına uymakla yükümlüdür.\n\nŞikayet durumunda ilk olarak privacy@whoboom.com adresiyle iletişim kurulmalıdır.\n\nWhoBoom, çözümlenemeyen gizlilik şikayetleri için üyeye hizmeti kullanmayı bırakmasını tavsiye eder.\n\n',
                ),
                const TextSpan(
                  text: '18. Veri Sahipliği ve İzinler\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Kullanıcı, paylaştığı içeriklerin sahibi olduğunu ve gerekli tüm haklara sahip olduğunu beyan eder.\n\nPaylaşım sırasında açık rıza verilen içerik, WhoBoom tarafından analiz ve geliştirme amacıyla kullanılabilir.\n\n',
                ),
                const TextSpan(
                  text: '19. Üçüncü Tarafların Veri Paylaşımıyla İlgili Sorumluluk\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'WhoBoom kullanıcı bilgilerini yalnızca bu politikada belirtilen çerçevede paylaşır.\n\nÜçüncü taraflar, kullanıcı bilgilerinin güvenliğinden doğrudan sorumludur.\n\n',
                ),
                const TextSpan(
                  text: '20. Gizlilik Taahhüdü\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'WhoBoom, kullanıcı verilerine saygı gösterir ve gizliliği korumayı taahhüt eder.\n\nGizlilik politikası kullanıcı bilgilendirme amacı taşır ve yasal güvence sağlar.\n\n',
                ),
                const TextSpan(
                  text: '21. Politika Dışı Kullanım\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Bu politikada açıkça belirtilmeyen hiçbir veri kullanımı yapılamaz.\n\nYeni kullanım amaçları için kullanıcıdan açık onay alınır.\n\n',
                ),
                const TextSpan(
                  text: '22. Politika\'nın Yürürlüğe Girmesi\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Bu politika 22 Temmuz 2013 tarihinde yürürlüğe girmiştir ve en son güncelleme tarihi belge başında belirtilmiştir.\n',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 