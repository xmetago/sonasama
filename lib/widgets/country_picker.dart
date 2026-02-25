import 'package:flutter/material.dart';
import '../utils/country_display_utils.dart';

/// Ülke seçimi için açılır liste sunan, arama destekli widget.
///
/// Kullanım örneği:
///   CountryPicker(),
class CountryPicker extends StatefulWidget {
  const CountryPicker({super.key});

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  String? _selectedCountry;
  final List<String> _countries = [
    'Türkiye', 'Almanya', 'Fransa', // ... Diğer ülkeler eklenebilir
  ];

  /// Ülke seçim modalını açar
  void _openCountryPicker(BuildContext context) {
    List<String> filteredCountries = _countries;
    TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Arama Çubuğu
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Ülke Ara',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        setModalState(() => filteredCountries = _countries);
                      },
                    ),
                  ),
                  onChanged: (query) {
                    setModalState(() {
                      filteredCountries = _countries
                          .where((country) => country
                              .toLowerCase()
                              .contains(query.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Performans için ListView.builder
                SizedBox(
                  height: 300, // Modal yüksekliği sabitlenebilir
                  child: ListView.builder(
                    itemCount: filteredCountries.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(CountryDisplayUtils.getDisplayName(filteredCountries[index])),
                      onTap: () {
                        setState(() => _selectedCountry = filteredCountries[index]);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(_selectedCountry != null 
        ? CountryDisplayUtils.getDisplayName(_selectedCountry!)
        : 'Ülke seçiniz'),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: () => _openCountryPicker(context),
    );
  }
} 