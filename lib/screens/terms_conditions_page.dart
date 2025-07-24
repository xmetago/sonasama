import 'package:flutter/material.dart';

/// Koşullarınız sayfası. Metin parametre ile alınabilir.
class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koşullar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 15, color: Colors.black),
              children: [
                const TextSpan(
                  text: 'WhoBoom Kullanım Koşulları\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Yürürlük Tarihi: 19.06.2025\n',
                ),
                const TextSpan(
                  text: 'Geçerlilik: Türkiye Cumhuriyeti yasaları geçerlidir. Uyuşmazlık halinde Hatay Mahkemeleri yetkilidir.\n\n',
                ),
                const TextSpan(
                  text: '1. Genel Hükümler\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'WhoBoom tamamen mizah ve eğlence temelli bir sosyal platformdur. Kullanımınız bu sözleşmeyi kabul ettiğiniz anlamına gelir.\n\nBu sözleşme yalnızca Türkçe hazırlanmıştır. Çevirilerle çelişme durumunda Türkçe metin esas alınır.\n\nWhoBoom\'a erişiminiz ya da kullanımınız, bu koşulları kabul ettiğiniz anlamına gelir.\n\n',
                ),
                const TextSpan(
                  text: '2. İçerik ve Paylaşımlar\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Paylaştığınız tüm içerikler size aittir. Fakat platformda bu içeriklerin yayınlanmasıyla WhoBoom\'a, içeriği kullanma ve sınırlı ölçekte tanıtımda gösterme hakkı vermiş sayılırsınız.\n\nTelif haklarına tabi içeriklerde yasal sorumluluk size aittir.\n\nKişisel verilerinizin görünürlüğünü "Seyir Defterim Görsün" gibi ayarlarla belirleyebilirsiniz. Ayarlar herkese açık ise bilgileriniz, adınız ve profil resminiz dahil olmak üzere, üçüncü şahıslarca görülebilir.\n\n',
                ),
                const TextSpan(
                  text: '3. Kullanıcı Yükümlülükleri\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Başkalarının içeriklerini otomatik yollarla (bot, spider vb.) toplamak yasaktır.\n\nAşağıdaki içerikleri paylaşmak yasaktır:\n\n    Nefret söylemi, çıplaklık, pornografi, tehdit, şiddet\n    Taciz, siyasi propaganda, yasa dışı amaçlar\n    Diğer kullanıcıları rahatsız edici davranışlar\n\n13 yaş altı kullanıcıların erişimi yasaktır.\n\nHesap bilgilerinizin güvenliğinden siz sorumlusunuz. Şifrenizi kimseyle paylaşmayınız.\n\n',
                ),
                const TextSpan(
                  text: '4. Kimlik ve Marka Politikası\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Kullandığınız kullanıcı adı yanıltıcı, resmi kurum adıyla benzer veya başka bir kişinin kimliğine ilişkin olmamalıdır. Aksi durumlarda kullanıcı adını değiştirme ya da silme hakkımız saklıdır.\n\n"WhoBoom", "the WhoBoom", "Wodoom" ve türevleri marka kapsamında korunmaktadır. Önceden izin alınmaksızın kullanılamaz.\n\n',
                ),
                const TextSpan(
                  text: '5. Reklam ve Ödeme Koşulları\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'WhoBoom\'da reklamlar yayınlanabilir, ancak hedef kitleye ulaşım garanti edilmez.\n\nTıklama bazlı reklam maliyetlerinde dolandırıcılık, geçersizlik gibi durumlar için WhoBoom sorumluluk kabul etmez.\n\nReklam siparişiniz kabul edilirse, ödeme yükümlülüğü size aittir.\n\nHer reklam, içerik uygunluğuna göre kabul edilir veya reddedilir.\n\n',
                ),
                const TextSpan(
                  text: '6. Fesih ve Askıya Alma\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Koşulların ihlali halinde hesabınız askıya alınabilir veya silinebilir. Bu durum size bildirilmek zorunda değildir.\n\nHesabınızı istediğiniz zaman silebilirsiniz.\n\n',
                ),
                const TextSpan(
                  text: '7. Hukuki Sınırlamalar ve Sorumluluk Reddi\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'WhoBoom, kullanıcıların içeriklerinden, paylaşımlarından ve davranışlarından sorumlu değildir.\n\nPlatformda uygunsuz içerikle karşılaşmanız halinde bu sizin sorumluluğunuzdadır.\n\nWhoBoom, açık ya da zımni hiçbir garanti vermez. Platform "olduğu gibi" sunulmaktadır.\n\nUyuşmazlıklar yalnızca Tunceli Ovacık Mahkemesi\'nde çözümlenecektir.\n\nMaksimum sorumluluğumuz 10 TL ile sınırlıdır.\n\n',
                ),
                const TextSpan(
                  text: '8. Diğer Hükümler\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'Bu sözleşme, WhoBoom ile sizin aranızda yapılan tüm önceki sözleşmelerin yerine geçer.\n\nHerhangi bir hüküm geçersiz sayılırsa diğer maddeler geçerliliğini korur.\n\nKoşullarda yapılacak değişiklikleri takip etme yükümlülüğü size aittir.\n\nGüncel koşulları takip etmeden kullanımınız, değişiklikleri kabul ettiğiniz anlamına gelir.\n\nKoşullarda belirtilmemiş tüm haklar WhoBoom tarafından saklı tutulur.\n\n',
                ),
                const TextSpan(
                  text: '9. Mizah ve Platform İlkesi\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: 'WhoBoom yalnızca eğlence ve şaka amaçlıdır. Bu amaç dışı kullanımlar (özellikle siyaset) yasaktır.\n\nWhoBoom, HAYKIR ve DAVA kampanyalarında yalnızca aracıdır. Bu eylemlerden doğacak hukuki sonuçlardan kullanıcılar sorumludur.\n',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 