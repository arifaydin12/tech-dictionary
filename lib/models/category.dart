import 'package:flutter/material.dart';

/// Presentation metadata for a dictionary category.
class WordCategory {
  const WordCategory(this.name, this.icon, this.color);

  final String name;
  final IconData icon;
  final Color color;
}

/// The fixed list of dictionary categories.
class Categories {
  const Categories._();

  static const hardware = WordCategory(
    'Hardware',
    Icons.memory,
    Color(0xFFE67700),
  );
  static const software = WordCategory(
    'Software',
    Icons.apps,
    Color(0xFF1C7ED6),
  );
  static const networking = WordCategory(
    'Networking',
    Icons.hub_outlined,
    Color(0xFF0C8599),
  );
  static const security = WordCategory(
    'Security',
    Icons.shield_outlined,
    Color(0xFFC92A2A),
  );
  static const programming = WordCategory(
    'Programming',
    Icons.code,
    Color(0xFF5F3DC4),
  );
  static const databases = WordCategory(
    'Databases',
    Icons.storage_outlined,
    Color(0xFF2B8A3E),
  );
  static const ai = WordCategory(
    'AI/ML',
    Icons.psychology_outlined,
    Color(0xFFD6336C),
  );
  static const cloud = WordCategory(
    'Cloud',
    Icons.cloud_outlined,
    Color(0xFF3B5BDB),
  );
  static const web = WordCategory('Web', Icons.language, Color(0xFF9C36B5));

  static const List<WordCategory> all = [
    hardware,
    software,
    networking,
    security,
    programming,
    databases,
    ai,
    cloud,
    web,
  ];

  static List<String> get names => [for (final c in all) c.name];

  /// Looks up a category by name; unknown names fall back to [software].
  static WordCategory byName(String name) {
    for (final c in all) {
      if (c.name == name) return c;
    }
    return software;
  }
}
