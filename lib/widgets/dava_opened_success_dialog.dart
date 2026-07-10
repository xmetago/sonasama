import 'package:flutter/material.dart';
import 'package:its19/screens/actigim_davalar_page.dart';
import 'fireworks_celebration_widget.dart';

/// Dava başarıyla açıldığında gösterilen onay dialog'u.
class DavaOpenedSuccessDialog extends StatelessWidget {
  const DavaOpenedSuccessDialog({
    super.key,
    required this.selectedGroup,
    required this.formattedDate,
    this.userEmail,
    required this.onDavetEt,
    required this.onTamam,
  });

  final String selectedGroup;
  final String formattedDate;
  final String? userEmail;
  final VoidCallback onDavetEt;
  final VoidCallback onTamam;

  static Future<void> show(
    BuildContext context, {
    required String selectedGroup,
    required String formattedDate,
    String? userEmail,
    required VoidCallback onDavetEt,
    required VoidCallback onTamam,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DavaOpenedSuccessDialog(
        selectedGroup: selectedGroup,
        formattedDate: formattedDate,
        userEmail: userEmail,
        onDavetEt: onDavetEt,
        onTamam: onTamam,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Üst bölümde havai fişek patlaması
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 200,
                child: IgnorePointer(
                  child: FireworksCelebrationWidget(
                    duration: const Duration(milliseconds: 3000),
                  ),
                ),
              ),
              // Okunabilirlik için hafif gradient
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 200,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.75),
                          Colors.white,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 32,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Dava Başarıyla Açıldı',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '"$selectedGroup" grubunuzdan rastgele seçilen 7 kişi şimdi değerlendirmeye başlayacak.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event,
                            size: 18,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Tarih: $formattedDate',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),


                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ActigimDavalarPage(
                                      userEmail: userEmail,
                                      initiallyCollapsed: true,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                                child: Image.asset('lib/icons/06_left_row_actigim_davalar_icon.png', width: 24, height: 24),
                              ),
                            ),





                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ' <-- Takip için',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onDavetEt();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('DAVET ET '),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onTamam();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Tamam'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
