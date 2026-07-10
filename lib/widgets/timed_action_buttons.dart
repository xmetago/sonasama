import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../services/hive_database_service.dart';
import '../utils/app_local_date_format.dart';
import '../screens/category_page.dart';
import '../screens/haykir_page.dart';

/// Dava için günlük kota; haykır serbest (çalışan proje ile uyumlu)
/// Bu widget tüm sayfalarda kullanılabilir
class TimedActionButtons extends StatefulWidget {
  final String? userEmail;
  final double iconSize;
  final double buttonSize;
  final VoidCallback? onDavaAcPressed;
  final VoidCallback? onHaykirPressed;
  final VoidCallback? onShowSavedDavalar; // Kaydedilen davalar dialog'u için callback
  final Function(String)? onDateUpdate;

  const TimedActionButtons({
    super.key,
    required this.userEmail,
    this.iconSize = 38,
    this.buttonSize = 40,
    this.onDavaAcPressed,
    this.onHaykirPressed,
    this.onShowSavedDavalar, // Kaydedilen davalar dialog'u için callback
    this.onDateUpdate,
  });

  @override
  State<TimedActionButtons> createState() => _TimedActionButtonsState();
}

class _TimedActionButtonsState extends State<TimedActionButtons> {
  bool _canOpenDava = true;
  int _remainingDavaQuota = 0;

  @override
  void initState() {
    super.initState();
    _checkTimers();
  }

  @override
  void didUpdateWidget(TimedActionButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userEmail != widget.userEmail) {
      _checkTimers();
    }
  }

  /// Zamanlayıcıları kontrol et
  void _checkTimers() {
    if (widget.userEmail == null) return;

    setState(() {
      _canOpenDava = HiveDatabaseService.canUserOpenDava(widget.userEmail!);

      if (!_canOpenDava) {
        _remainingDavaQuota = HiveDatabaseService.getRemainingDavaAcHours(widget.userEmail!);
      }
    });
  }

  /// Modern uyarı gösterme fonksiyonu
  void _showModernAlert({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // İkon ve başlık
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Başlık
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                
                // Mesaj
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                
                // Buton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dava aç butonuna tıklandığında
  void _onDavaAcPressed() {
    if (widget.onDavaAcPressed != null) {
      widget.onDavaAcPressed!();
      return;
    }

    if (!_canOpenDava) {
      // Dava aç ikonu inaktif olduğunda Kaydedilen Davalar dialog'unu aç
      if (widget.onShowSavedDavalar != null) {
        widget.onShowSavedDavalar!();
      } else {
        _showModernAlert(
          title: 'Günlük Dava Kotası ⏰',
          message: 'Bugün için dava açma hakkınızı doldurdunuz (maksimum 19).\n\nYeni dava açmak için yarını bekleyin.\nKaydedilen davalarınızı görüntülemek için save ikonuna tıklayın.',
          icon: FeatherIcons.clock,
          color: const Color(0xFFF59E0B),
        );
      }
      return;
    }

    // Günün tarihini al ve callback ile gönder (locale + cihaz yerel saati)
    final formattedDate =
        AppLocalDateFormat.formatShortDate(context, DateTime.now());
    widget.onDateUpdate?.call(formattedDate);

    // Dava açma zamanını güncelle
    if (widget.userEmail != null) {
      HiveDatabaseService.updateUserDavaAcTime(widget.userEmail!);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryPage(userEmail: widget.userEmail),
      ),
    );
  }

  /// Haykır butonuna tıklandığında
  void _onHaykirPressed() {
    if (widget.onHaykirPressed != null) {
      widget.onHaykirPressed!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HaykirPage(
          userEmail: widget.userEmail,
          initialShowForm: true, // Formu otomatik aç
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Dava Aç Butonu
        GestureDetector(
          onTap: _onDavaAcPressed,
          child: Container(
            width: widget.buttonSize,
            height: widget.buttonSize,
            decoration: BoxDecoration(
              color: _canOpenDava ? Colors.green.shade100 : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(
                color: _canOpenDava ? Colors.green : Colors.grey,
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'lib/icons/03_davala_ana_icon.png',
                  width: widget.iconSize,
                  height: widget.iconSize,
                  color: _canOpenDava ? null : Colors.grey.shade400,
                ),
                if (!_canOpenDava)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_remainingDavaQuota',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Haykır Butonu
        GestureDetector(
          onTap: _onHaykirPressed,
          child: Container(
            width: widget.buttonSize,
            height: widget.buttonSize,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),
            ),
            child: Image.asset(
              'lib/icons/03_haykir_ana_icon.png',
              width: widget.iconSize,
              height: widget.iconSize,
            ),
          ),
        ),
      ],
    );
  }
}
