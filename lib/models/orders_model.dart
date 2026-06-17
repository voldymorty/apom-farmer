// To parse this JSON data, do
//
//     final ordersModel = ordersModelFromJson(jsonString);

import 'dart:convert';

OrdersModel ordersModelFromJson(String str) => OrdersModel.fromJson(json.decode(str));

String ordersModelToJson(OrdersModel data) => json.encode(data.toJson());

int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
        return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }
    return 0;
}

String _asString(dynamic value) => value?.toString() ?? "";

bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value?.toString().toLowerCase();
    return s == "true" || s == "1";
}

DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    return parsed;
}

List<String> _asStringList(dynamic value) {
  if (value == null) return <String>[];

  if (value is List) {
    return value
        .map((e) => e?.toString() ?? "")
        .where((e) => e.isNotEmpty)
        .toList();
  }

  if (value is String) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return <String>[];

    // Fix for stringified JSON array
    if (trimmed.startsWith("[") && trimmed.endsWith("]")) {
      try {
        final decoded = json.decode(trimmed);
        if (decoded is List) {
          return decoded
              .map((e) => e?.toString() ?? "")
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }

    return <String>[trimmed];
  }

  return <String>[value.toString()];
}

class OrdersModel {
    bool success;
    int total;
    List<Datum> data;

    OrdersModel({
        required this.success,
        required this.total,
        required this.data,
    });

    factory OrdersModel.fromJson(Map<String, dynamic> json) => OrdersModel(
        success: _asBool(json["success"]),
        total: _asInt(json["total"]),
        data:
            json["data"] == null
                ? <Datum>[]
                : List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "total": total,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class Datum {
    int cropId;
    int farmerId;
    dynamic partitionId;
    int productId;
    String quantityKg;
    String grade;
    String expectedPricePerKg;
    DateTime? harvestDate;
    bool isReady;
    List<String> cropPhotoUrls;
    String status;
    dynamic remarks;
    DateTime? createdAt;
    DateTime? updatedAt;
    Product product;

    Datum({
        required this.cropId,
        required this.farmerId,
        required this.partitionId,
        required this.productId,
        required this.quantityKg,
        required this.grade,
        required this.expectedPricePerKg,
        required this.harvestDate,
        required this.isReady,
        required this.cropPhotoUrls,
        required this.status,
        required this.remarks,
        required this.createdAt,
        required this.updatedAt,
        required this.product,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        cropId: _asInt(json["crop_id"]),
        farmerId: _asInt(json["farmer_id"]),
        partitionId: json["partition_id"],
        productId: _asInt(json["product_id"]),
        quantityKg: _asString(json["quantity_kg"]),
        grade: _asString(json["grade"]),
        expectedPricePerKg: _asString(json["expected_price_per_kg"]),
        harvestDate: _asDateTime(json["harvest_date"]),
        isReady: _asBool(json["is_ready"]),
        cropPhotoUrls: _asStringList(
            json["crop_photo_urls"] ?? json["crop_photo_url"],
        ),
        status: _asString(json["status"]),
        remarks: json["remarks"],
        createdAt: _asDateTime(json["created_at"]),
        updatedAt: _asDateTime(json["updated_at"]),
        product: Product.fromJson(json["product"] ?? const <String, dynamic>{}),
    );

    Map<String, dynamic> toJson() => {
        "crop_id": cropId,
        "farmer_id": farmerId,
        "partition_id": partitionId,
        "product_id": productId,
        "quantity_kg": quantityKg,
        "grade": grade,
        "expected_price_per_kg": expectedPricePerKg,
        "harvest_date":
            harvestDate == null
                ? null
                : "${harvestDate!.year.toString().padLeft(4, '0')}-${harvestDate!.month.toString().padLeft(2, '0')}-${harvestDate!.day.toString().padLeft(2, '0')}",
        "is_ready": isReady,
        "crop_photo_urls": cropPhotoUrls,
        "status": status,
        "remarks": remarks,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "product": product.toJson(),
    };
}

class Product {
    int productId;
    String productName;
    String unit;
    dynamic imageUrl;
    Category category;

    Product({
        required this.productId,
        required this.productName,
        required this.unit,
        required this.imageUrl,
        required this.category,
    });

    factory Product.fromJson(Map<String, dynamic> json) => Product(
        productId: _asInt(json["product_id"]),
        productName: _asString(json["product_name"]),
        unit: _asString(json["unit"]),
        imageUrl: json["image_url"],
        category: Category.fromJson(json["category"] ?? const <String, dynamic>{}),
    );

    Map<String, dynamic> toJson() => {
        "product_id": productId,
        "product_name": productName,
        "unit": unit,
        "image_url": imageUrl,
        "category": category.toJson(),
    };
}

class Category {
    int categoryId;
    String categoryName;

    Category({
        required this.categoryId,
        required this.categoryName,
    });

    factory Category.fromJson(Map<String, dynamic> json) => Category(
        categoryId: _asInt(json["category_id"]),
        categoryName: _asString(json["category_name"]),
    );

    Map<String, dynamic> toJson() => {
        "category_id": categoryId,
        "category_name": categoryName,
    };
}
