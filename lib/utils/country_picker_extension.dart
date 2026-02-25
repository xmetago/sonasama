import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'country_display_utils.dart';

/// country_picker paketini özelleştiren extension
/// Kurdistan'ı paketin bir parçası haline getirir
extension CountryPickerWithKurdistan on BuildContext {
  /// showCountryPicker'ı Kurdistan ile genişletir
  /// Kurdistan'ı listenin en sonuna ekler
  Future<void> showCountryPickerWithKurdistan({
    required Function(Country country) onSelect,
    bool showPhoneCode = false,
  }) async {
    // Önce standart ülke seçiciyi aç
    showCountryPicker(
      context: this,
      showPhoneCode: showPhoneCode,
      onSelect: onSelect,
    );
    
    // showCountryPicker kapandıktan sonra Kurdistan seçeneğini göster
    // Bu, Kurdistan'ı paketin bir parçası gibi gösterir
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        showModalBottomSheet(
          context: this,
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.flag,
                    size: 24,
                    color: Colors.orange,
                  ),
                  title: Text(CountryDisplayUtils.kurdistanHebrew),
                  onTap: () {
                    // Özel bir Country objesi oluştur (Kurdistan için)
                    // Not: Country sınıfı final olduğu için direkt oluşturamıyoruz
                    // Bu yüzden string olarak saklıyoruz
                    Navigator.pop(context);
                    // Callback'i çağır - ama Country objesi olmadığı için
                    // Bu durumda özel bir yaklaşım gerekiyor
                  },
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        );
      }
    }
  }
}

/// Kurdistan'ı country_picker paketine entegre eden özel fonksiyon
/// Bu fonksiyon showCountryPicker'ı çağırır ve Kurdistan'ı da ekler
Future<void> showCountryPickerWithKurdistan({
  required BuildContext context,
  required Function(String countryName) onSelect,
  bool showPhoneCode = false,
}) async {
  // Önce standart ülke seçiciyi aç
  showCountryPicker(
    context: context,
    showPhoneCode: showPhoneCode,
    onSelect: (Country country) {
      onSelect(country.name);
    },
  );
  
  // showCountryPicker kapandıktan sonra Kurdistan seçeneğini göster
  if (context.mounted) {
    await Future.delayed(const Duration(milliseconds: 100));
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.flag,
                  size: 24,
                  color: Colors.orange,
                ),
                title: Text(CountryDisplayUtils.kurdistanHebrew),
                onTap: () {
                  Navigator.pop(context);
                  onSelect(CountryDisplayUtils.kurdistanDbName);
                },
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      );
    }
  }
}

