import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/hive_database_service.dart';
import '../providers/dava_provider.dart';
import '../widgets/modern_invitation_card.dart';
import '../utils/comment_utils.dart';
import '../widgets/common_header_widgets.dart';
import './haykir_page.dart'; // ✅ HAYKIR sayfasına yönlendirme için
import '../widgets/modern_dava_card.dart';
export '../widgets/davet_card.dart';
export '../widgets/modern_dava_card.dart';


class DavetlerPage extends StatefulWidget {
  final String? userEmail;
  
  const DavetlerPage({super.key, this.userEmail});

  @override
  State<DavetlerPage> createState() => _DavetlerPageState();
}

class DavetEtListesiSayfasi extends StatefulWidget {
  final String? userEmail;

  const DavetEtListesiSayfasi({super.key, this.userEmail});

  @override
  State<DavetEtListesiSayfasi> createState() => _DavetEtListesiSayfasiState();
}

class _DavetlerPageState extends State<DavetlerPage> {
  List<Map<String, dynamic>> davetler = [];

  @override
  void initState() {
    super.initState();
    _loadAktifDavetler();
  }

  // ignore: unused_element
  void _loadDavetler() {
    if (widget.userEmail != null) {
      print('DEBUG: DavetlerPage - Loading invitations for ${widget.userEmail}');
      final invitations = HiveDatabaseService.getInvitations(widget.userEmail!);
      print('DEBUG: DavetlerPage - Loaded ${invitations.length} invitations');
      
      // Davetleri kontrol et ve eksik alanları doldur
      final processedInvitations = invitations.map((invitation) {
        // Güvenli tip dönüşümü
        final processed = <String, dynamic>{};
        invitation.forEach((key, value) {
          processed[key.toString()] = value;
        });
        
        // Eksik alanları varsayılan değerlerle doldur
        processed['yorumSayisi'] ??= 0;
        processed['retweetSayisi'] ??= 0;
        processed['begeniSayisi'] ??= 0;
        processed['begenmemeSayisi'] ??= 0;
        processed['userLiked'] ??= false;
        processed['userDisliked'] ??= false;
        processed['userRetweeted'] ??= false;
        processed['isOpened'] ??= false;
        processed['yorumlar'] ??= <Map<String, dynamic>>[];
        
        return processed;
      }).toList();
      
      setState(() {
        davetler = processedInvitations;
      });
    } else {
      print('DEBUG: DavetlerPage - userEmail is null');
    }
  }

  // Güvenli yorumlar tip dönüşümü
  List<Map<String, dynamic>> _safeCastYorumlar(dynamic yorumlar) {
    if (yorumlar == null) return <Map<String, dynamic>>[];
    
    if (yorumlar is List) {
      return yorumlar.map((yorum) {
        if (yorum is Map) {
          final safeYorum = <String, dynamic>{};
          yorum.forEach((key, value) {
            safeYorum[key.toString()] = value;
          });
          return safeYorum;
        }
        return <String, dynamic>{};
      }).toList();
    }
    
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _buildWatchPayload(
    Map<String, dynamic> davet, {
    required bool isWatching,
    required String stateChangedAt,
  }) {
    final davaId = (davet['davaId'] ?? davet['id'])?.toString() ?? '';
    final caseName = (davet['davaAdi'] ?? davet['adi'] ?? '').toString();
    final profilResmi = davet['profilResmi']?.toString();
    final openedAtRaw = (davet['openedAt'] ?? davet['createdAt'] ?? davet['invitedAt'])?.toString();
    final watchState = isWatching ? 'on' : 'of';
    final watchLabel = isWatching ? 'ON' : 'OF';

    return {
      'davaId': davaId,
      'davaAdi': caseName,
      'davaci': davet['davaci']?.toString(),
      'davali': davet['davali']?.toString(),
      'kategori': davet['davaKategori']?.toString(),
      'userEmail': widget.userEmail,
      'displayName': davet['displayName']?.toString(),
      'profilResmi': profilResmi,
      'openedAt': openedAtRaw,
      'stateChangedAt': stateChangedAt,
      'watchState': watchState,
      'watchStateLabel': watchLabel,
      'isWatching': isWatching,
    };
  }

  void _loadAktifDavetler() {
    if (widget.userEmail != null) {
      print('DEBUG: DavetlerPage - Loading ACTIVE invitations for ${widget.userEmail}');
      final invitations = HiveDatabaseService.getActiveInvitations(widget.userEmail!);
      print('DEBUG: DavetlerPage - Loaded ${invitations.length} ACTIVE invitations');

      final processedInvitations = invitations.map((invitation) {
        // Güvenli tip dönüşümü
        final processed = <String, dynamic>{};
        invitation.forEach((key, value) {
          processed[key.toString()] = value;
        });
        
        processed['yorumSayisi'] ??= 0;
        processed['retweetSayisi'] ??= 0;
        processed['begeniSayisi'] ??= 0;
        processed['begenmemeSayisi'] ??= 0;
        processed['userLiked'] ??= false;
        processed['userDisliked'] ??= false;
        processed['userRetweeted'] ??= false;
        processed['isOpened'] ??= false;
        processed['yorumlar'] ??= <Map<String, dynamic>>[];
        return processed;
      }).toList();

      setState(() {
        davetler = processedInvitations;
      });
    }
  }

  // Mock davalar - gerçek davet yoksa gösterilecek
  // ignore: unused_element
  List<Map<String, dynamic>> _getMockDavalar() {
    return [
      {
        'userEmail': 'avukat1@example.com',
        'displayName': 'Ahmet Yılmaz',
        'davaAdi': 'İş Hukuku Davası',
        'davaKategori': 'İş Hukuku',
        'davaKonusu': 'Haksız yere işten çıkarılma davası. Çalışanın 5 yıllık hizmet süresi boyunca hiçbir disiplin cezası almamış olmasına rağmen, işveren tarafından geçersiz gerekçelerle işten çıkarılması durumu.',
        'isOpened': false,
        'yorumSayisi': 12,
        'retweetSayisi': 5,
        'begeniSayisi': 23,
        'begenmemeSayisi': 2,
        'userLiked': false,
        'userDisliked': false,
        'yorumlar': [
          {
            'id': 1,
            'userName': 'Av. Mehmet Kaya',
            'userEmail': 'mehmet@example.com',
            'yorum': 'Bu dava için gerekli delilleri toplamak önemli. İş sözleşmesi ve çalışma belgeleri mutlaka sunulmalı.',
            'tarih': '2024-01-15 14:30',
            'begeniSayisi': 5,
          },
          {
            'id': 2,
            'userName': 'Av. Fatma Demir',
            'userEmail': 'fatma@example.com',
            'yorum': 'İş Kanunu\'nun 20. maddesi bu durumda çok net. İşverenin geçerli gerekçe göstermesi gerekiyor.',
            'tarih': '2024-01-15 15:45',
            'begeniSayisi': 3,
          },
        ],
      },
      {
        'userEmail': 'avukat2@example.com',
        'displayName': 'Ayşe Demir',
        'davaAdi': 'Trafik Kazası Tazminat Davası',
        'davaKategori': 'Trafik Hukuku',
        'davaKonusu': 'Kırmızı ışık ihlali sonucu meydana gelen trafik kazasında maddi ve manevi tazminat talebi.',
        'davali': 'Mehmet Yılmaz',
        'isOpened': false,
        'yorumSayisi': 8,
        'retweetSayisi': 3,
        'begeniSayisi': 15,
        'begenmemeSayisi': 1,
        'userLiked': false,
        'userDisliked': false,
        'yorumlar': [],
      },
      {
        'userEmail': 'avukat3@example.com',
        'displayName': 'Mehmet Özkan',
        'davaAdi': 'Boşanma Davası',
        'davaKategori': 'Aile Hukuku',
        'davaKonusu': 'Anlaşmalı boşanma davası. Mal paylaşımı ve velayet konularında uzlaşma sağlanmış durumda.',
        'davali': 'Fatma Özkan',
        'isOpened': false,
        'yorumSayisi': 4,
        'retweetSayisi': 1,
        'begeniSayisi': 7,
        'begenmemeSayisi': 0,
        'userLiked': false,
        'userDisliked': false,
        'yorumlar': [],
      },
    ];
  }

  // Davet yenileme fonksiyonu
  void _refreshInvitations() {
    _loadAktifDavetler();
  }

  // Gerçek davetler için fonksiyonlar
  Future<void> _onSaveInvitation(Map<String, dynamic> davet) async {
    // Daveti kaydet ve durumu güncelle
    setState(() {
      davet['isOpened'] = true;
    });

    // Bitir: kalıcı olarak işaretle ve listeden kaldır
    try {
      final davaId = (davet['davaId'] ?? davet['id'])?.toString();
      if (widget.userEmail != null && davaId != null && davaId.isNotEmpty) {
        await HiveDatabaseService.markInvitationFinished(
          userEmail: widget.userEmail!,
          davaId: davaId,
        );
      }
    } catch (_) {}

    setState(() {
      final targetId = (davet['davaId'] ?? davet['id'])?.toString();
      davetler.removeWhere((e) =>
          (e['davaId']?.toString() ?? '') == targetId ||
          (e['id']?.toString() ?? '') == targetId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Davet bitirildi: ${davet['davaAdi']}'),
        backgroundColor: const Color(0xFF10B981), // Yeşil
        duration: const Duration(seconds: 2),
      ),
    );

    // Listeyi tazele (aktifleri yeniden yükle)
    _loadAktifDavetler();
  }

  Future<void> _onOpenInvitation(Map<String, dynamic> davet) async {
    // ✅ HAYKIR davetleri için özel işlem
    if (davet['type'] == 'haykir') {
      // HAYKIR davetini aç ve durumu güncelle
      setState(() {
        davet['isOpened'] = true;
      });
      
      // Veri tabanında da güncelle
      HiveDatabaseService.addInvitation(widget.userEmail!, davet);
      
      // HAYKIR sayfasına yönlendir
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HaykirPage(
            userEmail: widget.userEmail,
            initialShowForm: false, // Formu otomatik açma
          ),
        ),
      ).then((_) {
        // HAYKIR sayfasından dönüldüğünde listeyi yenile
        _loadAktifDavetler();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📢 HAYKIR açıldı: ${davet['davaAdi'] ?? davet['haykirAdi'] ?? 'HAYKIR'}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // ✅ Normal dava davetleri için mevcut işlem
    // Daveti aç ve durumu güncelle
    setState(() {
      davet['isOpened'] = true;
    });
    
    // Veri tabanında da güncelle
    HiveDatabaseService.addInvitation(widget.userEmail!, davet);
    
    final davaId = (davet['davaId'] ?? davet['id'])?.toString() ?? '';
    final watchPostId = 'dava_watch_${davaId.isNotEmpty ? davaId : DateTime.now().millisecondsSinceEpoch}';
    final nowIso = DateTime.now().toIso8601String();
    final davaProvider = Provider.of<DavaProvider>(context, listen: false);
    final existingWatchPost = HiveDatabaseService.getHomeFeedPostById(watchPostId, userEmail: widget.userEmail);
    final watchCreatedAt = existingWatchPost?['createdAt']?.toString() ?? nowIso;
    final watchPayloadOn = _buildWatchPayload(
      davet,
      isWatching: true,
      stateChangedAt: nowIso,
    );
    final onPost = {
      'id': watchPostId,
      'type': 'dava_watch',
      'createdAt': watchCreatedAt,
      'authorEmail': widget.userEmail,
      'payload': watchPayloadOn,
    };

    if (existingWatchPost != null) {
      await davaProvider.updateHomeFeedPost(watchPostId, onPost);
    } else {
      await davaProvider.addHomeFeedPost(onPost);
    }
    await davaProvider.refreshAll();

    if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('👁️ Dava izlenmeye alındı: ${davet['davaAdi'] ?? 'Dava'}'),
          backgroundColor: const Color(0xFF10B981), // Yeşil
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _onDelilEkleInvitation(Map<String, dynamic> davet) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 Delil ekleme: ${davet['davaAdi']}'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onYorumInvitation(
    Map<String, dynamic> davet,
    String yorumMetni, {
    String? parentCommentId,
    bool isGizliTanik = false,
  }) async {
    final mevcutYorumlar =
        List<Map<String, dynamic>>.from(davet['yorumlar'] ?? []);
    final gizliTanikSayisi = CommentUtils.countAllComments(
      mevcutYorumlar
          .where((comment) => comment['isGizliTanik'] == true)
          .toList(),
    );

    final yeniYorum = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'userName': isGizliTanik
          ? HiveDatabaseService.gizliTanikDisplayName
          : (widget.userEmail ?? 'Siz'),
      'userEmail': widget.userEmail,
      'yorum': yorumMetni,
      'tarih': DateTime.now().toString().substring(0, 19),
      'begeniSayisi': 0,
      'isGizliTanik': isGizliTanik,
      'parentId': parentCommentId,
      'replies': <Map<String, dynamic>>[],
    };

    setState(() {
      davet['yorumlar'] =
          CommentUtils.addComment(mevcutYorumlar, yeniYorum);
      davet['yorumSayisi'] =
          CommentUtils.countAllComments(davet['yorumlar']);
    });

    if (widget.userEmail != null) {
      HiveDatabaseService.addInvitation(widget.userEmail!, davet);
    }

    try {
      final String? davaId = (davet['davaId'] ?? davet['id'])?.toString();
      if (davaId != null && davaId.isNotEmpty) {
        final postId = 'dava_share_$davaId';
        final existing = HiveDatabaseService.getHomeFeedPostById(
          postId,
          userEmail: widget.userEmail,
        );

        if (existing != null) {
          final davaProvider =
              Provider.of<DavaProvider>(context, listen: false);
          final updatedPost = Map<String, dynamic>.from(existing);
          final yorumlar = List<Map<String, dynamic>>.from(
            updatedPost['payload']['yorumlar'] ?? [],
          );
          updatedPost['payload']['yorumlar'] =
              CommentUtils.addComment(yorumlar, yeniYorum);
          updatedPost['payload']['yorumSayisi'] =
              CommentUtils.countAllComments(
                  updatedPost['payload']['yorumlar']);
          await davaProvider.updateHomeFeedPost(postId, updatedPost);
          print('✅ Yorum seyir defterinde de güncellendi: $postId');
        }
      }
    } catch (e) {
      print('⚠️ Seyir defteri güncelleme hatası: $e');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💬 Yorum eklendi: "$yorumMetni"'),
        backgroundColor: const Color(0xFF10B981), // Yeşil
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onRetweetInvitation(Map<String, dynamic> davet) async {
    // ✅ Toggle mantığı: Eğer zaten retweet yapıldıysa geri al, yapılmadıysa retweet yap
    final isCurrentlyRetweeted = davet['userRetweeted'] == true;
    
    setState(() {
      if (isCurrentlyRetweeted) {
        // Retweet'i geri al
        davet['retweetSayisi'] = ((davet['retweetSayisi'] ?? 1) - 1).clamp(0, double.infinity).toInt();
        davet['userRetweeted'] = false;
      } else {
        // Retweet yap
        davet['retweetSayisi'] = (davet['retweetSayisi'] ?? 0) + 1;
        davet['userRetweeted'] = true;
      }
    });
    
    // Veri tabanında da güncelle
    HiveDatabaseService.addInvitation(widget.userEmail!, davet);

    // ✅ HAYKIR davetleri için özel işlem
    if (davet['type'] == 'haykir') {
      try {
        final String? haykirId = (davet['haykirId'] ?? davet['davaId'] ?? davet['id'])?.toString();
        if (haykirId != null && haykirId.isNotEmpty) {
          final davaProvider = Provider.of<DavaProvider>(context, listen: false);
          
          if (isCurrentlyRetweeted) {
            // ✅ Retweet geri alınıyor - Seyir Defteri'nden kaldır
            // HAYKIR retweet postlarını bul ve sil
            try {
              final allPosts = HiveDatabaseService.getHomeFeedPosts(userEmail: widget.userEmail);
              final haykirRetweetPosts = allPosts.where((post) {
                return post['type'] == 'haykir' &&
                       post['payload']?['haykirId']?.toString() == haykirId &&
                       post['payload']?['isRetweet'] == true &&
                       post['authorEmail'] == widget.userEmail;
              }).toList();
              
              for (var post in haykirRetweetPosts) {
                await davaProvider.removeHomeFeedPost(post['id']?.toString() ?? '');
              }
              
              // ✅ Katıldığım HAYKIR'lar sayfasından da kaldır
              await HiveDatabaseService.removeKatildigimHaykir(widget.userEmail!, haykirId);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🔄 HAYKIR paylaşımı geri alındı: ${davet['davaAdi'] ?? davet['haykirAdi'] ?? 'HAYKIR'}'),
                  backgroundColor: Colors.grey,
                  duration: const Duration(seconds: 2),
                ),
              );
            } catch (e) {
              print('⚠️ HAYKIR retweet geri alma hatası: $e');
            }
          } else {
            // ✅ Retweet yapılıyor - Seyir Defteri'ne ekle
            final postId = 'haykir_retweet_${haykirId}_${DateTime.now().millisecondsSinceEpoch}';
            final nowIso = DateTime.now().toIso8601String();
            
            final haykirPostData = {
              'id': postId,
              'type': 'haykir',
              'createdAt': nowIso,
              'authorEmail': widget.userEmail,
              'payload': {
                'haykirId': haykirId,
                'adi': davet['davaAdi'] ?? davet['haykirAdi'] ?? '',
                'slogan': davet['slogan'] ?? '',
                'direme': davet['direme'] ?? '',
                'detaylar': davet['detaylar'] ?? '',
                'createdAt': davet['createdAt'] ?? nowIso,
                'isRetweet': true,
              },
            };
            
            await davaProvider.addHomeFeedPost(haykirPostData);
            
            // ✅ HAYKIR için Katıldığım HAYKIR'lar sayfasına ekle
            await _addToKatildigimHaykirler(davet);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🔄 HAYKIR daveti Seyir Defteri\'nde paylaşıldı ve Katıldığım HAYKIR\'lar\'a eklendi: ${davet['davaAdi'] ?? davet['haykirAdi'] ?? 'HAYKIR'}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        print('❌ HAYKIR retweet hatası: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ HAYKIR paylaşım hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // ✅ Normal dava davetleri için mevcut işlem
    try {
      final String? davaId = (davet['davaId'] ?? davet['id'])?.toString();
      if (davaId != null && davaId.isNotEmpty) {
        final davaProvider = Provider.of<DavaProvider>(context, listen: false);
        final postId = 'dava_share_$davaId';
        final existing = HiveDatabaseService.getHomeFeedPostById(postId, userEmail: widget.userEmail);
        
        if (isCurrentlyRetweeted) {
          // ✅ Retweet geri alınıyor - Seyir Defteri'nden kaldır
          if (existing != null) {
            await davaProvider.removeHomeFeedPost(postId);
            print('✅ Seyir Defteri\'nden kaldırıldı: $postId');
          }
          
          // ✅ Katıldığım Davalar sayfasından da kaldır
          await HiveDatabaseService.removeKatildigimDava(widget.userEmail!, davaId);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔄 Davet paylaşımı geri alındı: ${davet['davaAdi']}'),
              backgroundColor: Colors.grey,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // ✅ Retweet yapılıyor - Seyir Defteri'ne ekle
          final nowIso = DateTime.now().toIso8601String();
          
          final postData = {
            'id': postId,
            'type': 'dava_share',
            'createdAt': nowIso,
            'authorEmail': widget.userEmail,
            'payload': Map<String, dynamic>.from(davet),
          };
          
          if (existing != null) {
            // Mevcut paylaşımı güncelle
            await davaProvider.updateHomeFeedPost(postId, postData);
            print('✅ Seyir Defteri güncellendi: $postId');
          } else {
            // Yeni paylaşım ekle
            await davaProvider.addHomeFeedPost(postData);
            print('✅ Seyir Defteri\'ne eklendi: $postId');
          }
          
          // ✅ YENİ: Katıldığım Davalar sayfasına da ekle
          await _addToKatildigimDavalar(davet);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔄 Davet Seyir Defteri\'nde paylaşıldı ve Katıldığım Davalar\'a eklendi: ${davet['davaAdi']}'),
              backgroundColor: const Color(0xFF10B981), // Yeşil
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('⚠️ Dava ID bulunamadı, Seyir Defteri\'ne eklenemedi');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Dava ID bulunamadı, paylaşılamadı'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Seyir Defteri paylaşım hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Paylaşım hatası: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// ✅ HAYKIR için Katıldığım HAYKIR'lar sayfasına ekle
  Future<void> _addToKatildigimHaykirler(Map<String, dynamic> davet) async {
    try {
      final String? haykirId = (davet['haykirId'] ?? davet['davaId'] ?? davet['id'])?.toString();
      if (haykirId != null && haykirId.isNotEmpty && widget.userEmail != null) {
        
        // Katıldığım HAYKIR'lar için veri hazırla
        final katildigimHaykirData = {
          'haykirId': haykirId,
          'id': haykirId,
          'adi': davet['davaAdi'] ?? davet['haykirAdi'] ?? 'HAYKIR Adı',
          'slogan': davet['slogan'] ?? '',
          'direme': davet['direme'] ?? '',
          'detaylar': davet['detaylar'] ?? '',
          'createdAt': davet['createdAt'] ?? DateTime.now().toIso8601String(),
          'userEmail': widget.userEmail!,
          'profilResmi': 'lib/icons/03_haykir_ana_icon.png',
          'source': 'davetler_page', // Kaynak bilgisi
          'isAccepted': true, // Kabul edilmiş olarak işaretle
        };

        // HiveDatabaseService'e ekle
        await HiveDatabaseService.addKatildigimHaykir(widget.userEmail!, katildigimHaykirData);
        
        print('✅ Katıldığım HAYKIR\'lar\'a eklendi: $haykirId');
        
      } else {
        print('⚠️ HAYKIR ID veya userEmail bulunamadı, Katıldığım HAYKIR\'lar\'a eklenemedi');
      }
    } catch (e) {
      print('❌ Katıldığım HAYKIR\'lar\'a eklenirken hata: $e');
    }
  }

  /// Katıldığım Davalar sayfasına dava ekle
  Future<void> _addToKatildigimDavalar(Map<String, dynamic> davet) async {
    try {
      final String? davaId = (davet['davaId'] ?? davet['id'])?.toString();
      if (davaId != null && davaId.isNotEmpty && widget.userEmail != null) {
        
        // Katıldığım davalar için veri hazırla
        final katildigimDavaData = {
          'id': davaId,
          'adi': davet['davaAdi'] ?? 'Dava Adı',
          'davaAdi': davet['davaAdi'] ?? 'Dava Adı',
          'davaKonusu': davet['davaKonusu'] ?? 'Dava konusu',
          'davaci': davet['davaci'] ?? 'Davacı',
          'davali': davet['davali'] ?? 'Davalı',
          'displayName': davet['displayName'] ?? 'Kullanıcı',
          'userEmail': widget.userEmail!,
          'mevkii': 'Katılımcı', // Katıldığım davalar için mevkii
          'kalanSure': DateTime.now().add(const Duration(days: 3)).toIso8601String(), // 3 gün sonra
          'profilResmi': 'lib/icons/07_profil_picture_davaci.png',
          'openedAt': DateTime.now().toIso8601String(),
          'acceptedAt': DateTime.now().toIso8601String(), // Kabul edildi olarak işaretle
          'kategori': davet['davaKategori'] ?? 'Genel',
          'davaKategori': davet['davaKategori'] ?? 'Genel',
          'source': 'davetler_page', // Kaynak bilgisi
          'isAccepted': true, // Kabul edilmiş olarak işaretle
        };

        // HiveDatabaseService'e ekle
        await HiveDatabaseService.addKatildigimDava(widget.userEmail!, katildigimDavaData);
        
        print('✅ Katıldığım Davalar\'a eklendi: $davaId');
        
      } else {
        print('⚠️ Dava ID veya userEmail bulunamadı, Katıldığım Davalar\'a eklenemedi');
      }
    } catch (e) {
      print('❌ Katıldığım Davalar\'a eklenirken hata: $e');
    }
  }

  void _onBegeniInvitation(Map<String, dynamic> davet) {
    setState(() {
      if (davet['userDisliked'] == true) {
        davet['begenmemeSayisi'] = (davet['begenmemeSayisi'] ?? 0) - 1;
        davet['userDisliked'] = false;
      }
      
      if (davet['userLiked'] == true) {
        davet['begeniSayisi'] = (davet['begeniSayisi'] ?? 0) - 1;
        davet['userLiked'] = false;
      } else {
        davet['begeniSayisi'] = (davet['begeniSayisi'] ?? 0) + 1;
        davet['userLiked'] = true;
      }
    });
    
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      HiveDatabaseService.addInvitation(widget.userEmail!, davet);
    }
    
    // Seyir defterindeki paylaşımı da güncelle
    try {
      final String? davaId = (davet['davaId'] ?? davet['id'])?.toString();
      if (davaId != null && davaId.isNotEmpty) {
        final postId = 'dava_share_$davaId';
        final existing = HiveDatabaseService.getHomeFeedPostById(postId, userEmail: widget.userEmail);
        
        if (existing != null) {
          final davaProvider = Provider.of<DavaProvider>(context, listen: false);
          final updatedPost = Map<String, dynamic>.from(existing);
          
          updatedPost['payload']['begeniSayisi'] = davet['begeniSayisi'];
          updatedPost['payload']['begenmemeSayisi'] = davet['begenmemeSayisi'];
          updatedPost['payload']['userLiked'] = davet['userLiked'];
          updatedPost['payload']['userDisliked'] = davet['userDisliked'];
          
          davaProvider.updateHomeFeedPost(postId, updatedPost);
        }
      }
    } catch (e) {
      print('⚠️ Seyir defteri güncelleme hatası: $e');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('👍 Davet beğenildi: ${davet['davaAdi']}'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onBegenmemeInvitation(Map<String, dynamic> davet) {
    setState(() {
      if (davet['userLiked'] == true) {
        davet['begeniSayisi'] = (davet['begeniSayisi'] ?? 0) - 1;
        davet['userLiked'] = false;
      }
      
      if (davet['userDisliked'] == true) {
        davet['begenmemeSayisi'] = (davet['begenmemeSayisi'] ?? 0) - 1;
        davet['userDisliked'] = false;
      } else {
        davet['begenmemeSayisi'] = (davet['begenmemeSayisi'] ?? 0) + 1;
        davet['userDisliked'] = true;
      }
    });
    
    // Veri tabanında da güncelle (invitation)
    HiveDatabaseService.addInvitation(widget.userEmail!, davet);
    
    // Seyir defterindeki paylaşımı da güncelle
    try {
      final String? davaId = (davet['davaId'] ?? davet['id'])?.toString();
      if (davaId != null && davaId.isNotEmpty) {
        final postId = 'dava_share_$davaId';
        final existing = HiveDatabaseService.getHomeFeedPostById(postId, userEmail: widget.userEmail);
        
        if (existing != null) {
          final davaProvider = Provider.of<DavaProvider>(context, listen: false);
          final updatedPost = Map<String, dynamic>.from(existing);
          
          updatedPost['payload']['begeniSayisi'] = davet['begeniSayisi'];
          updatedPost['payload']['begenmemeSayisi'] = davet['begenmemeSayisi'];
          updatedPost['payload']['userLiked'] = davet['userLiked'];
          updatedPost['payload']['userDisliked'] = davet['userDisliked'];
          
          davaProvider.updateHomeFeedPost(postId, updatedPost);
        }
      }
    } catch (e) {
      print('⚠️ Seyir defteri güncelleme hatası: $e');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('👎 Davet beğenilmedi: ${davet['davaAdi']}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: OneFriendPhoneBellMenu(
                userEmail: widget.userEmail,
                isBildirimlerPage: false,
              ),
            ),
            
            // Başlık ve İstatistikler
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        MdiIcons.phoneClassic,
                        size: 28,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'GELEN DAVETLER',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const Spacer(),
                      // Yenile butonu
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: const Color(0xFF10B981),
                          size: 24,
                        ),
                        onPressed: _refreshInvitations,
                        tooltip: 'Davetleri Yenile',
                      ),
                      const SizedBox(width: 8),
                      // Toplam davet sayısı
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${davetler.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // İçerik
            Expanded(
              child: davetler.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5), // Çok açık yeşil
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.inbox_outlined,
                            size: 80,
                            color: const Color(0xFF10B981).withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Henüz davet almadınız',
                          style: TextStyle(
                            fontSize: 20,
                            color: const Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dava davetleri burada görünecek',
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _refreshInvitations();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      itemCount: davetler.length,
                      itemBuilder: (context, index) {
                        final davet = davetler[index];
                        
                        return ModernInvitationCard(
                          userEmail: davet['userEmail'] ?? '',
                          displayName: davet['displayName'] ?? '',
                          davaAdi: davet['davaAdi'] ?? davet['haykirAdi'] ?? '',
                          davaKategori: davet['davaKategori'] ?? '',
                          davaKonusu: davet['davaKonusu'] ?? davet['slogan'] ?? '',
                          davaci: davet['davaci'] ?? '',
                          davali: davet['davali'] ?? '',
                          davaId: (davet['davaId'] ?? davet['id'])?.toString(),
                          isOpened: davet['isOpened'] ?? false,
                          yorumSayisi: davet['yorumSayisi'] ?? 0,
                          retweetSayisi: davet['retweetSayisi'] ?? 0,
                          begeniSayisi: davet['begeniSayisi'] ?? 0,
                          begenmemeSayisi: davet['begenmemeSayisi'] ?? 0,
                          userLiked: davet['userLiked'] ?? false,
                          userDisliked: davet['userDisliked'] ?? false,
                          userRetweeted: davet['userRetweeted'] ?? false,
                          yorumlar: _safeCastYorumlar(davet['yorumlar']),
                          onSave: () => _onSaveInvitation(davet),
                          onOpen: () => _onOpenInvitation(davet),
                          onDelilEkle: () => _onDelilEkleInvitation(davet),
                          onYorum: (yorumMetni,
                                  {parentCommentId, bool isGizliTanik = false}) =>
                              _onYorumInvitation(
                                davet,
                                yorumMetni,
                                parentCommentId: parentCommentId,
                                isGizliTanik: isGizliTanik,
                              ),
                          onRetweet: () => _onRetweetInvitation(davet),
                          onBegeni: () => _onBegeniInvitation(davet),
                          onBegenmeme: () => _onBegenmemeInvitation(davet),
                          // ✅ HAYKIR desteği için yeni parametreler
                          type: davet['type'],
                          slogan: davet['slogan'],
                          direme: davet['direme'],
                          detaylar: davet['detaylar'],
                          haykirId: (davet['haykirId'] ?? davet['davaId'] ?? davet['id'])?.toString(),
                        );
                      },
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}


class _DavetEtListesiSayfasiState extends State<DavetEtListesiSayfasi> {
  // Örnek dava verileri
  final List<Map<String, dynamic>> davalar = [
    {
      'userEmail': 'avukat1@example.com',
      'displayName': 'Ahmet Yılmaz',
      'davaAdi': 'İş Hukuku Davası',
      'davaKategori': 'İş Hukuku',
      'davaKonusu': 'Haksız yere işten çıkarılma davası. Çalışanın 5 yıllık hizmet süresi boyunca hiçbir disiplin cezası almamış olmasına rağmen, işveren tarafından geçersiz gerekçelerle işten çıkarılması durumu.',
      'isOpened': false,
      'yorumSayisi': 12,
      'retweetSayisi': 5,
      'begeniSayisi': 23,
      'begenmemeSayisi': 2,
      'userLiked': false,
      'userDisliked': false,
      'yorumlar': [
        {
          'id': 1,
          'userName': 'Av. Mehmet Kaya',
          'userEmail': 'mehmet@example.com',
          'yorum': 'Bu dava için gerekli delilleri toplamak önemli. İş sözleşmesi ve çalışma belgeleri mutlaka sunulmalı.',
          'tarih': '2024-01-15 14:30',
          'begeniSayisi': 5,
        },
        {
          'id': 2,
          'userName': 'Av. Fatma Demir',
          'userEmail': 'fatma@example.com',
          'yorum': 'İş Kanunu\'nun 20. maddesi bu durumda çok net. İşverenin geçerli gerekçe göstermesi gerekiyor.',
          'tarih': '2024-01-15 15:45',
          'begeniSayisi': 3,
        },
      ],
    },
  ];
  String? _currentUserEmail;
  String _currentUserDisplayName = 'Demo Kullanıcı';

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
  }

  void _initializeCurrentUser() {
    final email = widget.userEmail;
    if (email == null || email.isEmpty) {
      _currentUserEmail = null;
      _currentUserDisplayName = 'Demo Kullanıcı';
      return;
    }

    try {
      final user = HiveDatabaseService.getRegistrationByEmail(email);
      _currentUserEmail = email;
      _currentUserDisplayName = user?.judgeName ?? email.split('@').first;
    } catch (_) {
      _currentUserEmail = email;
      _currentUserDisplayName = email.split('@').first;
    }
  }

  void _onSave(int index) {
    setState(() {
      davalar[index]['isOpened'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Dava kaydedildi: ${davalar[index]['davaAdi']}'),
        backgroundColor: Colors.greenAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onOpen(int index) {
    setState(() {
      davalar[index]['isOpened'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚖️ Dava başlatıldı: ${davalar[index]['davaAdi']}'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onDelilEkle(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 Delil ekleme sayfası açılıyor: ${davalar[index]['davaAdi']}'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onYorum(
    int index,
    String yorumMetni, {
    String? parentCommentId,
    bool isGizliTanik = false,
  }) async {
    final mevcutYorumlar =
        List<Map<String, dynamic>>.from(davalar[index]['yorumlar'] ?? []);
    final gizliTanikSayisi = CommentUtils.countAllComments(
      mevcutYorumlar
          .where((comment) => comment['isGizliTanik'] == true)
          .toList(),
    );

    final currentUserEmail =
        _currentUserEmail ?? widget.userEmail ?? 'demo@whoboom.com';
    final currentUserName = isGizliTanik
        ? HiveDatabaseService.gizliTanikDisplayName
        : _currentUserDisplayName;

    final yeniYorum = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'userName': currentUserName,
      'userEmail': currentUserEmail,
      'yorum': yorumMetni,
      'tarih': DateTime.now().toString().substring(0, 19),
      'begeniSayisi': 0,
      'isGizliTanik': isGizliTanik,
      'parentId': parentCommentId,
      'replies': <Map<String, dynamic>>[],
    };

    setState(() {
      davalar[index]['yorumlar'] =
          CommentUtils.addComment(mevcutYorumlar, yeniYorum);
      davalar[index]['yorumSayisi'] =
          CommentUtils.countAllComments(davalar[index]['yorumlar']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💬 Yorum eklendi: ${davalar[index]['davaAdi']}'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onRetweet(int index) {
    setState(() {
      // Toggle retweet mantığı
      if (davalar[index]['userRetweeted'] == true) {
        // Retweet kaldır
        davalar[index]['retweetSayisi'] = (davalar[index]['retweetSayisi'] ?? 1) - 1;
        davalar[index]['userRetweeted'] = false;
      } else {
        // Retweet ekle
        davalar[index]['retweetSayisi'] = (davalar[index]['retweetSayisi'] ?? 0) + 1;
        davalar[index]['userRetweeted'] = true;
      }
    });
    
    // Not: Bu örnek sayfa için veritabanı güncellemesi yapılmıyor
    
    String message = davalar[index]['userRetweeted'] == true
        ? '🔄 Dava paylaşıldı: ${davalar[index]['davaAdi']}'
        : '🔄 Paylaşım kaldırıldı: ${davalar[index]['davaAdi']}';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onBegeni(int index) {
    setState(() {
      // Eğer daha önce beğenmeme seçilmişse, beğenmeme sayısını azalt
      if (davalar[index]['userDisliked'] == true) {
        davalar[index]['begenmemeSayisi'] = (davalar[index]['begenmemeSayisi'] ?? 1) - 1;
        davalar[index]['userDisliked'] = false;
      }

      // Eğer daha önce beğeni seçilmişse, beğeni sayısını azalt (iptal et)
      if (davalar[index]['userLiked'] == true) {
        davalar[index]['begeniSayisi'] = (davalar[index]['begeniSayisi'] ?? 1) - 1;
        davalar[index]['userLiked'] = false;
      } else {
        // Yeni beğeni ekle
        davalar[index]['begeniSayisi'] = (davalar[index]['begeniSayisi'] ?? 0) + 1;
        davalar[index]['userLiked'] = true;
      }
    });
    
    // Not: Bu örnek sayfa için veritabanı güncellemesi yapılmıyor

    String message = davalar[index]['userLiked'] == true
        ? '👍 Beğenildi: ${davalar[index]['davaAdi']}'
        : '👍 Beğeni kaldırıldı: ${davalar[index]['davaAdi']}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onBegenmeme(int index) {
    setState(() {
      // Eğer daha önce beğeni seçilmişse, beğeni sayısını azalt
      if (davalar[index]['userLiked'] == true) {
        davalar[index]['begeniSayisi'] = (davalar[index]['begeniSayisi'] ?? 1) - 1;
        davalar[index]['userLiked'] = false;
      }

      // Eğer daha önce beğenmeme seçilmişse, beğenmeme sayısını azalt (iptal et)
      if (davalar[index]['userDisliked'] == true) {
        davalar[index]['begenmemeSayisi'] = (davalar[index]['begenmemeSayisi'] ?? 1) - 1;
        davalar[index]['userDisliked'] = false;
      } else {
        // Yeni beğenmeme ekle
        davalar[index]['begenmemeSayisi'] = (davalar[index]['begenmemeSayisi'] ?? 0) + 1;
        davalar[index]['userDisliked'] = true;
      }
    });
    
    // Not: Bu örnek sayfa için veritabanı güncellemesi yapılmıyor

    String message = davalar[index]['userDisliked'] == true
        ? '👎 Beğenilmedi: ${davalar[index]['davaAdi']}'
        : '👎 Beğenmeme kaldırıldı: ${davalar[index]['davaAdi']}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DAVA DESTEK GELEN  DAVETLERİ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[50]!,
              Colors.white,
            ],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: davalar.length,
          itemBuilder: (context, index) {
            final dava = davalar[index];
            return ModernDavaCard(
              userEmail: dava['userEmail'],
              displayName: dava['displayName'],
              davaAdi: dava['davaAdi'],
              davaKategori: dava['davaKategori'],
              davaKonusu: dava['davaKonusu'],
              davaci: dava['davaci'] ?? '',
              davaId: (dava['davaId'] ?? dava['id'])?.toString(),
              isOpened: dava['isOpened'],
              yorumSayisi: dava['yorumSayisi'],
              retweetSayisi: dava['retweetSayisi'],
              begeniSayisi: dava['begeniSayisi'],
              begenmemeSayisi: dava['begenmemeSayisi'],
              userLiked: dava['userLiked'] ?? false,
              userDisliked: dava['userDisliked'] ?? false,
              userRetweeted: dava['userRetweeted'] ?? false,
              yorumlar: dava['yorumlar'] ?? [],
              onSave: () => _onSave(index),
              onOpen: () => _onOpen(index),
              onDelilEkle: () => _onDelilEkle(index),
              onYorum: (yorumMetni,
                      {parentCommentId, bool isGizliTanik = false}) =>
                  _onYorum(
                    index,
                    yorumMetni,
                    parentCommentId: parentCommentId,
                    isGizliTanik: isGizliTanik,
                  ),
              onRetweet: () => _onRetweet(index),
              onBegeni: () => _onBegeni(index),
              onBegenmeme: () => _onBegenmeme(index),
            );
          },
        ),
      ),
    );
  }
}

