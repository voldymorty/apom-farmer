import 'package:client/config/api_config.dart';
import 'package:client/models/profile_detail_model.dart';
import 'package:client/utils/auth_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileRepository {
  Future<ProfileDetailsModel> getProfileDetails() async {
    final url = ApiConfig.getProfileDetailUrl();

    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load profile details (${response.statusCode}): ${response.body}",
      );
    }

    return profileDetailsModelFromJson(response.body);
  }
}

final profileRepoProvider = Provider((ref) => ProfileRepository());

final profileDetailsProvider = FutureProvider<ProfileDetailsModel>((ref) async {
  return ref.watch(profileRepoProvider).getProfileDetails();
});
