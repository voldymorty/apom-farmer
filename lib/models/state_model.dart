// To parse this JSON data, do
//
//     final stateDetailsModel = stateDetailsModelFromJson(jsonString);

import 'dart:convert';

StateDetailsModel stateDetailsModelFromJson(String str) => StateDetailsModel.fromJson(json.decode(str));

String stateDetailsModelToJson(StateDetailsModel data) => json.encode(data.toJson());

class StateDetailsModel {
    bool success;
    List<Datum> data;

    StateDetailsModel({
        required this.success,
        required this.data,
    });

    factory StateDetailsModel.fromJson(Map<String, dynamic> json) => StateDetailsModel(
        success: json["success"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class Datum {
    int stateId;
    String stateName;
    String stateCode;

    Datum({
        required this.stateId,
        required this.stateName,
        required this.stateCode,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        stateId: json["state_id"],
        stateName: json["state_name"],
        stateCode: json["state_code"],
    );

    Map<String, dynamic> toJson() => {
        "state_id": stateId,
        "state_name": stateName,
        "state_code": stateCode,
    };
}
