import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:client/config/api_config.dart';
import 'package:client/models/city_model.dart';
import 'package:client/models/district_model.dart';
import 'package:client/models/state_model.dart';
import 'package:client/utils/auth_client.dart';
import 'package:client/utils/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/models/profile_detail_model.dart';

class ProfileSetupRepository {
  Future<ProfileDetailsModel?> getProfileDetail() async {
    final url = ApiConfig.getProfileDetailUrl();
    try {
      final response = await AuthClient.getWithAuth(url);
      if (response.statusCode == 200) {
        return profileDetailsModelFromJson(response.body);
      } else {
        print("DEBUG [ProfileRepo]: Error response status = ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("DEBUG [ProfileRepo]: Error fetching profile: $e");
      return null;
    }
  }

  Future<bool> logout() async {
    final url = ApiConfig.getAuthLogoutUrl();
    try {
      final response = await AuthClient.postWithAuth(url, {});
      await TokenStorage.clearToken();
      return response.statusCode == 200;
    } catch (e) {
      print("DEBUG [ProfileRepo]: Error during logout: $e");
      await TokenStorage.clearToken(); // Clear token anyway
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    final url = ApiConfig.getAccountInactiveUrl();
    try {
      final response = await AuthClient.deleteWithAuth(url);
      if (response.statusCode == 200 || response.statusCode == 204) {
        await TokenStorage.clearToken();
        return true;
      }
      return false;
    } catch (e) {
      print("DEBUG [ProfileRepo]: Error during account deletion: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> setupProfile({
    required String pincode,
    required double totalLand,
    required String stateId,
    required String locationAddress,
    required double latitude,
    required String districtId,
    required String cityId,
    required double longitude,
    required String aadharNumber,
    required String farmName,
    required List<Map<String, dynamic>> landSegments,
    required String landUnit,
    required String fullName,
    required File profilePhoto,
    required File landPhoto,
  }) async {
    final url = ApiConfig.getProfileSetupUrl();

    try {
      final accessToken = await TokenStorage.getToken();
      print("DEBUG [ProfileSetup]: Retrieved Access Token = $accessToken");

      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add authorization header
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Add text fields
      request.fields['pincode'] = pincode;
      request.fields['total_land'] = totalLand.toString();
      request.fields['state_id'] = stateId;
      request.fields['location_address'] = locationAddress;
      request.fields['latitude'] = latitude.toString();
      request.fields['district_id'] = districtId;
      request.fields['city_id'] = cityId;
      request.fields['longitude'] = longitude.toString();
      request.fields['aadhar_number'] = aadharNumber;
      request.fields['farm_name'] = farmName;
      request.fields['land_unit'] = landUnit;
      request.fields['full_name'] = fullName;

      // Add land_segments as JSON string
      request.fields['land_segments'] = jsonEncode(landSegments);

      // Add files
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_photo',
          profilePhoto.path,
          filename: 'profile_photo.png',
          contentType: MediaType('image', 'png'),
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'land_photo',
          landPhoto.path,
          filename: 'land_photo.png',
          contentType: MediaType('image', 'png'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("DEBUG [ProfileSetup]: Error Response = ${response.body}");
        return {
          "success": false,
          "message": jsonDecode(response.body)['message'] ?? "Failed to setup profile: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> editProfile({
    required String stateId,
    required String districtId,
    required String cityId,
    required String fullName,
    required String pincode,
    String? stateName,
    String? districtName,
    String? cityName,
    File? profilePhoto,
  }) async {
    final url = ApiConfig.getEditprofilelUrl();

    try {
      final accessToken = await TokenStorage.getToken();
      print("DEBUG [ProfileEdit]: Retrieved Access Token = $accessToken");

      final request = http.MultipartRequest('PUT', Uri.parse(url));

      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      request.fields['state_id'] = stateId;
      request.fields['district_id'] = districtId;
      request.fields['city_id'] = cityId;
      request.fields['full_name'] = fullName;
      request.fields['pincode'] = pincode;

      if (stateName != null && stateName.isNotEmpty) {
        request.fields['state_name'] = stateName;
      }
      if (districtName != null && districtName.isNotEmpty) {
        request.fields['district_name'] = districtName;
      }
      if (cityName != null && cityName.isNotEmpty) {
        request.fields['city_name'] = cityName;
      }

      if (profilePhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_photo',
            profilePhoto.path,
            filename: 'profile_photo.png',
            contentType: MediaType('image', 'png'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        String? message;
        try {
          message = jsonDecode(response.body)['message']?.toString();
        } catch (_) {}
        return {
          "success": false,
          "message": message ?? "Failed to edit profile: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<StateDetailsModel?> getStates() async {
    final url = ApiConfig.getLocationStatesUrl();
    try {
      final response = await AuthClient.getWithAuth(url);
      if (response.statusCode == 200) {
        return stateDetailsModelFromJson(response.body);
      }
      return null;
    } catch (e) {
      print("DEBUG [ProfileSetup]: Error fetching states: $e");
      return null;
    }
  }

  Future<DistrictDetailsModel?> getDistricts(String stateId, String stateName) async {
    final url = ApiConfig.getLocationDistrictsUrl(stateId, stateName);
    print("DEBUG [ProfileSetup]: Fetching districts from $url");
    try {
      final response = await AuthClient.getWithAuth(url);
      print("DEBUG [ProfileSetup]: Districts response status = ${response.statusCode}");
      if (response.statusCode == 200) {
        return districtDetailsModelFromJson(response.body);
      }
      print("DEBUG [ProfileSetup]: Error response body = ${response.body}");
      return null;
    } catch (e) {
      print("DEBUG [ProfileSetup]: Error fetching districts: $e");
      return null;
    }
  }

  Future<CityDetailsModel?> getCities(String districtId, String districtName) async {
    final url = ApiConfig.getLocationCitiesUrl(districtId, districtName);
    print("DEBUG [ProfileSetup]: Fetching cities from $url");
    try {
      final response = await AuthClient.getWithAuth(url);
      print("DEBUG [ProfileSetup]: Cities response status = ${response.statusCode}");
      if (response.statusCode == 200) {
        return cityDetailsModelFromJson(response.body);
      }
      print("DEBUG [ProfileSetup]: Error response body = ${response.body}");
      return null;
    } catch (e) {
      print("DEBUG [ProfileSetup]: Error fetching cities: $e");
      return null;
    }
  }
}

final profileSetupRepoProvider = Provider((ref) => ProfileSetupRepository());

final statesProvider = FutureProvider<StateDetailsModel?>((ref) async {
  return ref.watch(profileSetupRepoProvider).getStates();
});

final districtsProvider = FutureProvider.family<DistrictDetailsModel?, String>((ref, arg) async {
  final parts = arg.split('|');
  return ref.watch(profileSetupRepoProvider).getDistricts(parts[0], parts[1]);
});

final citiesProvider = FutureProvider.family<CityDetailsModel?, String>((ref, arg) async {
  final parts = arg.split('|');
  return ref.watch(profileSetupRepoProvider).getCities(parts[0], parts[1]);
});

final profileProvider = FutureProvider<ProfileDetailsModel?>((ref) async {
  return ref.watch(profileSetupRepoProvider).getProfileDetail();
});
