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
    required String cropName,
    required double areaValue,
    required String areaUnit,
    required DateTime plantationDate,
    required DateTime harvestingDate,
    required String status,
  }) async {
    final url = ApiConfig.getLandpartitionCreateUrl();
    final payload = <String, dynamic>{
      'crop_name': cropName,
      'area_value': areaValue,
      'area_unit': areaUnit,
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
    required String cropName,
    required double areaValue,
    required String areaUnit,
    required DateTime plantationDate,
    required DateTime harvestingDate,
    required String status,
  }) async {
    final url = ApiConfig.getLandpartitionUpdateUrl(segmentId);
    final payload = <String, dynamic>{
      'crop_name': cropName,
      'area_value': areaValue,
      'area_unit': areaUnit,
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
