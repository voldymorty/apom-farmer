// To parse this JSON data, do
//
//     final districtDetailsModel = districtDetailsModelFromJson(jsonString);

import 'dart:convert';

DistrictDetailsModel districtDetailsModelFromJson(String str) => DistrictDetailsModel.fromJson(json.decode(str));

String districtDetailsModelToJson(DistrictDetailsModel data) => json.encode(data.toJson());

class DistrictDetailsModel {
    bool success;
    List<Datum> data;

    DistrictDetailsModel({
        required this.success,
        required this.data,
    });

    factory DistrictDetailsModel.fromJson(Map<String, dynamic> json) => DistrictDetailsModel(
        success: json["success"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class Datum {
    int districtId;
    String districtName;
    int stateId;

    Datum({
        required this.districtId,
        required this.districtName,
        required this.stateId,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        districtId: json["district_id"],
        districtName: json["district_name"],
        stateId: json["state_id"],
    );

    Map<String, dynamic> toJson() => {
        "district_id": districtId,
        "district_name": districtName,
        "state_id": stateId,
    };
}
