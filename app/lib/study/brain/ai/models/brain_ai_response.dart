class BrainAiSuggestion {
  const BrainAiSuggestion({
    required this.title,
    required this.reason,
  });

  final String title;
  final String reason;

  factory BrainAiSuggestion.fromJson(Map<String, dynamic> json) {
    return BrainAiSuggestion(
      title: json['title']?.toString().trim() ?? '',
      reason: json['reason']?.toString().trim() ?? '',
    );
  }
}

class BrainAiResponse {
  const BrainAiResponse({
    required this.headline,
    required this.summary,
    required this.suggestions,
  });

  final String headline;
  final String summary;
  final List<BrainAiSuggestion> suggestions;

  factory BrainAiResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['suggestions'];

    return BrainAiResponse(
      headline: json['headline']?.toString().trim() ?? '',
      summary: json['summary']?.toString().trim() ?? '',
      suggestions: raw is List
          ? raw
              .whereType<Map>()
              .map((item) => BrainAiSuggestion.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((item) => item.title.isNotEmpty)
              .toList(growable: false)
          : const <BrainAiSuggestion>[],
    );
  }
}
