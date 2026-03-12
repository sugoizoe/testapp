/// Keşfet ekranı profil modeli. Backend [user_id, full_name, age, distance_km, attributes] ile uyumludur.
class DiscoveryProfile {
  const DiscoveryProfile({
    required this.id,
    required this.fullName,
    required this.age,
    required this.distanceKm,
    required this.imageUrl,
    required this.interests,
  });

  final String id;
  final String fullName;
  final int age;
  final double distanceKm;
  final String imageUrl;
  final List<String> interests;
}
