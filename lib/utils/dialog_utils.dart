import 'package:flutter/material.dart';
import '../models/dava.dart' as dava_model;
import '../services/hive_database_service.dart';
import '../screens/dava_ac_page.dart'; // DavaAcPage için import eklendi

/// Kaydedilen Davalar dialog'unu gösteren global utility fonksiyonu
/// Bu fonksiyon tüm sayfalarda kullanılabilir
Future<void> showSavedDavalarDialog(BuildContext context, String userEmail) async {
  // Kaydedilen davaları veritabanından yükle
  final List<Map<String, dynamic>> savedDavalarMaps = HiveDatabaseService.getSavedDavalar();
  final List<dava_model.Dava> savedDavalar = savedDavalarMaps.map((map) => dava_model.Dava.fromMap(map)).toList();

  if (!context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
                             // Header Section
               Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   borderRadius: const BorderRadius.only(
                     topLeft: Radius.circular(20),
                     topRight: Radius.circular(20),
                   ),
                   color: Colors.green.shade600,
                 ),
                 child: Row(
                   children: [
                     // Icon
                     Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.2),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: const Icon(
                         Icons.check_circle,
                         color: Colors.white,
                         size: 24,
                       ),
                     ),
                     const SizedBox(width: 16),
                     // Title
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text(
                             'Kaydedilen Davalar',
                             style: TextStyle(
                               fontSize: 20,
                               fontWeight: FontWeight.bold,
                               color: Colors.white,
                             ),
                           ),
                           const SizedBox(height: 4),
                           Text(
                             '${savedDavalar.length} dava kaydedildi',
                             style: TextStyle(
                               fontSize: 14,
                               color: Colors.white.withOpacity(0.9),
                             ),
                           ),
                         ],
                       ),
                     ),
                     // Close Button
                     IconButton(
                       onPressed: () => Navigator.of(context).pop(),
                       icon: const Icon(
                         Icons.close,
                         color: Colors.white,
                         size: 20,
                       ),
                     ),
                   ],
                 ),
               ),
              
              // Content Section
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
     padding: const EdgeInsets.all(32),
     child: Column(
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
         // Empty State Icon
         Container(
           padding: const EdgeInsets.all(20),
           decoration: BoxDecoration(
             color: Colors.grey.withOpacity(0.1),
             shape: BoxShape.circle,
           ),
           child: Icon(
             Icons.folder_open_outlined,
             size: 48,
             color: Colors.grey.shade400,
           ),
         ),
         const SizedBox(height: 20),
         
         // Empty State Text
         Text(
           'Henüz dava kaydedilmedi',
           style: TextStyle(
             fontSize: 18,
             fontWeight: FontWeight.bold,
             color: Colors.grey.shade700,
           ),
           textAlign: TextAlign.center,
         ),
         const SizedBox(height: 8),
         
         Text(
           'Dava açtığınızda burada görünecek',
           style: TextStyle(
             fontSize: 14,
             color: Colors.grey.shade600,
           ),
           textAlign: TextAlign.center,
         ),
       ],
     ),
   );
 }

Widget _buildSavedDavalarList(BuildContext context, List<dava_model.Dava> savedDavalar, String userEmail) {
  return Container(
    padding: const EdgeInsets.all(16),
    child: ListView.builder(
      itemCount: savedDavalar.length,
      itemBuilder: (context, index) {
        final dava = savedDavalar[index];
        return _buildDavaCard(context, dava, userEmail, index);
      },
    ),
  );
}

 Widget _buildDavaCard(BuildContext context, dava_model.Dava dava, String userEmail, int index) {
   return Container(
     margin: const EdgeInsets.only(bottom: 12),
     decoration: BoxDecoration(
       borderRadius: BorderRadius.circular(12),
       color: Colors.white,
       border: Border.all(color: Colors.grey.withOpacity(0.2)),
       boxShadow: [
         BoxShadow(
           color: Colors.black.withOpacity(0.03),
           blurRadius: 8,
           offset: const Offset(0, 2),
         ),
       ],
     ),
     child: Material(
       color: Colors.transparent,
       child: InkWell(
         borderRadius: BorderRadius.circular(12),
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
           padding: const EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               // Header Row
               Row(
                 children: [
                   // Dava Adı
                   Expanded(
                     child: Text(
                       dava.davaAdi.isNotEmpty ? dava.davaAdi : 'Dava Adı Belirtilmemiş',
                       style: const TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.bold,
                         color: Colors.black87,
                       ),
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                   
                   // Action Buttons
                   Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       // Edit Button
                       IconButton(
                         icon: Icon(
                           Icons.edit_outlined,
                           color: Colors.grey.shade600,
                           size: 20,
                         ),
                         onPressed: () {
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
                       ),
                       
                       // Delete Button
                       IconButton(
                         icon: Icon(
                           Icons.delete_outline,
                           color: Colors.red.shade600,
                           size: 20,
                         ),
                         onPressed: () => _showDeleteConfirmation(context, dava, userEmail),
                       ),
                     ],
                   ),
                 ],
               ),
               
               const SizedBox(height: 8),
               
               // Dava Details
               if (dava.kategori.isNotEmpty || dava.davaci.isNotEmpty || dava.davali.isNotEmpty)
                 Column(
                   children: [
                     if (dava.kategori.isNotEmpty) _buildDetailRow('Kategori', dava.kategori),
                     if (dava.davaci.isNotEmpty) _buildDetailRow('Davacı', dava.davaci),
                     if (dava.davali.isNotEmpty) _buildDetailRow('Davalı', dava.davali),
                   ],
                 ),
             ],
           ),
         ),
       ),
     ),
   );
 }

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                'Dava Silinecek',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                'Bu davayı silmek istediğinizden emin misiniz?\nBu işlem geri alınamaz.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HiveDatabaseService.deleteSavedDava(dava.id);
                        Navigator.of(context).pop(); // Delete dialog'u kapat
                        Navigator.of(context).pop(); // Main dialog'u kapat
                        // Dialog'u yeniden aç
                        showSavedDavalarDialog(context, userEmail);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
