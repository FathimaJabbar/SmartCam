class Language {
  final String name;
  final String code;

  const Language({required this.name, required this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

const List<Language> supportedLanguages = [
  Language(name: 'English', code: 'en'),
  Language(name: 'Hindi', code: 'hi'),
  Language(name: 'Spanish', code: 'es'),
  Language(name: 'French', code: 'fr'),
  Language(name: 'German', code: 'de'),
  Language(name: 'Japanese', code: 'ja'),
  Language(name: 'Malayalam', code: 'ml'),
];