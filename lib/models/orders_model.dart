// To parse this JSON data, do
//
//     final ordersModel = ordersModelFromJson(jsonString);

import 'dart:convert';
import 'package:client/models/order_Detail_Model.dart';

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

double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
        return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
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
    String? procurementReceiptUrl;
    String? paymentReceiptUrl;
    String? transactionProofUrl;
    String? holdingStatus;
    String? paymentStatus;
    bool isProcurementLocked;
    bool isPaymentLocked;
    double totalPayableAmount;
    List<FarmerProcurementItem> items;
    List<FarmerSettlementItem> settlementItems;
    String? deliveryStatus;
    String? procurementStatus;
    String? deliveryNumber;

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
        this.procurementReceiptUrl,
        this.paymentReceiptUrl,
        this.transactionProofUrl,
        this.holdingStatus,
        this.paymentStatus,
        this.isProcurementLocked = false,
        this.isPaymentLocked = false,
        this.totalPayableAmount = 0.0,
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

    factory Datum.fromJson(Map<String, dynamic> json) {
        final primaryDelivery = json["pickup_delivery"] as Map<String, dynamic>?;
        final delId = _asInt(primaryDelivery?["delivery_id"] ?? json["delivery_id"]);

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

        return Datum(
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
            isProcurementLocked: _asBool(json["is_procurement_locked"] ?? primaryDelivery?["is_procurement_locked"]),
            isPaymentLocked: _asBool(json["is_payment_locked"] ?? primaryDelivery?["is_payment_locked"]),
            totalPayableAmount: _asDouble(json["total_payable_amount"] ?? primaryDelivery?["total_payable_amount"]),
            items: itemsList,
            settlementItems: settlementList,
            deliveryStatus: _asString(json["delivery_status"] ?? primaryDelivery?["status"]),
            procurementStatus: _asString(json["procurement_status"] ?? primaryDelivery?["procurement_status"]),
            deliveryNumber: _asString(json["delivery_number"] ?? primaryDelivery?["delivery_number"]),
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
        "procurement_receipt_url": procurementReceiptUrl,
        "payment_receipt_url": paymentReceiptUrl,
        "transaction_proof_url": transactionProofUrl,
        "holding_status": holdingStatus,
        "payment_status": paymentStatus,
        "is_procurement_locked": isProcurementLocked,
        "is_payment_locked": isPaymentLocked,
        "total_payable_amount": totalPayableAmount,
        "items": items.map((x) => x.toJson()).toList(),
        "settlement_items": settlementItems.map((x) => x.toJson()).toList(),
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
