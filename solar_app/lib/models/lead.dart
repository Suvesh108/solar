enum LeadStatus {
  newLead('New'),
  contacted('Contacted'),
  qualified('Qualified'),
  siteVisit('Site Visit'),
  quotation('Quotation'),
  won('Won'),
  lost('Lost');

  final String label;
  const LeadStatus(this.label);

  static LeadStatus fromString(String val) {
    for (final s in LeadStatus.values) {
      if (s.label.toLowerCase() == val.toLowerCase()) return s;
    }
    return LeadStatus.newLead;
  }
}

class Lead {
  final String id;
  final String name;
  final String phone;
  final String location;
  final String monthlyBill;
  final String propertyType;
  final LeadStatus status;
  final DateTime createdAt;

  Lead({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    required this.monthlyBill,
    required this.propertyType,
    this.status = LeadStatus.newLead,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'location': location,
        'monthlyBill': monthlyBill,
        'propertyType': propertyType,
        'status': status.label,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        location: json['location'] as String? ?? '',
        monthlyBill: json['monthlyBill']?.toString() ?? '',
        propertyType: json['propertyType'] as String? ?? 'House',
        status: LeadStatus.fromString(json['status'] as String? ?? 'New'),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  Lead copyWith({
    String? id,
    String? name,
    String? phone,
    String? location,
    String? monthlyBill,
    String? propertyType,
    LeadStatus? status,
    DateTime? createdAt,
  }) {
    return Lead(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      monthlyBill: monthlyBill ?? this.monthlyBill,
      propertyType: propertyType ?? this.propertyType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
