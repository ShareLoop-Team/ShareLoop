/// Main cities and towns of each of Sri Lanka's 25 districts, bundled with
/// the app (no location API). Registration, Edit Profile and Home all use
/// this one table, so a city is only ever offered under its own district.
///
/// Each list starts with the district's capital, then the rest A–Z. To add a
/// town, put it under the district it administratively belongs to.
library;

import 'app_constants.dart';

class SriLankaLocations {
  SriLankaLocations._();

  static const Map<String, List<String>> citiesByDistrict = {
    'Ampara': [
      'Ampara',
      'Akkaraipattu',
      'Dehiattakandiya',
      'Kalmunai',
      'Maha Oya',
      'Pottuvil',
      'Sammanthurai',
      'Uhana',
    ],
    'Anuradhapura': [
      'Anuradhapura',
      'Eppawala',
      'Galenbindunuwewa',
      'Horowpothana',
      'Kekirawa',
      'Medawachchiya',
      'Mihintale',
      'Tambuttegama',
    ],
    'Badulla': [
      'Badulla',
      'Bandarawela',
      'Ella',
      'Hali-Ela',
      'Haputale',
      'Mahiyanganaya',
      'Passara',
      'Welimada',
    ],
    'Batticaloa': [
      'Batticaloa',
      'Chenkalady',
      'Eravur',
      'Kaluwanchikudy',
      'Kattankudy',
      'Valaichchenai',
    ],
    'Colombo': [
      'Colombo',
      'Avissawella',
      'Battaramulla',
      'Boralesgamuwa',
      'Dehiwala-Mount Lavinia',
      'Homagama',
      'Kaduwela',
      'Kolonnawa',
      'Maharagama',
      'Moratuwa',
      'Nugegoda',
      'Padukka',
      'Piliyandala',
      'Sri Jayawardenepura Kotte',
    ],
    'Galle': [
      'Galle',
      'Ambalangoda',
      'Baddegama',
      'Bentota',
      'Elpitiya',
      'Habaraduwa',
      'Hikkaduwa',
      'Karandeniya',
      'Unawatuna',
    ],
    'Gampaha': [
      'Gampaha',
      'Divulapitiya',
      'Ja-Ela',
      'Kadawatha',
      'Kandana',
      'Katunayake',
      'Kelaniya',
      'Kiribathgoda',
      'Minuwangoda',
      'Mirigama',
      'Negombo',
      'Nittambuwa',
      'Ragama',
      'Seeduwa',
      'Veyangoda',
      'Wattala',
    ],
    'Hambantota': [
      'Hambantota',
      'Ambalantota',
      'Beliatta',
      'Suriyawewa',
      'Tangalle',
      'Tissamaharama',
      'Weeraketiya',
    ],
    'Jaffna': [
      'Jaffna',
      'Chankanai',
      'Chavakachcheri',
      'Kayts',
      'Kopay',
      'Nallur',
      'Point Pedro',
      'Valvettithurai',
    ],
    'Kalutara': [
      'Kalutara',
      'Agalawatta',
      'Aluthgama',
      'Bandaragama',
      'Beruwala',
      'Horana',
      'Ingiriya',
      'Matugama',
      'Panadura',
      'Wadduwa',
    ],
    'Kandy': [
      'Kandy',
      'Akurana',
      'Digana',
      'Gampola',
      'Kadugannawa',
      'Katugastota',
      'Kundasale',
      'Nawalapitiya',
      'Peradeniya',
      'Pilimathalawa',
      'Wattegama',
    ],
    'Kegalle': [
      'Kegalle',
      'Dehiowita',
      'Deraniyagala',
      'Galigamuwa',
      'Mawanella',
      'Rambukkana',
      'Ruwanwella',
      'Warakapola',
      'Yatiyantota',
    ],
    'Kilinochchi': [
      'Kilinochchi',
      'Pallai',
      'Paranthan',
      'Poonakary',
    ],
    'Kurunegala': [
      'Kurunegala',
      'Alawwa',
      'Galgamuwa',
      'Hettipola',
      'Ibbagamuwa',
      'Kuliyapitiya',
      'Mawathagama',
      'Narammala',
      'Nikaweratiya',
      'Pannala',
      'Polgahawela',
      'Wariyapola',
    ],
    'Mannar': [
      'Mannar',
      'Madhu',
      'Murunkan',
      'Nanattan',
      'Pesalai',
    ],
    'Matale': [
      'Matale',
      'Dambulla',
      'Galewela',
      'Naula',
      'Palapathwala',
      'Rattota',
      'Sigiriya',
      'Ukuwela',
    ],
    'Matara': [
      'Matara',
      'Akuressa',
      'Deniyaya',
      'Devinuwara',
      'Dikwella',
      'Hakmana',
      'Kamburupitiya',
      'Mirissa',
      'Weligama',
    ],
    'Monaragala': [
      'Monaragala',
      'Bibile',
      'Buttala',
      'Kataragama',
      'Medagama',
      'Siyambalanduwa',
      'Wellawaya',
    ],
    'Mullaitivu': [
      'Mullaitivu',
      'Mallavi',
      'Mankulam',
      'Oddusuddan',
      'Puthukudiyiruppu',
    ],
    'Nuwara Eliya': [
      'Nuwara Eliya',
      'Hanguranketha',
      'Hatton',
      'Kotagala',
      'Maskeliya',
      'Nanu Oya',
      'Ragala',
      'Talawakele',
      'Walapane',
    ],
    'Polonnaruwa': [
      'Polonnaruwa',
      'Aralaganwila',
      'Dimbulagala',
      'Hingurakgoda',
      'Kaduruwela',
      'Manampitiya',
      'Medirigiriya',
      'Welikanda',
    ],
    'Puttalam': [
      'Puttalam',
      'Anamaduwa',
      'Chilaw',
      'Dankotuwa',
      'Kalpitiya',
      'Marawila',
      'Nattandiya',
      'Nawagattegama',
      'Wennappuwa',
    ],
    'Ratnapura': [
      'Ratnapura',
      'Balangoda',
      'Eheliyagoda',
      'Embilipitiya',
      'Kahawatta',
      'Kalawana',
      'Kuruwita',
      'Pelmadulla',
      'Rakwana',
    ],
    'Trincomalee': [
      'Trincomalee',
      'Kantale',
      'Kinniya',
      'Kuchchaveli',
      'Mutur',
      'Nilaveli',
    ],
    'Vavuniya': [
      'Vavuniya',
      'Cheddikulam',
      'Nedunkeni',
      'Omanthai',
    ],
  };

  /// The cities and towns of [district]; empty for none or an unknown one.
  static List<String> citiesFor(String? district) =>
      citiesByDistrict[district] ?? const [];

  /// Whether [city] is one of [district]'s listed cities.
  static bool isCityIn(String? district, String? city) =>
      city != null && citiesFor(district).contains(city);

  /// [district] if it is one of the 25, else null.
  static String? validDistrict(String? district) =>
      AppConstants.sriLankanDistricts.contains(district) ? district : null;

  /// [city] if it belongs to [district], else null — e.g. an old free-text
  /// city, or one left over from a different district.
  static String? validCity(String? district, String? city) =>
      isCityIn(district, city) ? city : null;
}
