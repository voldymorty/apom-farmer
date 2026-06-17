// To parse this JSON data, do
//
//     final landPartitionModel = landPartitionModelFromJson(jsonString);

import 'dart:convert';

LandPartitionModel landPartitionModelFromJson(String str) => LandPartitionModel.fromJson(json.decode(str));

String landPartitionModelToJson(LandPartitionModel data) => json.encode(data.toJson());

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
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

class LandPartitionModel {
    bool success;
    Summary summary;
    int total;
    List<Datum> data;

    LandPartitionModel({
        required this.success,
        required this.summary,
        required this.total,
        required this.data,
    });

    factory LandPartitionModel.fromJson(Map<String, dynamic> json) => LandPartitionModel(
        success: _asBool(json["success"]),
        summary: Summary.fromJson(json["summary"] ?? const <String, dynamic>{}),
        total: _asInt(json["total"]),
        data:
            json["data"] == null
                ? <Datum>[]
                : List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "summary": summary.toJson(),
        "total": total,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class Datum {
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

    Datum({
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

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
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

class Summary {
    int totalLand;
    String landUnit;
    int allocatedLand;
    int availableLand;
    int activeCount;
    int fallowCount;
    int harvestedCount;
    int totalSegments;

    Summary({
        required this.totalLand,
        required this.landUnit,
        required this.allocatedLand,
        required this.availableLand,
        required this.activeCount,
        required this.fallowCount,
        required this.harvestedCount,
        required this.totalSegments,
    });

    factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        totalLand: _asInt(json["total_land"]),
        landUnit: _asString(json["land_unit"]),
        allocatedLand: _asInt(json["allocated_land"]),
        availableLand: _asInt(json["available_land"]),
        activeCount: _asInt(json["active_count"]),
        fallowCount: _asInt(json["fallow_count"]),
        harvestedCount: _asInt(json["harvested_count"]),
        totalSegments: _asInt(json["total_segments"]),
    );

    Map<String, dynamic> toJson() => {
        "total_land": totalLand,
        "land_unit": landUnit,
        "allocated_land": allocatedLand,
        "available_land": availableLand,
        "active_count": activeCount,
        "fallow_count": fallowCount,
        "harvested_count": harvestedCount,
        "total_segments": totalSegments,
    };
}
