import 'package:flutter/material.dart';
import '../services/verified_users_service.dart';

/// Verified Users (Mavi Tik) Yönetim Dialog'u
/// Geliştiriciye özel gizli yönetim arayüzü
class VerifiedUsersManagementDialog extends StatefulWidget {
  const VerifiedUsersManagementDialog({super.key});

  @override
  State<VerifiedUsersManagementDialog> createState() => _VerifiedUsersManagementDialogState();
}

class _VerifiedUsersManagementDialogState extends State<VerifiedUsersManagementDialog> {
  final TextEditingController _judgeNameController = TextEditingController();
  List<String> _verifiedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVerifiedUsers();
  }

  @override
  void dispose() {
    _judgeNameController.dispose();
    super.dispose();
  }

  /// Verified kullanıcıları yükle
  void _loadVerifiedUsers() {
    setState(() {
      _verifiedUsers = VerifiedUsersService.listVerified();
    });
  }

  /// Kullanıcıya mavi tik ver
  Future<void> _setVerified(String judgeName, bool verified) async {
    if (judgeName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yargıç adı boş olamaz!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await VerifiedUsersService.setVerified(judgeName.trim(), verified);
      _loadVerifiedUsers();
      _judgeNameController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(verified ? 'Mavi tik verildi ✅' : 'Mavi tik iptal edildi ❌'),
          backgroundColor: verified ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Mavi Tik Yönetimi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // Yargıç adı girişi
            TextField(
              controller: _judgeNameController,
              decoration: InputDecoration(
                labelText: 'Yargıç Adı',
                hintText: 'Örn: Edip Yüksel',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            
            // Butonlar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () {
                      if (_judgeNameController.text.trim().isNotEmpty) {
                        _setVerified(_judgeNameController.text, true);
                      }
                    },
                    icon: const Icon(Icons.verified, color: Colors.blue),
                    label: const Text('Mavi Tik Ver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () {
                      if (_judgeNameController.text.trim().isNotEmpty) {
                        _setVerified(_judgeNameController.text, false);
                      }
                    },
                    icon: const Icon(Icons.cancel_outlined, color: Colors.orange),
                    label: const Text('Mavi Tik İptal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade50,
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Verified kullanıcı listesi
            const Text(
              'Verified Kullanıcılar:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_verifiedUsers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Henüz verified kullanıcı yok',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _verifiedUsers.length,
                  itemBuilder: (context, index) {
                    final judgeName = _verifiedUsers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.verified, color: Colors.blue),
                        title: Text(judgeName),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _setVerified(judgeName, false),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

