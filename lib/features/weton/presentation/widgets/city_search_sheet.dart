import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CityPreset {
  final String name;
  final double latitude;
  final double longitude;

  const CityPreset({required this.name, required this.latitude, required this.longitude});
}

class CitySearchSheet extends StatefulWidget {
  final List<CityPreset> cityPresets;

  const CitySearchSheet({super.key, required this.cityPresets});

  @override
  State<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<CitySearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CityPreset> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    _filteredCities = widget.cityPresets;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCities = widget.cityPresets;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCities = widget.cityPresets.where((city) {
          if (city.name == 'Koordinat Kustom') return true;
          return city.name.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih Kota Kelahiran',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppTheme.textLight),
              decoration: InputDecoration(
                hintText: 'Cari Kota atau Kabupaten...',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppTheme.accentPurple),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.background.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.accentPurple.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.accentPurple),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredCities.isEmpty
                  ? Center(
                      child: Text(
                        'Kota tidak ditemukan',
                        style: textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = _filteredCities[index];
                        final isCustom = city.name == 'Koordinat Kustom';
                        return ListTile(
                           contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Icon(
                            isCustom ? Icons.my_location : Icons.location_city,
                            color: isCustom ? AppTheme.accentPink : AppTheme.accentPurple.withValues(alpha: 0.7),
                          ),
                          title: Text(
                            city.name,
                            style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Lat: ${city.latitude.toStringAsFixed(4)} • Lng: ${city.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                          onTap: () {
                            Navigator.pop(context, city);
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
