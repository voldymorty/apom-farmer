import 'dart:io';

import 'package:client/config/api_config.dart';
import 'package:client/models/crop_catogory_model.dart';
import 'package:client/utils/auth_client.dart';
import 'package:client/utils/token_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AddPickupRepository {
  Future<CropCatogoryModel> getCropCategories() async {
    final url = ApiConfig.getCropcatogoryUrl();
    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load crop categories (${response.statusCode}): ${response.body}",
      );
    }

    return cropCatogoryModelFromJson(response.body);
  }

  Future<void> submitPickup({
    required int productId,
    required double quantity,
    required double expectedPrice,
    required String grade,
    required DateTime harvestDate,
    required List<File> photos,
    String? remarks,
  }) async {
    final url = ApiConfig.getAddpickupUrl();
    final accessToken = await TokenStorage.getToken();

    final request = http.MultipartRequest('POST', Uri.parse(url));

    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    request.fields['product_id'] = productId.toString();
    request.fields['quantity_kg'] = quantity.toString();
    request.fields['expected_price_per_kg'] = expectedPrice.toString();
    request.fields['grade'] = grade;
    request.fields['harvest_date'] = harvestDate.toIso8601String().split('T')[0];

    if (remarks != null && remarks.trim().isNotEmpty) {
      request.fields['remarks'] = remarks.trim();
    }

    for (var i = 0; i < photos.length; i++) {
      final file = photos[i];
      request.files.add(
        await http.MultipartFile.fromPath(
          'crop_photos',
          file.path,
          filename: 'crop_photos_$i.png',
          contentType: MediaType('image', 'png'),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "Failed to submit pickup (${response.statusCode}): ${response.body}",
      );
    }
  }
}
