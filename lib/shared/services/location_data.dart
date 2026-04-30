/// Static location data for Gaza Strip delivery zones.
/// Maps cities to neighborhoods, grouped by delivery zone.
class LocationData {
  LocationData._();

  /// Zone definitions with cities and neighborhoods
  static const List<ZoneData> zones = [
    ZoneData(
      zone: 'north',
      zoneNameAr: 'الشمال',
      cities: [
        CityData(
          name: 'مدينة غزة',
          neighborhoods: [
            'حي الرمال',
            'حي الشجاعية',
            'حي الزيتون',
            'حي التفاح',
            'حي الدرج',
            'حي الصبرة',
            'حي الشيخ رضوان',
            'حي النصر',
            'حي تل الهوا',
            'حي الشيخ عجلين',
            'مخيم الشاطئ',
          ],
        ),
      ],
    ),
    ZoneData(
      zone: 'central',
      zoneNameAr: 'الوسطى',
      cities: [
        CityData(
          name: 'مدينة دير البلح',
          neighborhoods: [
            'منطقة حكر الجامع',
            'منطقة المشاعلة',
            'منطقة طريق النخل',
          ],
        ),
        CityData(
          name: 'مخيم النصيرات',
          neighborhoods: [
            'مخيم 1',
            'مخيم 2',
            'مخيم 5',
            'منطقة الحساينة',
          ],
        ),
        CityData(
          name: 'مخيم البريج',
          neighborhoods: [
            'بلوك 1',
            'بلوك 2',
            'بلوك 3',
            'بلوك 4',
            'بلوك 5',
            'بلوك 6',
            'بلوك 7',
            'بلوك 8',
            'بلوك 9',
            'بلوك 10',
            'بلوك 11',
            'بلوك 12',
          ],
        ),
        CityData(
          name: 'مخيم المغازي',
          neighborhoods: [
            'منطقة وسط المخيم',
          ],
        ),
      ],
    ),
    ZoneData(
      zone: 'south',
      zoneNameAr: 'الجنوب',
      cities: [
        CityData(
          name: 'مدينة خانيونس',
          neighborhoods: [
            'حي الأمل',
            'حي الكتيبة',
            'حي الشيخ ناصر',
            'جورة العقاد',
            'منطقة السطر',
            'منطقة معن',
            'منطقة المواسي',
            'مخيم خانيونس',
          ],
        ),
      ],
    ),
  ];

  /// Get all city names across all zones
  static List<String> get allCities =>
      zones.expand((z) => z.cities.map((c) => c.name)).toList();

  /// Get neighborhoods for a given city
  static List<String> getNeighborhoods(String city) {
    for (final zone in zones) {
      for (final c in zone.cities) {
        if (c.name == city) return c.neighborhoods;
      }
    }
    return [];
  }

  /// Get the zone key for a given city
  static String getZoneForCity(String city) {
    for (final zone in zones) {
      for (final c in zone.cities) {
        if (c.name == city) return zone.zone;
      }
    }
    return 'north'; // fallback
  }

  /// Get the Arabic zone name for a given city
  static String getZoneNameAr(String city) {
    for (final zone in zones) {
      for (final c in zone.cities) {
        if (c.name == city) return zone.zoneNameAr;
      }
    }
    return 'الشمال';
  }

  /// Get the Arabic zone name from zone key
  static String zoneKeyToArabic(String zoneKey) {
    switch (zoneKey) {
      case 'north':
        return 'الشمال';
      case 'central':
        return 'الوسطى';
      case 'south':
        return 'الجنوب';
      default:
        return zoneKey;
    }
  }
}

class ZoneData {
  final String zone;
  final String zoneNameAr;
  final List<CityData> cities;

  const ZoneData({
    required this.zone,
    required this.zoneNameAr,
    required this.cities,
  });
}

class CityData {
  final String name;
  final List<String> neighborhoods;

  const CityData({
    required this.name,
    required this.neighborhoods,
  });
}
