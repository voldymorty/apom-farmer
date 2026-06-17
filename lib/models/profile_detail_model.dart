// To parse this JSON data, do
//
//     final profileDetailsModel = profileDetailsModelFromJson(jsonString);

import 'dart:convert';

ProfileDetailsModel profileDetailsModelFromJson(String str) => ProfileDetailsModel.fromJson(json.decode(str));

String profileDetailsModelToJson(ProfileDetailsModel data) => json.encode(data.toJson());

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? "") ?? 0;
}

String _asString(dynamic value) => value?.toString() ?? "";

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value?.toString().toLowerCase();
  return s == "true" || s == "1";
}

DateTime _asDateTime(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? "") ??
    DateTime.fromMillisecondsSinceEpoch(0);

class ProfileDetailsModel {
    bool success;
    Data data;

    ProfileDetailsModel({
        required this.success,
        required this.data,
    });

    factory ProfileDetailsModel.fromJson(Map<String, dynamic> json) => ProfileDetailsModel(
        success: _asBool(json["success"]),
        data: Data.fromJson(json["data"] ?? const <String, dynamic>{}),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": data.toJson(),
    };
}

class Data {
    int userId;
    String mobileNumber;
    String role;
    bool isActive;
    bool isVerified;
    bool profileComplete;
    dynamic email;
    DateTime lastLogin;
    String fcmToken;
    DateTime createdAt;
    DateTime updatedAt;
    Profile profile;

    Data({
        required this.userId,
        required this.mobileNumber,
        required this.role,
        required this.isActive,
        required this.isVerified,
        required this.profileComplete,
        required this.email,
        required this.lastLogin,
        required this.fcmToken,
        required this.createdAt,
        required this.updatedAt,
        required this.profile,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        userId: _asInt(json["user_id"]),
        mobileNumber: _asString(json["mobile_number"]),
        role: _asString(json["role"]),
        isActive: _asBool(json["is_active"]),
        isVerified: _asBool(json["is_verified"]),
        profileComplete: _asBool(json["profile_complete"]),
        email: json["email"],
        lastLogin: _asDateTime(json["last_login"]),
        fcmToken: _asString(json["fcm_token"]),
        createdAt: _asDateTime(json["created_at"]),
        updatedAt: _asDateTime(json["updated_at"]),
        profile: Profile.fromJson(json["profile"] ?? const <String, dynamic>{}),
    );

    Map<String, dynamic> toJson() => {
        "user_id": userId,
        "mobile_number": mobileNumber,
        "role": role,
        "is_active": isActive,
        "is_verified": isVerified,
        "profile_complete": profileComplete,
        "email": email,
        "last_login": lastLogin.toIso8601String(),
        "fcm_token": fcmToken,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "profile": profile.toJson(),
    };
}

class Profile {
    int farmerId;
    int userId;
    String fullName;
    String aadharNumber;
    String farmName;
    String locationAddress;
    int stateId;
    int districtId;
    int cityId;
    String pincode;
    String latitude;
    String longitude;
    String totalLand;
    String landUnit;
    String allocatedLand;
    String availableLand;
    dynamic profilePhotoUrl;
    dynamic landPhotoUrl;
    int totalSupplies;
    String totalEarnings;
    DateTime createdAt;
    DateTime updatedAt;
    List<LandSegment> landSegments;
    StateInfo stateInfo;
    DistrictInfo districtInfo;
    CityInfo cityInfo;

    Profile({
        required this.farmerId,
        required this.userId,
        required this.fullName,
        required this.aadharNumber,
        required this.farmName,
        required this.locationAddress,
        required this.stateId,
        required this.districtId,
        required this.cityId,
        required this.pincode,
        required this.latitude,
        required this.longitude,
        required this.totalLand,
        required this.landUnit,
        required this.allocatedLand,
        required this.availableLand,
        required this.profilePhotoUrl,
        required this.landPhotoUrl,
        required this.totalSupplies,
        required this.totalEarnings,
        required this.createdAt,
        required this.updatedAt,
        required this.landSegments,
        required this.stateInfo,
        required this.districtInfo,
        required this.cityInfo,
    });

    factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        farmerId: _asInt(json["farmer_id"]),
        userId: _asInt(json["user_id"]),
        fullName: _asString(json["full_name"]),
        aadharNumber: _asString(json["aadhar_number"]),
        farmName: _asString(json["farm_name"]),
        locationAddress: _asString(json["location_address"]),
        stateId: _asInt(json["state_id"]),
        districtId: _asInt(json["district_id"]),
        cityId: _asInt(json["city_id"]),
        pincode: _asString(json["pincode"]),
        latitude: _asString(json["latitude"]),
        longitude: _asString(json["longitude"]),
        totalLand: _asString(json["total_land"]),
        landUnit: _asString(json["land_unit"]),
        allocatedLand: _asString(json["allocated_land"]),
        availableLand: _asString(json["available_land"]),
        profilePhotoUrl: json["profile_photo_url"],
        landPhotoUrl: json["land_photo_url"],
        totalSupplies: _asInt(json["total_supplies"]),
        totalEarnings: _asString(json["total_earnings"]),
        createdAt: _asDateTime(json["created_at"]),
        updatedAt: _asDateTime(json["updated_at"]),
        landSegments:
            json["land_segments"] == null
                ? <LandSegment>[]
                : List<LandSegment>.from(
                  json["land_segments"].map((x) => LandSegment.fromJson(x)),
                ),
        stateInfo:
            json["state_info"] == null
                ? StateInfo(stateId: 0, stateName: "", stateCode: "")
                : StateInfo.fromJson(json["state_info"]),
        districtInfo:
            json["district_info"] == null
                ? DistrictInfo(districtId: 0, districtName: "")
                : DistrictInfo.fromJson(json["district_info"]),
        cityInfo:
            json["city_info"] == null
                ? CityInfo(cityId: 0, cityName: "")
                : CityInfo.fromJson(json["city_info"]),
    );

    Map<String, dynamic> toJson() => {
        "farmer_id": farmerId,
        "user_id": userId,
        "full_name": fullName,
        "aadhar_number": aadharNumber,
        "farm_name": farmName,
        "location_address": locationAddress,
        "state_id": stateId,
        "district_id": districtId,
        "city_id": cityId,
        "pincode": pincode,
        "latitude": latitude,
        "longitude": longitude,
        "total_land": totalLand,
        "land_unit": landUnit,
        "allocated_land": allocatedLand,
        "available_land": availableLand,
        "profile_photo_url": profilePhotoUrl,
        "land_photo_url": landPhotoUrl,
        "total_supplies": totalSupplies,
        "total_earnings": totalEarnings,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "land_segments": List<dynamic>.from(landSegments.map((x) => x.toJson())),
        "state_info": stateInfo.toJson(),
        "district_info": districtInfo.toJson(),
        "city_info": cityInfo.toJson(),
    };
}

class CityInfo {
    int cityId;
    String cityName;

    CityInfo({
        required this.cityId,
        required this.cityName,
    });

    factory CityInfo.fromJson(Map<String, dynamic> json) => CityInfo(
        cityId: _asInt(json["city_id"]),
        cityName: _asString(json["city_name"]),
    );

    Map<String, dynamic> toJson() => {
        "city_id": cityId,
        "city_name": cityName,
    };
}

class DistrictInfo {
    int districtId;
    String districtName;

    DistrictInfo({
        required this.districtId,
        required this.districtName,
    });

    factory DistrictInfo.fromJson(Map<String, dynamic> json) => DistrictInfo(
        districtId: _asInt(json["district_id"]),
        districtName: _asString(json["district_name"]),
    );

    Map<String, dynamic> toJson() => {
        "district_id": districtId,
        "district_name": districtName,
    };
}

class LandSegment {
    int segmentId;
    int farmerId;
    String cropName;
    String areaValue;
    String areaUnit;
    DateTime plantationDate;
    DateTime harvestingDate;
    String status;
    DateTime createdAt;
    DateTime updatedAt;

    LandSegment({
        required this.segmentId,
        required this.farmerId,
        required this.cropName,
        required this.areaValue,
        required this.areaUnit,
        required this.plantationDate,
        required this.harvestingDate,
        required this.status,
        required this.createdAt,
        required this.updatedAt,
    });

    factory LandSegment.fromJson(Map<String, dynamic> json) => LandSegment(
        segmentId: _asInt(json["segment_id"]),
        farmerId: _asInt(json["farmer_id"]),
        cropName: _asString(json["crop_name"]),
        areaValue: _asString(json["area_value"]),
        areaUnit: _asString(json["area_unit"]),
        plantationDate: _asDateTime(json["plantation_date"]),
        harvestingDate: _asDateTime(json["harvesting_date"]),
        status: _asString(json["status"]),
        createdAt: _asDateTime(json["created_at"]),
        updatedAt: _asDateTime(json["updated_at"]),
    );

    Map<String, dynamic> toJson() => {
        "segment_id": segmentId,
        "farmer_id": farmerId,
        "crop_name": cropName,
        "area_value": areaValue,
        "area_unit": areaUnit,
        "plantation_date": "${plantationDate.year.toString().padLeft(4, '0')}-${plantationDate.month.toString().padLeft(2, '0')}-${plantationDate.day.toString().padLeft(2, '0')}",
        "harvesting_date": "${harvestingDate.year.toString().padLeft(4, '0')}-${harvestingDate.month.toString().padLeft(2, '0')}-${harvestingDate.day.toString().padLeft(2, '0')}",
        "status": status,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
    };
}

class StateInfo {
    int stateId;
    String stateName;
    String stateCode;

    StateInfo({
        required this.stateId,
        required this.stateName,
        required this.stateCode,
    });

    factory StateInfo.fromJson(Map<String, dynamic> json) => StateInfo(
        stateId: _asInt(json["state_id"]),
        stateName: _asString(json["state_name"]),
        stateCode: _asString(json["state_code"]),
    );

    Map<String, dynamic> toJson() => {
        "state_id": stateId,
        "state_name": stateName,
        "state_code": stateCode,
    };
}
