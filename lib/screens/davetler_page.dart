import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/hive_database_service.dart';
import '../providers/dava_provider.dart';
import '../widgets/modern_invitation_card.dart';
import '../widgets/comment_section.dart';
import '../utils/comment_utils.dart';
import './delil_listesi_ekrani.dart';
import '../widgets/common_header_widgets.dart';
import './haykir_page.dart'; // ✅ HAYKIR sayfasına yönlendirme için

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
          ? 'GizliTanık-${gizliTanikSayisi + 1}'
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

class DavetCard extends StatelessWidget {
  final Map<String, dynamic> davet;
  final VoidCallback onMarkAsRead;

  const DavetCard({
    super.key,
    required this.davet,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = davet['isRead'] ?? false;
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isRead ? Colors.grey[50] : Colors.blue[50],
          border: isRead ? null : Border.all(color: Colors.blue[200]!, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      davet['groupName'] ?? 'Davet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Dava Bilgileri
              Text(
                davet['davaAdi'] ?? 'Dava Adı Belirtilmemiş',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              if (davet['kategori'] != null && davet['kategori'].toString().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.category, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Kategori: ${davet['kategori']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              if (davet['davaKonusu'] != null && davet['davaKonusu'].toString().isNotEmpty) ...[
                const Text(
                  'Dava Konusu:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  davet['davaKonusu'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Davacı ve Davalı
              if (davet['davaci'] != null && davet['davaci'].toString().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Davacı: ${davet['davaci']}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              
              if (davet['davali'] != null && davet['davali'].toString().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      'Davalı: ${davet['davali']}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Tarih
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(davet['invitedAt']),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (!isRead)
                    TextButton(
                      onPressed: onMarkAsRead,
                      child: const Text('Okundu İşaretle'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Tarih belirtilmemiş';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Geçersiz tarih';
    }
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
        ? 'GizliTanık-${gizliTanikSayisi + 1}'
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

class ModernDavaCard extends StatefulWidget {
  final String userEmail;
  final String displayName;
  final String davaAdi;
  final String davaKategori;
  final String davaKonusu;
  final String? davaci; // Davacı alanı eklendi
  final String? davali;
  final String? davaId;
  final bool isOpened;
  final int yorumSayisi;
  final int retweetSayisi;
  final int begeniSayisi;
  final int begenmemeSayisi;
  final bool userLiked;
  final bool userDisliked;
  final bool? userRetweeted; // Retweet state eklendi
  final List<Map<String, dynamic>> yorumlar;
  final VoidCallback onSave;
  final VoidCallback onOpen;
  final VoidCallback onDelilEkle;
  final CommentSubmitCallback? onYorum;
  final VoidCallback? onRetweet;
  final VoidCallback? onBegeni;
  final VoidCallback? onBegenmeme;

  const ModernDavaCard({
    super.key,
    required this.userEmail,
    required this.displayName,
    required this.davaAdi,
    required this.davaKategori,
    required this.davaKonusu,
    this.davaci,
    this.davali,
    this.davaId,
    required this.isOpened,
    required this.yorumSayisi,
    required this.retweetSayisi,
    required this.begeniSayisi,
    required this.begenmemeSayisi,
    required this.userLiked,
    required this.userDisliked,
    this.userRetweeted,
    required this.yorumlar,
    required this.onSave,
    required this.onOpen,
    required this.onDelilEkle,
    this.onYorum,
    this.onRetweet,
    this.onBegeni,
    this.onBegenmeme,
  });

  @override
  State<ModernDavaCard> createState() => _ModernDavaCardState();
}

class _ModernDavaCardState extends State<ModernDavaCard> {
  bool isExpanded = false;
  bool isSaved = false;
  bool isLiked = false;
  bool isDisliked = false;
  bool isRetweeted = false;
  final GlobalKey<CommentSectionState> _commentSectionKey =
      GlobalKey<CommentSectionState>();

  @override
  void initState() {
    super.initState();
    // Widget'tan gelen state'leri local state'e kopyala
    isLiked = widget.userLiked;
    isDisliked = widget.userDisliked;
    isRetweeted = widget.userRetweeted ?? false;
  }

  void _focusComments() {
    setState(() => isExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commentSectionKey.currentState?.focusInput();
    });
  }

  Widget _buildInfoRow(String label, String value, {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required String count,
    required Color color,
    required VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? Border.all(color: color, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? color : color.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? color : color.withOpacity(0.7),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showCommentDialog() {
    final TextEditingController commentController = TextEditingController();
    bool isGizliTanik = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Builder(
                    builder: (context) {
                      // Kullanıcının profil resmi URL'sini Hive'dan al
                      final settings = HiveDatabaseService.getSettings(widget.userEmail);
                      final profileImageUrl = settings?.profileImageUrl;
                      
                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl) as ImageProvider<Object>
                            : const AssetImage('lib/icons/07_profil_picture_davaci.png') as ImageProvider<Object>,
                        onBackgroundImageError: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? (exception, stackTrace) {
                                // Resim yüklenemezse varsayılan ikonu göster
                              }
                            : null,
                        child: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? null
                            : const Icon(Icons.account_circle, size: 32, color: Colors.grey),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yorum Yap',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Dava: ${widget.davaAdi}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: commentController,
                      maxLines: 4,
                      maxLength: 280,
                      onChanged: (value) {
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        hintText: 'Davanız hakkında yorumunuzu yazın...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        counterText: '',
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${commentController.text.length}/280',
                        style: TextStyle(
                          fontSize: 12,
                          color: commentController.text.length > 250
                              ? Colors.orange
                              : Colors.grey[600],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('📷 Fotoğraf ekleme özelliği yakında!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: Icon(Icons.photo_camera, color: Colors.green[600]),
                            tooltip: 'Fotoğraf Ekle',
                          ),
                        ],
                      ),
                    ],
                    ),
                    const SizedBox(height: 16),
                    // Gizli Tanık checkbox'ı
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isGizliTanik,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                isGizliTanik = value ?? false;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  isGizliTanik = !isGizliTanik;
                                });
                              },
                              child: const Text(
                                'Gizli Tanık olarak yorum yap',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isGizliTanik) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Yorumunuz "GizliTanık-X" adıyla görünecektir.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'İptal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: commentController.text.trim().isEmpty ? null : () async {
                    if (commentController.text.trim().isNotEmpty) {
                      final yorumMetni = commentController.text.trim();
                      
                      // Gizli tanık seçildiyse, yorumu HiveDatabaseService ile kaydet
                      if (widget.davaId != null && widget.userEmail.isNotEmpty && isGizliTanik) {
                        await HiveDatabaseService.addDavaComment(
                          widget.davaId!,
                          widget.userEmail,
                          yorumMetni: yorumMetni,
                          isGizliTanik: true,
                        );
                      }
                      
                      widget.onYorum?.call(yorumMetni);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('💬 Yorum eklendi: "$yorumMetni"${isGizliTanik ? ' (Gizli Tanık olarak)' : ''}'),
                          backgroundColor: Colors.green[600],
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ],
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Builder(
                  builder: (context) {
                    // Kullanıcının profil resmi URL'sini Hive'dan al
                    final settings = HiveDatabaseService.getSettings(widget.userEmail);
                    final profileImageUrl = settings?.profileImageUrl;
                    
                    return CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl) as ImageProvider<Object>
                          : const AssetImage('lib/icons/07_profil_picture_davaci.png') as ImageProvider<Object>,
                      onBackgroundImageError: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? (exception, stackTrace) {
                              // Resim yüklenemezse varsayılan ikonu göster
                            }
                          : null,
                      child: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? null
                          : const Icon(Icons.account_circle, size: 40, color: Colors.grey),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Davacı: ${widget.davaci?.isNotEmpty == true ? widget.davaci : widget.displayName}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() => isExpanded = !isExpanded);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Dava Bilgileri
            _buildInfoRow("Dava Adı", widget.davaAdi, bold: true),
            if (widget.davaKategori.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildInfoRow("Kategori", widget.davaKategori),
            ],
            if (widget.davali != null && widget.davali!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildInfoRow("Davalı", widget.davali!),
            ],

            if (isExpanded) ...[
              const SizedBox(height: 12),
              _buildInfoRow("Dava Konusu", widget.davaKonusu),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  _buildActionButton(
                    text: "Arşivle",
                    icon: isSaved ? Icons.check_circle : Icons.check_circle_outline,
                    onPressed: () {
                      setState(() {
                        isSaved = !isSaved;
                      });
                      widget.onSave();
                    },
                    color: isSaved ? Colors.green : Colors.grey[600]!,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    text: "İzle",
                    icon: Icons.open_in_new,
                    onPressed: widget.onOpen,
                    color: Colors.green[600]!,
                  ),


                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 8),
                  _buildActionButton(
                    text: "Delil Listesine Gözat",
                    icon: Icons.account_tree_outlined,
                    onPressed: () {
                      final id = widget.davaId;
                      if (id == null || id.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bu dava için davaId bulunamadı.')),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DelilListesiEkrani(davaId: id),
                        ),
                      );
                    },
                    color: Colors.grey[600]!,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Engagement buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEngagementButton(
                  icon: Icons.comment_outlined,
                  count: widget.yorumSayisi.toString(),
                  color: Colors.blue,
                  onPressed: _focusComments,
                ),
                _buildEngagementButton(
                  icon: Icons.repeat,
                  count: widget.retweetSayisi.toString(),
                  color: Colors.green,
                  onPressed: () {
                    setState(() {
                      isRetweeted = !isRetweeted;
                    });
                    widget.onRetweet?.call();
                  },
                  isActive: isRetweeted || (widget.userRetweeted ?? false),
                ),
                _buildEngagementButton(
                  icon: Icons.thumb_up_outlined,
                  count: widget.begeniSayisi.toString(),
                  color: Colors.orange,
                  onPressed: () {
                    setState(() {
                      isLiked = !isLiked;
                      if (isLiked && isDisliked) {
                        isDisliked = false;
                      }
                    });
                    widget.onBegeni?.call();
                  },
                  isActive: isLiked,
                ),
                _buildEngagementButton(
                  icon: Icons.thumb_down_outlined,
                  count: widget.begenmemeSayisi.toString(),
                  color: Colors.red,
                  onPressed: () {
                    setState(() {
                      isDisliked = !isDisliked;
                      if (isDisliked && isLiked) {
                        isLiked = false;
                      }
                    });
                    widget.onBegenmeme?.call();
                  },
                  isActive: isDisliked,
                ),
              ],
            ),

            const SizedBox(height: 16),
            CommentSection(
              key: _commentSectionKey,
              comments: widget.yorumlar,
              onSubmit: widget.onYorum == null
                  ? null
                  : (text, {parentCommentId, bool isGizliTanik = false}) async {
                      await widget.onYorum!(
                        text,
                        parentCommentId: parentCommentId,
                        isGizliTanik: isGizliTanik,
                      );
                    },
              currentUserName: widget.displayName,
            ),
          ],
        ),
      ),
    );
  }
}

