import 'dart:convert';

import 'package:client/config/api_config.dart';
import 'package:client/models/orders_model.dart';
import 'package:client/utils/auth_client.dart';

class OrdersRepository {
  Future<OrdersModel> getOrders({String? status}) async {
    final url = ApiConfig.getOrdersUrl(status: status);
    final response = await AuthClient.getWithAuth(url);

    final subscriptionError = AuthClient.subscriptionErrorFrom(response);
    if (subscriptionError != null) throw subscriptionError;

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load orders (${response.statusCode}): ${response.body}",
      );
    }

    return ordersModelFromJson(response.body);
  }

  Future<void> updateOrder({
    required int cropId,
    required String quantityKg,
    required String expectedPricePerKg,
    required String grade,
    required DateTime harvestDate,
  }) async {
    final url = ApiConfig.getOrdersUpdateUrl(cropId);
    final payload = <String, dynamic>{
      'quantity_kg': quantityKg,
      'expected_price_per_kg': expectedPricePerKg,
      'grade': grade,
      'harvest_date': harvestDate.toIso8601String().split('T')[0],
    };

    final response = await AuthClient.putWithAuth(url, jsonEncode(payload));

    final subscriptionError = AuthClient.subscriptionErrorFrom(response);
    if (subscriptionError != null) throw subscriptionError;

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "Failed to update order (${response.statusCode}): ${response.body}",
      );
    }
  }

  Future<void> deleteOrder({required int cropId}) async {
    final url = ApiConfig.getOrdersDeleteUrl(cropId);
    final response = await AuthClient.deleteWithAuth(url);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        "Failed to delete order (${response.statusCode}): ${response.body}",
      );
    }
  }
}