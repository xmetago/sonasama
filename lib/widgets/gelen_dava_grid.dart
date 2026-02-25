import 'package:flutter/material.dart';

import '../services/hive_database_service.dart';
import 'ilgililerin_seyir_defteri_widgeti.dart';

/// Gelen davalar listesini grid yapısında sunar ve her dava için izleme aksiyonu sağlar.
class GelenDavaGrid extends StatefulWidget {
  /// İzlenecek davaların hangi kullanıcıya göre filtreleneceğini belirtir.
  /// Null olması durumunda sistemdeki tüm açılmış davalar kullanılır.
  final String? userEmail;

  const GelenDavaGrid({super.key, this.userEmail});

  @override
  State<GelenDavaGrid> createState() => _GelenDavaGridState();
}

class _GelenDavaGridState extends State<GelenDavaGrid> {
  late Future<List<Map<String, dynamic>>> _davalarFuture;

  @override
  void initState() {
    super.initState();
    _davalarFuture = _fetchDavalar();
  }

  /// Veritabanından ilgili davaları yükler.
  Future<List<Map<String, dynamic>>> _fetchDavalar() async {
    return Future<List<Map<String, dynamic>>>.microtask(() {
      if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
        return HiveDatabaseService.getIncomingDavalar(widget.userEmail!);
      }
      return HiveDatabaseService.getOpenedDavalar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _davalarFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _EmptyState(
            title: 'Veriler yüklenemedi',
            message: 'Lütfen daha sonra tekrar deneyiniz.',
            icon: Icons.error_outline,
          );
        }

        final davalar = snapshot.data ?? <Map<String, dynamic>>[];
        if (davalar.isEmpty) {
          return const _EmptyState(
            title: 'Dava bulunamadı',
            message: 'Şu anda izlenebilecek aktif bir dava bulunmuyor.',
            icon: Icons.inbox_outlined,
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: davalar.length,
          itemBuilder: (context, index) {
            final dava = davalar[index];
            return GelenDavaIconTile(
              dava: dava,
            );
          },
        );
      },
    );
  }
}

/// Davanın kısa bilgilerini ve izleme aksiyonunu gösteren grid elemanı.
class GelenDavaIconTile extends StatelessWidget {
  final Map<String, dynamic> dava;

  const GelenDavaIconTile({
    super.key,
    required this.dava,
  });

  @override
  Widget build(BuildContext context) {
    final caseName = _extractCaseName();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF34dfae).withOpacity(0.15),
            child: const Icon(
              Icons.cases_outlined,
              color: Color(0xFF34dfae),
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            caseName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF34dfae),
                side: const BorderSide(color: Color(0xFF34dfae)),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _openSeyirDefteri(context, caseName),
              child: const Text(
                'İzle',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dava adını veriden güvenli şekilde çeker.
  String _extractCaseName() {
    final rawName = (dava['davaAdi'] ?? dava['adi'] ?? '').toString().trim();
    if (rawName.isNotEmpty) {
      return rawName;
    }
    return 'Dava adı bulunamadı';
  }

  /// Seyir defteri widgetını alt sayfada açar.
  Future<void> _openSeyirDefteri(BuildContext context, String caseName) async {
    final openedAtRaw = (dava['openedAt'] ?? dava['createdAt'])?.toString();
    DateTime? openedAt;
    if (openedAtRaw != null && openedAtRaw.isNotEmpty) {
      openedAt = DateTime.tryParse(openedAtRaw);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (sheetContext, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: SingleChildScrollView(
                controller: scrollController,
                child: IlgililerinSeyirDefteriWidgeti(
                  davaId: (dava['id'] ?? '').toString(),
                  userEmail: dava['userEmail']?.toString(),
                  davaAdi: caseName,
                  davaci: dava['davaci']?.toString(),
                  davali: dava['davali']?.toString(),
                  kategori: dava['kategori']?.toString(),
                  davaKonusu: dava['davaKonusu']?.toString(),
                  openedAt: openedAt,
                  onClose: () => Navigator.of(modalContext).maybePop(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Veri olmadığında gösterilecek bilgi kartı.
class _EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 36,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

