class PromoBannerModel {
  final String id;
  final String category;
  final String title;
  final String iconName;
  final String gradientStart;
  final String gradientEnd;
  final String? targetLink;
  final bool isActive;
  final int displayOrder;
  final List<String>? targetDepartments;
  final List<String>? targetBatches;
  final DateTime? startDate;
  final DateTime? endDate;
  final int clicks;
  final String? imageUrl;
  final String? ctaText;

  PromoBannerModel({
    required this.id,
    required this.category,
    required this.title,
    required this.iconName,
    required this.gradientStart,
    required this.gradientEnd,
    this.targetLink,
    required this.isActive,
    required this.displayOrder,
    this.targetDepartments,
    this.targetBatches,
    this.startDate,
    this.endDate,
    this.clicks = 0,
    this.imageUrl,
    this.ctaText,
  });

  factory PromoBannerModel.fromJson(Map<String, dynamic> json) {
    return PromoBannerModel(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Event',
      title: json['title']?.toString() ?? '',
      iconName: json['icon_name']?.toString() ?? 'sparkles',
      gradientStart: json['gradient_start']?.toString() ?? '#4F46E5',
      gradientEnd: json['gradient_end']?.toString() ?? '#3730A3',
      targetLink: json['target_link']?.toString(),
      isActive: json['is_active'] ?? true,
      displayOrder: json['display_order'] ?? 0,
      targetDepartments: json['target_departments'] != null 
          ? List<String>.from(json['target_departments']) 
          : null,
      targetBatches: json['target_batches'] != null 
          ? List<String>.from(json['target_batches']) 
          : null,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'].toString()) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'].toString()) : null,
      clicks: json['clicks'] ?? 0,
      imageUrl: json['image_url']?.toString(),
      ctaText: json['cta_text']?.toString(),
    );
  }
}
