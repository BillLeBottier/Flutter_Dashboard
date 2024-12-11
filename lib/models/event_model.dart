class EventModel {
  final String title;
  final String description;
  final String date;
  final String url;
  final String organizer;

  EventModel({
    required this.title,
    required this.description,
    required this.date,
    required this.url,
    required this.organizer,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      title: json['title'] ?? 'No title',
      description: json['description'] ?? 'No description',
      date: json['start_date'] ?? '',
      url: json['website'] ?? '',
      organizer: json['organizer'] ?? 'Unknown organizer',
    );
  }
}