import 'dart:convert';

DashboardModel dashboardModelFromJson(String str) =>
    DashboardModel.fromJson(json.decode(str));

class DashboardModel {
  final bool success;
  final DashboardData data;

  DashboardModel({required this.success, required this.data});

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
        success: json["success"] == true,
        data: DashboardData.fromJson(
            (json["data"] ?? const {}) as Map<String, dynamic>),
      );
}

class DashboardData {
  final int farmerId;
  final String fullName;
  final String profilePhotoUrl;
  final String landPhotoUrl;
  final String farmName;
  final FarmerLocation location;
  final String totalLand;
  final String landUnit;
  final String allocatedLand;
  final String availableLand;
  final int totalSegments;
  final WeeklyChart weeklyPickups;

  // stat cards
  final int availableCrops;
  final double totalSoldTons;
  final double monthlyEarnings;
  final int pendingPickups;
  final double totalEarnings;

  // demand
  final int currentMonth;
  final String currentMonthName;
  final String topSuggestedCrop;
  final Map<int, MonthDemand> allMonthlyDemand;
  final MonthDemand currentMonthDemand;

  DashboardData({
    required this.farmerId,
    required this.fullName,
    required this.profilePhotoUrl,
    required this.landPhotoUrl,
    required this.farmName,
    required this.location,
    required this.totalLand,
    required this.landUnit,
    required this.allocatedLand,
    required this.availableLand,
    required this.totalSegments,
    required this.availableCrops,
    required this.totalSoldTons,
    required this.monthlyEarnings,
    required this.pendingPickups,
    required this.totalEarnings,
    required this.currentMonth,
    required this.currentMonthName,
    required this.topSuggestedCrop,
    required this.allMonthlyDemand,
    required this.currentMonthDemand,
    required this.weeklyPickups,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // all_monthly_demand keys come as int or string — normalise to int
    final rawDemand =
        (json["all_monthly_demand"] as Map<String, dynamic>?) ?? {};
    final allDemand = <int, MonthDemand>{};
    rawDemand.forEach((k, v) {
      final monthIdx = int.tryParse(k.toString());
      if (monthIdx != null && v is Map<String, dynamic>) {
        allDemand[monthIdx] = MonthDemand.fromJson(v);
      }
    });

    return DashboardData(
      farmerId: _asInt(json["farmer_id"]),
      fullName: _asString(json["full_name"]),
      profilePhotoUrl: _asString(json["profile_photo_url"]),
      landPhotoUrl: _asString(json["land_photo_url"]),
      farmName: _asString(json["farm_name"]),
      location: FarmerLocation.fromJson(
          (json["location"] ?? const {}) as Map<String, dynamic>),
      totalLand: json["total_land"]?.toString() ?? "0",
      landUnit: _asString(json["land_unit"]),
      allocatedLand: json["allocated_land"]?.toString() ?? "0",
      availableLand: json["available_land"]?.toString() ?? "0",
      totalSegments: _asInt(json["total_segments"]),
      availableCrops: _asInt(json["available_crops"]),
      totalSoldTons: _asDouble(json["total_sold_tons"]) ?? 0,
      monthlyEarnings: _asDouble(json["monthly_earnings"]) ?? 0,
      pendingPickups: _asInt(json["pending_pickups"]),
      totalEarnings: _asDouble(json["total_earnings"]) ?? 0,
      currentMonth: _asInt(json["current_month"]),
      currentMonthName: _asString(json["current_month_name"]),
      topSuggestedCrop: _asString(json["top_suggested_crop"]),
      allMonthlyDemand: allDemand,
      currentMonthDemand: MonthDemand.fromJson(
          (json["current_month_demand"] ?? const {}) as Map<String, dynamic>),
      weeklyPickups: WeeklyChart.fromJson(
          (json["weekly_pickups"] ?? const {}) as Map<String, dynamic>),
    );
  }
}

class WeeklyChart {
  final List<String> labels;
  final List<double> data;

  WeeklyChart({required this.labels, required this.data});

  factory WeeklyChart.fromJson(Map<String, dynamic> json) => WeeklyChart(
        labels: (json["labels"] as List<dynamic>?)
                ?.map((x) => x.toString())
                .toList() ??
            const [],
        data: (json["data"] as List<dynamic>?)
                ?.map((x) => _asDouble(x) ?? 0)
                .toList() ??
            const [],
      );

  double get maxValue =>
      data.isEmpty ? 0 : data.reduce((a, b) => a > b ? a : b);

  bool get isAllZero => data.every((v) => v == 0);
}

/// Represents the demand breakdown for one month.
class MonthDemand {
  final List<CropSlice> slices;
  final bool isLive;
  final int? dataYear;

  MonthDemand({
    required this.slices,
    required this.isLive,
    this.dataYear,
  });

  factory MonthDemand.fromJson(Map<String, dynamic> json) {
    final rawSlices = (json["slices"] as List<dynamic>?) ?? [];
    return MonthDemand(
      slices: rawSlices
          .map((s) => CropSlice.fromJson(s as Map<String, dynamic>))
          .toList(),
      isLive: json["is_live"] == true,
      dataYear: json["data_year"] != null
          ? int.tryParse(json["data_year"].toString())
          : null,
    );
  }

  /// Convenience: { "Tomatoes": 0.30, "Carrots": 0.25, ... } for PieChartPainter
  Map<String, double> get ratioMap =>
      {for (final s in slices) s.crop: s.ratio};

  String get topCrop => slices.isNotEmpty ? slices.first.crop : "N/A";
}

class CropSlice {
  final String crop;
  final double ratio;
  final double? totalKg;
  final int? orderCount;

  CropSlice({
    required this.crop,
    required this.ratio,
    this.totalKg,
    this.orderCount,
  });

  factory CropSlice.fromJson(Map<String, dynamic> json) => CropSlice(
        crop: _asString(json["crop"]),
        ratio: _asDouble(json["ratio"]) ?? 0,
        totalKg: _asDouble(json["total_kg"]),
        orderCount:
            json["order_count"] != null ? _asInt(json["order_count"]) : null,
      );
}

class FarmerLocation {
  final LocationPart? state;
  final LocationPart? district;
  final LocationPart? city;
  final String pincode;

  FarmerLocation({this.state, this.district, this.city, required this.pincode});

  factory FarmerLocation.fromJson(Map<String, dynamic> json) => FarmerLocation(
        state: json["state"] != null
            ? LocationPart.fromJson(json["state"] as Map<String, dynamic>)
            : null,
        district: json["district"] != null
            ? LocationPart.fromJson(json["district"] as Map<String, dynamic>)
            : null,
        city: json["city"] != null
            ? LocationPart.fromJson(json["city"] as Map<String, dynamic>)
            : null,
        pincode: json["pincode"]?.toString() ?? "",
      );
}

class LocationPart {
  final int id;
  final String name;

  LocationPart({required this.id, required this.name});

  factory LocationPart.fromJson(Map<String, dynamic> json) {
    // works for state/district/city — each has a different id key name
    final id = _asInt(
      json["state_id"] ?? json["district_id"] ?? json["city_id"],
    );
    final name = _asString(
      json["state_name"] ?? json["district_name"] ?? json["city_name"],
    );
    return LocationPart(id: id, name: name);
  }
}

// ── helpers ──────────────────────────────────────────────────────
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