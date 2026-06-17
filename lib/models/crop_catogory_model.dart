// To parse this JSON data, do
//
//     final cropCatogoryModel = cropCatogoryModelFromJson(jsonString);

import 'dart:convert';

CropCatogoryModel cropCatogoryModelFromJson(String str) => CropCatogoryModel.fromJson(json.decode(str));

String cropCatogoryModelToJson(CropCatogoryModel data) => json.encode(data.toJson());

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}

String _asString(dynamic value) => value?.toString() ?? "";

class CropCatogoryModel {
    bool success;
    List<Datum> data;

    CropCatogoryModel({
        required this.success,
        required this.data,
    });

    factory CropCatogoryModel.fromJson(Map<String, dynamic> json) => CropCatogoryModel(
        success: json["success"] == true,
        data:
            json["data"] == null
                ? <Datum>[]
                : List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class Datum {
    int categoryId;
    String categoryName;
    String categoryCode;
    String iconUrl;
    List<Product> products;

    Datum({
        required this.categoryId,
        required this.categoryName,
        required this.categoryCode,
        required this.iconUrl,
        required this.products,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        categoryId: _asInt(json["category_id"]),
        categoryName: _asString(json["category_name"]),
        categoryCode: _asString(json["category_code"]),
        iconUrl: _asString(json["icon_url"]),
        products:
            json["products"] == null
                ? <Product>[]
                : List<Product>.from(
                  json["products"].map((x) => Product.fromJson(x)),
                ),
    );

    Map<String, dynamic> toJson() => {
        "category_id": categoryId,
        "category_name": categoryName,
        "category_code": categoryCode,
        "icon_url": iconUrl,
        "products": List<dynamic>.from(products.map((x) => x.toJson())),
    };
}

class Product {
    int productId;
    String productName;
    String unit;

    Product({
        required this.productId,
        required this.productName,
        required this.unit,
    });

    factory Product.fromJson(Map<String, dynamic> json) => Product(
        productId: _asInt(json["product_id"]),
        productName: _asString(json["product_name"]),
        unit: _asString(json["unit"]),
    );

    Map<String, dynamic> toJson() => {
        "product_id": productId,
        "product_name": productName,
        "unit": unit,
    };
}
