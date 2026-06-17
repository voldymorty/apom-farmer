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
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
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
  );

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
