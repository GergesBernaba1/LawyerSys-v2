class BillingPay {

  BillingPay({
    this.id,
    required this.amount,
    required this.dateOfOperation,
    required this.notes,
    required this.customerId,
    this.customerName,
  });

  factory BillingPay.fromJson(Map<String, dynamic> json) {
    return BillingPay(
      id: json['id'] as int?,
      amount: (json['amount'] as num).toDouble(),
      dateOfOperation: json['dateOfOperation'] as String,
      notes: json['notes'] as String,
      customerId: json['customerId'] as int,
      customerName: json['customerName'] as String?,
    );
  }
  final int? id;
  final double amount;
  final String dateOfOperation;
  final String notes;
  final int customerId;
  final String? customerName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'dateOfOperation': dateOfOperation,
      'notes': notes,
      'customerId': customerId,
      'customerName': customerName,
    };
  }
}

class BillingReceipt {

  BillingReceipt({
    this.id,
    required this.amount,
    required this.dateOfOperation,
    required this.notes,
    required this.employeeId,
  });

  factory BillingReceipt.fromJson(Map<String, dynamic> json) {
    return BillingReceipt(
      id: json['id'] as int?,
      amount: (json['amount'] as num).toDouble(),
      dateOfOperation: json['dateOfOperation'] as String,
      notes: json['notes'] as String,
      employeeId: json['employeeId'] as int,
    );
  }
  final int? id;
  final double amount;
  final String dateOfOperation;
  final String notes;
  final int employeeId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'dateOfOperation': dateOfOperation,
      'notes': notes,
      'employeeId': employeeId,
    };
  }
}

class CustomerItem {

  CustomerItem({
    this.id,
    this.usersId,
    this.fullName,
    this.email,
  });

  factory CustomerItem.fromJson(Map<String, dynamic> json) {
    return CustomerItem(
      id: json['id'] as int?,
      usersId: json['usersId'] as int?,
      fullName: json['identity'] != null
          ? json['identity']['fullName'] as String?
          : null,
      email: json['identity'] != null
          ? json['identity']['email'] as String?
          : null,
    );
  }
  final int? id;
  final int? usersId;
  final String? fullName;
  final String? email;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usersId': usersId,
      'identity': {
        'fullName': fullName,
        'email': email,
      },
    };
  }
}

class EmployeeItem {

  EmployeeItem({
    this.id,
    this.usersId,
    this.fullName,
    this.email,
  });

  factory EmployeeItem.fromJson(Map<String, dynamic> json) {
    return EmployeeItem(
      id: json['id'] as int?,
      usersId: json['usersId'] as int?,
      fullName: json['identity'] != null
          ? json['identity']['fullName'] as String?
          : null,
      email: json['identity'] != null
          ? json['identity']['email'] as String?
          : null,
    );
  }
  final int? id;
  final int? usersId;
  final String? fullName;
  final String? email;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usersId': usersId,
      'identity': {
        'fullName': fullName,
        'email': email,
      },
    };
  }
}

class BillingSummary {

  BillingSummary({
    this.totalPayments,
    this.totalReceipts,
    this.balance,
  });

  factory BillingSummary.fromJson(Map<String, dynamic> json) {
    return BillingSummary(
      totalPayments: (json['totalPayments'] as num?)?.toDouble(),
      totalReceipts: (json['totalReceipts'] as num?)?.toDouble(),
      balance: (json['balance'] as num?)?.toDouble(),
    );
  }
  final double? totalPayments;
  final double? totalReceipts;
  final double? balance;

  Map<String, dynamic> toJson() {
    return {
      'totalPayments': totalPayments,
      'totalReceipts': totalReceipts,
      'balance': balance,
    };
  }
}
