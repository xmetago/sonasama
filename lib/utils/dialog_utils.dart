import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/dava.dart' as dava_model;
import '../services/hive_database_service.dart';
import '../screens/dava_ac_page.dart';

// Uygulama yeşil tonu paleti (#169371 ana yeşil)
const _kPrimaryDark = Color(0xFF169371);   // Ana yeşil
const _kPrimaryLight = Color(0xFF059669);  // Gradient için açık yeşil
const _kAccent = Color(0xFF0D7A5A);        // Vurgu (koyu yeşil)
const _kCardBg = Color(0xFFE8F5F1);        // Açık yeşil zemin (E0F5EF benzeri)
const _kTextPrimary = Color(0xFF1E293B);
const _kTextSecondary = Color(0xFF64748B);

/// Kaydedilen Davalar dialog'unu gösteren global utility fonksiyonu
Future<void> showSavedDavalarDialog(BuildContext context, String userEmail) async {
  final List<Map<String, dynamic>> savedDavalarMaps = HiveDatabaseService.getSavedDavalar();
  final List<dava_model.Dava> savedDavalar = savedDavalarMaps.map((map) => dava_model.Dava.fromMap(map)).toList();

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _kPrimaryDark.withOpacity(0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header — mahkeme teması
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kPrimaryDark, _kPrimaryLight],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dava Düzenle',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${savedDavalar.length} dava ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.9), size: 22),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: savedDavalar.isEmpty
                    ? _buildEmptyState()
                    : _buildSavedDavalarList(context, savedDavalar, userEmail),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildEmptyState() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kPrimaryDark.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.gavel_rounded,
            size: 56,
            color: _kTextSecondary.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Henüz dava kaydedilmedi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Dava açtığınızda burada görünecek',
          style: TextStyle(fontSize: 14, color: _kTextSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget _buildSavedDavalarList(BuildContext context, List<dava_model.Dava> savedDavalar, String userEmail) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    child: ListView.builder(
      itemCount: savedDavalar.length,
      itemBuilder: (context, index) {
        final dava = savedDavalar[index];
        return Slidable(
          key: ValueKey(dava.id),
          groupTag: 'saved_davalar',
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.35,
            children: [
              SlidableAction(
                onPressed: (_) => _showDeleteConfirmation(context, dava, userEmail),
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                icon: Icons.delete_rounded,
                label: 'Sil',
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.35,
            children: [
              SlidableAction(
                onPressed: (_) => _navigateToEdit(context, dava, userEmail),
                backgroundColor: _kPrimaryDark,
                foregroundColor: Colors.white,
                icon: Icons.edit_rounded,
                label: 'Düzenle',
              ),
            ],
          ),
          child: _buildDavaCard(context, dava, userEmail, index),
        );
      },
    ),
  );
}

void _navigateToEdit(BuildContext context, dava_model.Dava dava, String userEmail) {
  Navigator.of(context).pop();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => DavaAcPage(
        userEmail: userEmail,
        editDava: dava,
      ),
    ),
  );
}

/// Sıra göstergesi: 1. dava = 1 tokmak, 2. dava = 2 tokmak ...
Widget _buildGavelRow(int count) {
  final int n = count.clamp(1, 10);
  final double size = n > 5 ? 12 : 16;
  final double spacing = n > 5 ? 2 : 4;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      n,
      (i) => Padding(
        padding: EdgeInsets.only(right: i < n - 1 ? spacing : 0),
        child: Icon(Icons.save_outlined, size: size, color: _kAccent),
      ),
    ),
  );
}

Widget _buildDavaCard(BuildContext context, dava_model.Dava dava, String userEmail, int index) {
  final int sira = index + 1;
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: _kCardBg,
      border: Border.all(color: _kPrimaryDark.withOpacity(0.08), width: 1),
      boxShadow: [
        BoxShadow(
          color: _kPrimaryDark.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DavaAcPage(
                userEmail: userEmail,
                editDava: dava,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Sıra tokmağı + dava adı (sağa kaydır → Düzenle)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _buildGavelRow(sira),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dava.davaAdi.isNotEmpty ? dava.davaAdi : 'Dava Adı Belirtilmemiş',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sağa kaydır --> : Sil \n Sola kaydır: <--Düzenle',
                          style: TextStyle(
                            fontSize: 11,
                            color: _kTextSecondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (dava.kategori.isNotEmpty || dava.davaci.isNotEmpty || dava.davali.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: _kPrimaryDark.withOpacity(0.06),
                ),
                const SizedBox(height: 10),
                if (dava.kategori.isNotEmpty) _buildDetailRow(Icons.category_outlined, 'Kategori', dava.kategori),
                if (dava.davaci.isNotEmpty) _buildDetailRow(Icons.person_outline_rounded, 'Davacı', dava.davaci),
                if (dava.davali.isNotEmpty) _buildDetailRow(Icons.person_outline_rounded, 'Davalı', dava.davali),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildCardIconButton({
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 20),
      ),
    ),
  );
}

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _kTextSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _kTextPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _showDeleteConfirmation(BuildContext context, dava_model.Dava dava, String userEmail) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _kPrimaryDark.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                'Dava Silinecek',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bu davayı silmek istediğinizden emin misiniz?\nBu işlem geri alınamaz.',
                style: TextStyle(fontSize: 14, color: _kTextSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: _kTextSecondary.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('İptal', style: TextStyle(color: _kTextSecondary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HiveDatabaseService.deleteSavedDava(dava.id);
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        showSavedDavalarDialog(context, userEmail);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Sil'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
