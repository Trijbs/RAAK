class Dare {
  final String id;
  final String text;
  final bool isCustom;
  final bool isEnabled;

  const Dare({
    required this.id,
    required this.text,
    this.isCustom = false,
    this.isEnabled = true,
  });

  // Only isEnabled is exposed because built-in dares are immutable.
  // If custom dare text editing is added in future, expand this method.
  Dare copyWith({bool? isEnabled}) => Dare(
    id: id,
    text: text,
    isCustom: isCustom,
    isEnabled: isEnabled ?? this.isEnabled,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isCustom': isCustom,
    'isEnabled': isEnabled,
  };

  factory Dare.fromJson(Map<String, dynamic> j) => Dare(
    id: j['id'] as String,
    text: j['text'] as String,
    isCustom: j['isCustom'] as bool? ?? false,
    isEnabled: j['isEnabled'] as bool? ?? true,
  );
}
