class ESignSigner {
  final String email;
  final String? name;
  final bool hasSigned;
  final DateTime? signedAt;

  ESignSigner({
    required this.email,
    this.name,
    required this.hasSigned,
    this.signedAt,
  });

  factory ESignSigner.fromJson(Map<String, dynamic> json) {
    return ESignSigner(
      email: json['email'] as String,
      name: json['name'] as String?,
      hasSigned: json['hasSigned'] as bool? ?? false,
      signedAt: json['signedAt'] != null
          ? DateTime.tryParse(json['signedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'hasSigned': hasSigned,
      'signedAt': signedAt?.toIso8601String(),
    };
  }
}

class ESignRequest {
  final String id;
  final String title;
  final String status; // Pending, Signed, Rejected, Expired
  final List<ESignSigner> signers;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final String? shareLink;
  final String? createdBy;

  ESignRequest({
    required this.id,
    required this.title,
    required this.status,
    required this.signers,
    this.expiresAt,
    required this.createdAt,
    this.shareLink,
    this.createdBy,
  });

  factory ESignRequest.fromJson(Map<String, dynamic> json) {
    final signersList = json['signers'];
    List<ESignSigner> signers = [];
    if (signersList is List) {
      signers = signersList
          .whereType<Map<String, dynamic>>()
          .map(ESignSigner.fromJson)
          .toList();
    }

    return ESignRequest(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      signers: signers,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      shareLink: json['shareLink'] as String?,
      createdBy: json['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'signers': signers.map((s) => s.toJson()).toList(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'shareLink': shareLink,
      'createdBy': createdBy,
    };
  }
}
