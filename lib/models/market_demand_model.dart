import 'dart:convert';
import 'dashboard_model.dart' show CropSlice;  // only CropSlice, no helpers

MarketDemandModel marketDemandModelFromJson(String str) =>
    MarketDemandModel.fromJson(json.decode(str));

class MarketDemandModel {
  final bool success;
  final MarketDemandData data;

  MarketDemandModel({required this.success, required this.data});

  factory MarketDemandModel.fromJson(Map<String, dynamic> json) =>
      MarketDemandModel(
        success: json["success"] == true,
        data: MarketDemandData.fromJson(
            (json["data"] ?? const {}) as Map<String, dynamic>),
      );
}

class MarketDemandData {
  final int month;
  final String monthName;
  final String topSuggestedCrop;
  final bool isLive;
  final int? dataYear;
  final String insightLabel;
  final List<CropSlice> slices;

  MarketDemandData({
    required this.month,
    required this.monthName,
    required this.topSuggestedCrop,
    required this.isLive,
    this.dataYear,
    required this.insightLabel,
    required this.slices,
  });

  factory MarketDemandData.fromJson(Map<String, dynamic> json) {
    final rawSlices = (json["slices"] as List<dynamic>?) ?? [];
    return MarketDemandData(
      month:             _asInt(json["month"]),
      monthName:         _asString(json["month_name"]),
      topSuggestedCrop:  _asString(json["top_suggested_crop"]),
      isLive:            json["is_live"] == true,
      dataYear:          json["data_year"] != null
          ? int.tryParse(json["data_year"].toString())
          : null,
      insightLabel:      _asString(json["insight_label"]),
      slices:            rawSlices
          .map((s) => CropSlice.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, double> get ratioMap =>
      {for (final s in slices) s.crop: s.ratio};
}

// ── local helpers (mirrors dashboard_model.dart) ────────────────
int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

String _asString(dynamic v) => (v ?? '').toString();