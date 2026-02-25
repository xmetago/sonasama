import 'package:flutter/material.dart';
import '../services/hive_database_service.dart';
import '../models/registration_model.dart';

class DatabaseDebugPage extends StatefulWidget {
  const DatabaseDebugPage({super.key});

  @override
  State<DatabaseDebugPage> createState() => _DatabaseDebugPageState();
}

class _DatabaseDebugPageState extends State<DatabaseDebugPage> {
  List<RegistrationModel> users = [];
  Map<String, int> stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      users = HiveDatabaseService.getAllRegistrations();
      stats = HiveDatabaseService.getDatabaseStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veritabanı Debug'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İstatistikler
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Veritabanı İstatistikleri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...stats.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${entry.key}:',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${entry.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Kullanıcılar Listesi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                                                 Text(
                           '👥 Kayıtlı Kullanıcılar (${users.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadData,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (users.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Henüz kayıtlı kullanıcı bulunmuyor',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ...users.map((user) => _buildUserCard(user)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(RegistrationModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.isAdmin ? Colors.red : Colors.grey[300]!,
          width: user.isAdmin ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık Satırı
          Row(
            children: [
              Icon(
                user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: user.isAdmin ? Colors.red : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user.judgeName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: user.isAdmin ? Colors.red : Colors.black,
                  ),
                ),
              ),
              if (user.isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ADMİN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // E-posta
          Row(
            children: [
              const Icon(Icons.email, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user.email,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Ülke
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                user.country,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Durum Bilgileri
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildStatusChip(
                'Aktif',
                user.isActive ? Colors.green : Colors.red,
                user.isActive,
              ),
              _buildStatusChip(
                'E-posta Doğrulandı',
                user.isEmailVerified ? Colors.blue : Colors.orange,
                user.isEmailVerified,
              ),
              _buildStatusChip(
                'Giriş Yapabilir',
                user.canLogin ? Colors.green : Colors.red,
                user.canLogin,
              ),
              if (user.isLocked)
                _buildStatusChip(
                  'Kilitli',
                  Colors.red,
                  true,
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Zaman Bilgileri
          Text(
            'Kayıt Tarihi: ${_formatDateTime(user.createdAt)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'Son Giriş: ${_formatDateTime(user.lastLoginAt)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          
          // Dava ve Haykır Zamanları
          if (user.lastDavaAcTime != null)
            Text(
              'Son Dava Açma: ${_formatDateTime(user.lastDavaAcTime!)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (user.lastHaykirTime != null)
            Text(
              'Son Haykırma: ${_formatDateTime(user.lastHaykirTime!)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          
          // Giriş Denemeleri
          if (user.loginAttempts > 0)
            Text(
              'Giriş Denemeleri: ${user.loginAttempts}',
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isActive ? color : Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 