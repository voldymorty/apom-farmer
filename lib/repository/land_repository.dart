import 'dart:convert';

import 'package:client/config/api_config.dart';
import 'package:client/models/land_partition_model.dart';
import 'package:client/utils/auth_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LandRepository {
  Future<LandPartitionModel> getLandPartitions({String? status}) async {
    final url = ApiConfig.getLandpartitionUrl(status: status);

    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load land partitions (${response.statusCode}): ${response.body}",
      );
    }

    return landPartitionModelFromJson(response.body);
  }

  Future<void> createLandPartition({
    required int productId,
    required double areaValue,
    required String areaUnit,
    double? expectedYieldValue,
    String expectedYieldUnit = 'kg',
    required DateTime plantationDate,
    required DateTime harvestingDate,
    required String status,
  }) async {
    final url = ApiConfig.getLandpartitionCreateUrl();
    final payload = <String, dynamic>{
      'product_id': productId,
      'area_value': areaValue,
      'area_unit': areaUnit,
      'expected_yield_value': expectedYieldValue,
      'expected_yield_unit': expectedYieldUnit,
      'plantation_date': plantationDate.toIso8601String().split('T')[0],
      'harvesting_date': harvestingDate.toIso8601String().split('T')[0],
      'status': status,
    };

    final response = await AuthClient.postWithAuth(
      url,
      payload,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "Failed to create land partition (${response.statusCode}): ${response.body}",
      );
    }
  }

  Future<void> updateLandPartition({
    required int segmentId,
    required int productId,
    required double areaValue,
    required String areaUnit,
    double? expectedYieldValue,
    String expectedYieldUnit = 'kg',
    required DateTime plantationDate,
    required DateTime harvestingDate,
    required String status,
  }) async {
    final url = ApiConfig.getLandpartitionUpdateUrl(segmentId);
    final payload = <String, dynamic>{
      'product_id': productId,
      'area_value': areaValue,
      'area_unit': areaUnit,
      'expected_yield_value': expectedYieldValue,
      'expected_yield_unit': expectedYieldUnit,
      'plantation_date': plantationDate.toIso8601String().split('T')[0],
      'harvesting_date': harvestingDate.toIso8601String().split('T')[0],
      'status': status,
    };

    final response = await AuthClient.putWithAuth(url, jsonEncode(payload));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "Failed to update land partition (${response.statusCode}): ${response.body}",
      );
    }
  }

  // Updates the farmer's total land. Fallow land is recomputed
  // automatically on the backend; shrinking below the currently
  // cultivated area is rejected there with a clear error message.
  Future<void> updateTotalLand({
    required double totalLand,
    required String landUnit,
  }) async {
    final url = ApiConfig.getEditprofilelUrl();
    final payload = <String, dynamic>{
      'total_land': totalLand,
      'land_unit': landUnit,
    };

    final response = await AuthClient.putWithAuth(url, jsonEncode(payload));

    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Failed to update total land (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  Future<void> deleteLandPartition({required int segmentId}) async {
    final url = ApiConfig.getLandpartitionDeleteUrl(segmentId);
    final response = await AuthClient.deleteWithAuth(url);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        "Failed to delete land partition (${response.statusCode}): ${response.body}",
      );
    }
  }
}

final landRepoProvider = Provider((ref) => LandRepository());

final landPartitionProvider = FutureProvider<LandPartitionModel>((ref) async {
  return ref.watch(landRepoProvider).getLandPartitions(status: 'all');
});