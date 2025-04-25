class InquiryData {
  final String category;
  final String title;
  final String content;
  final String author;
  final String date;
  final bool isPrivate;
  final bool isAnswered;
  final String? password;


  InquiryData({
    required this.category,
    required this.title,
    required this.content,
    required this.author,
    required this.date,
    required this.isPrivate,
    required this.isAnswered,
    this.password,
  });
}