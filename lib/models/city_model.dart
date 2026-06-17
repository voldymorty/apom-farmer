// To parse this JSON data, do
//
//     final cityDetailsModel = cityDetailsModelFromJson(jsonString);

import 'dart:convert';

CityDetailsModel cityDetailsModelFromJson(String str) => CityDetailsModel.fromJson(json.decode(str));

String cityDetailsModelToJson(CityDetailsModel data) => json.encode(data.toJson());

class CityDetailsModel {
    bool success;
    List<Datum> data;

    CityDetailsModel({
        required this.success,
        required this.data,
    });

    factory CityDetailsModel.fromJson(Map<String, dynamic> json) => CityDetailsModel(
        success: json["success"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class Datum {
    int cityId;
    String cityName;
    int districtId;

    Datum({
        required this.cityId,
        required this.cityName,
        required this.districtId,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        cityId: json["city_id"],
        cityName: json["city_name"],
        districtId: json["district_id"],
    );

    Map<String, dynamic> toJson() => {
        "city_id": cityId,
        "city_name": cityName,
        "district_id": districtId,
    };
}
