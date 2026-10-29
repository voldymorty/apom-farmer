import 'dart:convert';

OrderDetailModel orderDetailModelFromJson(String str) =>
    OrderDetailModel.fromJson(json.decode(str));

String orderDetailModelToJson(OrderDetailModel data) =>
    json.encode(data.toJson());

class OrderDetailModel {
  bool success;
  Data data;

  OrderDetailModel({
    required this.success,
    required this.data,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      success: json["success"] == true || json["status"] == true,
      data: Data.fromJson(json["data"] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data.toJson(),
  };
}

class Data {
  int cropId;
  int farmerId;
  dynamic partitionId;
  int productId;
  String quantityKg;
  String grade;
  String expectedPricePerKg;
  dynamic harvestDate;
  bool isReady;
  dynamic cropPhotoUrl;
  String status;
  dynamic remarks;
  DateTime createdAt;
  DateTime updatedAt;
  Product product;
  Farmer farmer;
  String? procurementReceiptUrl;
  String? paymentReceiptUrl;
  String? transactionProofUrl;
  String? holdingStatus;
  String? paymentStatus;
  bool isProcurementLocked;
  bool isPaymentLocked;
  double totalPayableAmount;
  int deliveryId;
  List<FarmerProcurementItem> items;
  List<FarmerSettlementItem> settlementItems;
  String? deliveryStatus;
  String? procurementStatus;
  String? deliveryNumber;

  Data({
    required this.cropId,
    required this.farmerId,
    required this.partitionId,
    required this.productId,
    required this.quantityKg,
    required this.grade,
    required this.expectedPricePerKg,
    required this.harvestDate,
    required this.isReady,
    required this.cropPhotoUrl,
    required this.status,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
    required this.farmer,
    this.procurementReceiptUrl,
    this.paymentReceiptUrl,
    this.transactionProofUrl,
    this.holdingStatus,
    this.paymentStatus,
    this.isProcurementLocked = false,
    this.isPaymentLocked = false,
    this.totalPayableAmount = 0.0,
    this.deliveryId = 0,
    this.items = const [],
    this.settlementItems = const [],
    this.deliveryStatus,
    this.procurementStatus,
    this.deliveryNumber,
  });

  String get effectiveStatus {
    final s = status.trim().toLowerCase();
    final delStatus = (deliveryStatus ?? '').trim().toLowerCase();
    final pStatus = (paymentStatus ?? '').trim().toLowerCase();
    final hStatus = (holdingStatus ?? '').trim().toLowerCase();
    final procStatus = (procurementStatus ?? '').trim().toLowerCase();

    if (s == 'cancelled' || delStatus == 'cancelled' || s == 'rejected') {
      return 'cancelled';
    }
    if (isPaymentLocked || pStatus == 'paid' || pStatus == 'fully_paid') {
      return 'payment_settled';
    }
    if (hStatus == 'released') {
      return 'stock_released';
    }
    if (hStatus == 'holding' || isProcurementLocked || procStatus == 'finalized') {
      return 'in_holding';
    }
    if (s == 'picked_up' || delStatus == 'completed') {
      return 'picked_up';
    }
    if (delStatus == 'reached' || delStatus == 'arrived') {
      return 'driver_arrived';
    }
    if (delStatus == 'in_transit') {
      return 'in_transit';
    }
    if (s == 'pickup_assigned' || delStatus == 'assigned' || delStatus == 'accepted') {
      return 'pickup_assigned';
    }
    if (delStatus == 'requested' || s == 'requested') {
      return 'requested';
    }
    return 'requested';
  }

  String get effectiveStatusLabel {
    switch (effectiveStatus) {
      case 'cancelled':
        return 'CANCELLED';
      case 'payment_settled':
        return 'PAYMENT SETTLED';
      case 'stock_released':
        return 'STOCK RELEASED';
      case 'in_holding':
        return 'IN HOLDING STAGE';
      case 'picked_up':
        return 'PICKED UP';
      case 'driver_arrived':
        return 'DRIVER ARRIVED';
      case 'in_transit':
        return 'IN TRANSIT';
      case 'pickup_assigned':
        return 'PICKUP ASSIGNED';
      case 'requested':
      case 'available':
      default:
        return 'REQUESTED';
    }
  }

  factory Data.fromJson(Map<String, dynamic> json) {
    final primaryDelivery = json["pickup_delivery"] as Map<String, dynamic>?;
    final delId = _toInt(primaryDelivery?["delivery_id"] ?? json["delivery_id"]);

    final rawItems = (json["items"] as List<dynamic>?) ??
        (primaryDelivery?["items"] as List<dynamic>?) ??
        [];
    final itemsList = rawItems
        .map((x) => FarmerProcurementItem.fromJson(x as Map<String, dynamic>))
        .toList();

    final rawSettlements = (json["settlement_items"] as List<dynamic>?) ??
        (primaryDelivery?["settlement_items"] as List<dynamic>?) ??
        [];
    final settlementList = rawSettlements
        .map((x) => FarmerSettlementItem.fromJson(x as Map<String, dynamic>))
        .toList();

    return Data(
      cropId: _toInt(json["crop_id"]),
      farmerId: _toInt(json["farmer_id"]),
      partitionId: json["partition_id"],
      productId: _toInt(json["product_id"]),
      quantityKg: _toString(json["quantity_kg"]),
      grade: _toString(json["grade"]),
      expectedPricePerKg: _toString(json["expected_price_per_kg"]),
      harvestDate: json["harvest_date"],
      isReady: _toBool(json["is_ready"]),
      cropPhotoUrl: json["crop_photo_url"],
      status: _toString(json["status"]),
      remarks: json["remarks"],
      createdAt: _toDateTime(json["created_at"]),
      updatedAt: _toDateTime(json["updated_at"]),
      product: Product.fromJson(json["product"] ?? {}),
      farmer: Farmer.fromJson(json["farmer"] ?? {}),
      procurementReceiptUrl: json["procurement_receipt_url"] ??
          (primaryDelivery?["procurement_receipt_filename"] != null
              ? "/api/secure-documents/procurement-receipt/$delId"
              : null),
      paymentReceiptUrl: json["payment_receipt_url"] ??
          (primaryDelivery?["payment_receipt_filename"] != null
              ? "/api/secure-documents/payment-receipt/$delId"
              : null),
      transactionProofUrl: json["transaction_proof_url"] ??
          (primaryDelivery?["transaction_proof_filename"] != null
              ? "/api/secure-documents/transaction-proof/$delId"
              : null),
      holdingStatus: json["holding_status"] ?? primaryDelivery?["holding_status"] ?? "not_holding",
      paymentStatus: (json["payment_status"] == "fully_paid" || primaryDelivery?["payment_status"] == "fully_paid")
          ? "paid"
          : (json["payment_status"] ?? primaryDelivery?["payment_status"] ?? "unpaid"),
      isProcurementLocked: _toBool(json["is_procurement_locked"] ?? primaryDelivery?["is_procurement_locked"]),
      isPaymentLocked: _toBool(json["is_payment_locked"] ?? primaryDelivery?["is_payment_locked"]),
      totalPayableAmount: _toDouble(json["total_payable_amount"] ?? primaryDelivery?["total_payable_amount"]),
      deliveryId: delId,
      items: itemsList,
      settlementItems: settlementList,
      deliveryStatus: _toString(json["delivery_status"] ?? primaryDelivery?["status"]),
      procurementStatus: _toString(json["procurement_status"] ?? primaryDelivery?["procurement_status"]),
      deliveryNumber: _toString(json["delivery_number"] ?? primaryDelivery?["delivery_number"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "crop_id": cropId,
    "farmer_id": farmerId,
    "partition_id": partitionId,
    "product_id": productId,
    "quantity_kg": quantityKg,
    "grade": grade,
    "expected_price_per_kg": expectedPricePerKg,
    "harvest_date": harvestDate,
    "is_ready": isReady,
    "crop_photo_url": cropPhotoUrl,
    "status": status,
    "remarks": remarks,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "product": product.toJson(),
    "farmer": farmer.toJson(),
    "procurement_receipt_url": procurementReceiptUrl,
    "payment_receipt_url": paymentReceiptUrl,
    "transaction_proof_url": transactionProofUrl,
    "holding_status": holdingStatus,
    "payment_status": paymentStatus,
    "is_procurement_locked": isProcurementLocked,
    "is_payment_locked": isPaymentLocked,
    "total_payable_amount": totalPayableAmount,
    "delivery_id": deliveryId,
    "items": items.map((x) => x.toJson()).toList(),
    "settlement_items": settlementItems.map((x) => x.toJson()).toList(),
  };
}

class Farmer {
  int farmerId;
  String fullName;

  Farmer({
    required this.farmerId,
    required this.fullName,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) => Farmer(
    farmerId: _toInt(json["farmer_id"]),
    fullName: _toString(json["full_name"]),
  );

  Map<String, dynamic> toJson() => {
    "farmer_id": farmerId,
    "full_name": fullName,
  };
}

class Product {
  int productId;
  int categoryId;
  String productName;
  String productCode;
  dynamic description;
  String unit;
  dynamic imageUrl;
  bool isSeasonal;
  dynamic seasonStartMonth;
  dynamic seasonEndMonth;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;
  Category category;

  Product({
    required this.productId,
    required this.categoryId,
    required this.productName,
    required this.productCode,
    required this.description,
    required this.unit,
    required this.imageUrl,
    required this.isSeasonal,
    required this.seasonStartMonth,
    required this.seasonEndMonth,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    productId: _toInt(json["product_id"]),
    categoryId: _toInt(json["category_id"]),
    productName: _toString(json["product_name"]),
    productCode: _toString(json["product_code"]),
    description: json["description"],
    unit: _toString(json["unit"], fallback: "KG"),
    imageUrl: json["image_url"],
    isSeasonal: _toBool(json["is_seasonal"]),
    seasonStartMonth: json["season_start_month"],
    seasonEndMonth: json["season_end_month"],
    isActive: _toBool(json["is_active"]),
    createdAt: _toDateTime(json["created_at"]),
    updatedAt: _toDateTime(json["updated_at"]),
    category: Category.fromJson(json["category"] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    "product_id": productId,
    "category_id": categoryId,
    "product_name": productName,
    "product_code": productCode,
    "description": description,
    "unit": unit,
    "image_url": imageUrl,
    "is_seasonal": isSeasonal,
    "season_start_month": seasonStartMonth,
    "season_end_month": seasonEndMonth,
    "is_active": isActive,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "category": category.toJson(),
  };
}

class Category {
  int categoryId;
  String categoryName;
  String categoryCode;
  String description;
  dynamic imageUrl;
  dynamic iconUrl;
  bool isActive;
  int displayOrder;
  DateTime createdAt;
  DateTime updatedAt;

  Category({
    required this.categoryId,
    required this.categoryName,
    required this.categoryCode,
    required this.description,
    required this.imageUrl,
    required this.iconUrl,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    categoryId: _toInt(json["category_id"]),
    categoryName: _toString(json["category_name"]),
    categoryCode: _toString(json["category_code"]),
    description: _toString(json["description"]),
    imageUrl: json["image_url"],
    iconUrl: json["icon_url"],
    isActive: _toBool(json["is_active"]),
    displayOrder: _toInt(json["display_order"]),
    createdAt: _toDateTime(json["created_at"]),
    updatedAt: _toDateTime(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "category_id": categoryId,
    "category_name": categoryName,
    "category_code": categoryCode,
    "description": description,
    "image_url": imageUrl,
    "icon_url": iconUrl,
    "is_active": isActive,
    "display_order": displayOrder,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String _toString(dynamic value, {String fallback = ""}) {
  if (value == null) return fallback;
  return value.toString();
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    return value == "1" || value.toLowerCase() == "true";
  }
  return false;
}

DateTime _toDateTime(dynamic value) {
  if (value == null || value.toString().isEmpty) {
    return DateTime.now();
  }
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

class FarmerProcurementItem {
  int procurementItemId;
  int deliveryId;
  int productId;
  double requestedQuantityKg;
  double collectedQuantityKg;
  double gradeAQtyKg;
  double gradeBQtyKg;
  double gradeCQtyKg;
  double wastageQuantityKg;
  double acceptedQuantityKg;
  String status;
  String? productName;
  String? unit;
  double? expectedPricePerKg;
  String? grade;

  FarmerProcurementItem({
    required this.procurementItemId,
    required this.deliveryId,
    required this.productId,
    required this.requestedQuantityKg,
    required this.collectedQuantityKg,
    required this.gradeAQtyKg,
    required this.gradeBQtyKg,
    required this.gradeCQtyKg,
    required this.wastageQuantityKg,
    required this.acceptedQuantityKg,
    required this.status,
    this.productName,
    this.unit,
    this.expectedPricePerKg,
    this.grade,
  });

  factory FarmerProcurementItem.fromJson(Map<String, dynamic> json) {
    final prod = json["product"] as Map<String, dynamic>?;
    double gradeA = _toDouble(json["grade_a_quantity_kg"]);
    double gradeB = _toDouble(json["grade_b_quantity_kg"]);
    double gradeC = _toDouble(json["grade_c_quantity_kg"]);
    if (gradeA == 0 && gradeB == 0 && gradeC == 0 && json["grade_breakdown"] != null) {
      try {
        final gb = json["grade_breakdown"] is String
            ? jsonDecode(json["grade_breakdown"])
            : json["grade_breakdown"];
        if (gb is List) {
          for (final item in gb) {
            final g = item["grade"]?.toString().toUpperCase();
            final q = _toDouble(item["quantity_kg"]);
            if (g == "A") gradeA = q;
            if (g == "B") gradeB = q;
            if (g == "C") gradeC = q;
          }
        }
      } catch (_) {}
    }

    return FarmerProcurementItem(
      procurementItemId: _toInt(json["procurement_item_id"] ?? json["item_id"]),
      deliveryId: _toInt(json["delivery_id"]),
      productId: _toInt(json["product_id"]),
      requestedQuantityKg: _toDouble(json["requested_quantity_kg"]),
      collectedQuantityKg: _toDouble(json["collected_quantity_kg"]),
      gradeAQtyKg: gradeA,
      gradeBQtyKg: gradeB,
      gradeCQtyKg: gradeC,
      wastageQuantityKg: _toDouble(json["wastage_quantity_kg"]),
      acceptedQuantityKg: _toDouble(json["accepted_quantity_kg"]),
      status: _toString(json["status"]),
      productName: prod != null ? _toString(prod["product_name"]) : null,
      unit: prod != null ? _toString(prod["unit"], fallback: "KG") : "KG",
      expectedPricePerKg: json["expected_price_per_kg"] != null
          ? _toDouble(json["expected_price_per_kg"])
          : null,
      grade: json["grade"] != null ? _toString(json["grade"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "procurement_item_id": procurementItemId,
    "delivery_id": deliveryId,
    "product_id": productId,
    "requested_quantity_kg": requestedQuantityKg,
    "collected_quantity_kg": collectedQuantityKg,
    "grade_a_quantity_kg": gradeAQtyKg,
    "grade_b_quantity_kg": gradeBQtyKg,
    "grade_c_quantity_kg": gradeCQtyKg,
    "wastage_quantity_kg": wastageQuantityKg,
    "accepted_quantity_kg": acceptedQuantityKg,
    "status": status,
    "expected_price_per_kg": expectedPricePerKg,
    "grade": grade,
  };
}

class FarmerSettlementItem {
  int settlementItemId;
  int deliveryId;
  int productId;
  String grade;
  double quantityKg;
  double ratePerKg;
  double subtotal;
  String? productName;

  FarmerSettlementItem({
    required this.settlementItemId,
    required this.deliveryId,
    required this.productId,
    required this.grade,
    required this.quantityKg,
    required this.ratePerKg,
    required this.subtotal,
    this.productName,
  });

  factory FarmerSettlementItem.fromJson(Map<String, dynamic> json) {
    final prod = json["product"] as Map<String, dynamic>?;
    return FarmerSettlementItem(
      settlementItemId: _toInt(json["settlement_item_id"]),
      deliveryId: _toInt(json["delivery_id"]),
      productId: _toInt(json["product_id"]),
      grade: _toString(json["grade"]),
      quantityKg: _toDouble(json["quantity_kg"] ?? json["settled_quantity_kg"]),
      ratePerKg: _toDouble(json["rate_per_kg"] ?? json["price_per_kg"]),
      subtotal: _toDouble(json["subtotal"] ?? json["total_amount"] ?? json["subtotal_amount"]),
      productName: prod != null ? _toString(prod["product_name"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "settlement_item_id": settlementItemId,
    "delivery_id": deliveryId,
    "product_id": productId,
    "grade": grade,
    "quantity_kg": quantityKg,
    "rate_per_kg": ratePerKg,
    "subtotal": subtotal,
  };
}
