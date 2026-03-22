class CaseRelationCustomer {
  final int id;
  final int customerId;
  final String customerName;

  CaseRelationCustomer({required this.id, required this.customerId, required this.customerName});

  factory CaseRelationCustomer.fromJson(Map<String, dynamic> json) => CaseRelationCustomer(
        id: json['id'] as int? ?? 0,
        customerId: json['customerId'] as int? ?? 0,
        customerName: json['customerName']?.toString() ?? '',
      );
}

class CaseRelationContender {
  final int id;
  final int contenderId;
  final String contenderName;

  CaseRelationContender({required this.id, required this.contenderId, required this.contenderName});

  factory CaseRelationContender.fromJson(Map<String, dynamic> json) => CaseRelationContender(
        id: json['id'] as int? ?? 0,
        contenderId: json['contenderId'] as int? ?? 0,
        contenderName: json['contenderName']?.toString() ?? '',
      );
}

class CaseRelationCourt {
  final int id;
  final int courtId;
  final String courtName;

  CaseRelationCourt({required this.id, required this.courtId, required this.courtName});

  factory CaseRelationCourt.fromJson(Map<String, dynamic> json) => CaseRelationCourt(
        id: json['id'] as int? ?? 0,
        courtId: json['courtId'] as int? ?? 0,
        courtName: json['courtName']?.toString() ?? '',
      );
}

class CaseRelationEmployee {
  final int id;
  final int employeeId;
  final String employeeName;

  CaseRelationEmployee({required this.id, required this.employeeId, required this.employeeName});

  factory CaseRelationEmployee.fromJson(Map<String, dynamic> json) => CaseRelationEmployee(
        id: json['id'] as int? ?? 0,
        employeeId: json['employeeId'] as int? ?? 0,
        employeeName: json['employeeName']?.toString() ?? '',
      );
}

class CaseRelationSiting {
  final int id;
  final int sitingId;
  final String? sitingDate;
  final String? judgeName;

  CaseRelationSiting({required this.id, required this.sitingId, this.sitingDate, this.judgeName});

  factory CaseRelationSiting.fromJson(Map<String, dynamic> json) => CaseRelationSiting(
        id: json['id'] as int? ?? 0,
        sitingId: json['sitingId'] as int? ?? 0,
        sitingDate: json['sitingDate']?.toString(),
        judgeName: json['judgeName']?.toString(),
      );
}

class CaseRelationFile {
  final int id;
  final int fileId;
  final String? filePath;
  final String? fileCode;

  CaseRelationFile({required this.id, required this.fileId, this.filePath, this.fileCode});

  factory CaseRelationFile.fromJson(Map<String, dynamic> json) => CaseRelationFile(
        id: json['id'] as int? ?? 0,
        fileId: json['fileId'] as int? ?? 0,
        filePath: json['filePath']?.toString(),
        fileCode: json['fileCode']?.toString(),
      );

  String get displayName => filePath ?? fileCode ?? 'File $fileId';
}

class CaseRelations {
  final int caseCode;
  final String caseStatement;
  final List<CaseRelationCustomer> customers;
  final List<CaseRelationContender> contenders;
  final List<CaseRelationCourt> courts;
  final List<CaseRelationEmployee> employees;
  final List<CaseRelationSiting> sitings;
  final List<CaseRelationFile> files;

  CaseRelations({
    required this.caseCode,
    required this.caseStatement,
    required this.customers,
    required this.contenders,
    required this.courts,
    required this.employees,
    required this.sitings,
    required this.files,
  });

  factory CaseRelations.fromJson(Map<String, dynamic> json) {
    final caseObj = json['case'] as Map<String, dynamic>? ?? {};
    return CaseRelations(
      caseCode: caseObj['code'] as int? ?? 0,
      caseStatement: caseObj['invitionsStatment']?.toString() ?? '',
      customers: _parseList(json['customers'], CaseRelationCustomer.fromJson),
      contenders: _parseList(json['contenders'], CaseRelationContender.fromJson),
      courts: _parseList(json['courts'], CaseRelationCourt.fromJson),
      employees: _parseList(json['employees'], CaseRelationEmployee.fromJson),
      sitings: _parseList(json['sitings'], CaseRelationSiting.fromJson),
      files: _parseList(json['files'], CaseRelationFile.fromJson),
    );
  }

  static List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw == null) return [];
    return (raw as List<dynamic>)
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
