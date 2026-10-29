import 'package:client/global/colortheme.dart';
import 'package:client/models/crop_catogory_model.dart' as crop_catalog;
import 'package:client/models/land_partition_model.dart';
import 'package:client/repository/add_pickup_repository.dart';
import 'package:client/repository/land_repository.dart';
import 'package:client/widgets/crop_picker_sheet.dart';
import 'package:client/widgets/custom_app_bar.dart';
import 'package:client/widgets/custom_snackbar.dart';
import 'package:client/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LandManageScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> initialParcels;
  final double totalLand;
  final String landUnit;

  const LandManageScreen({
    super.key,
    this.initialParcels = const [],
    this.totalLand = 0,
    this.landUnit = 'Acres',
  });

  @override
  ConsumerState<LandManageScreen> createState() => _LandManageScreenState();
}

class _LandManageScreenState extends ConsumerState<LandManageScreen> {
  String _selectedFilter = 'All';
  late List<Map<String, dynamic>> _parcels;
  int _nextParcelId = 1;
  String? _apiLandUnit;
  bool _apiSynced = false;
  Summary? _summary;

  List<crop_catalog.Datum> _cropCategories = [];
  bool _cropCategoriesLoading = false;

  @override
  void initState() {
    super.initState();
    _parcels = _buildInitialParcels();
    _ensureParcelIds();
    _loadCropCategories();
  }

  Future<void> _loadCropCategories() async {
    setState(() => _cropCategoriesLoading = true);
    try {
      final repo = AddPickupRepository();
      final result = await repo.getCropCategories();
      if (mounted) setState(() => _cropCategories = result.data);
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Failed to load crops: $e');
    } finally {
      if (mounted) setState(() => _cropCategoriesLoading = false);
    }
  }

  List<Map<String, dynamic>> _buildInitialParcels() {
    if (widget.initialParcels.isEmpty) return <Map<String, dynamic>>[];
    return widget.initialParcels.map((raw) {
      final crop = (raw['crop'] ?? 'Unknown Crop').toString();
      final areaValue = (raw['areaValue'] as num?)?.toDouble() ?? 0.0;
      final areaUnit = _normalizeUnit(
        (raw['areaUnit'] ?? widget.landUnit).toString(),
      );
      final parsedStatus = _normalizeStatus(raw['status']?.toString() ?? '');
      return <String, dynamic>{
        'name': '$crop Plot',
        'areaValue': areaValue,
        'areaUnit': areaUnit,
        'crop': crop,
        'productId': raw['product_id'] ?? raw['productId'],
        'expectedYieldValue': (raw['expected_yield_value'] as num?)?.toDouble(),
        'expectedYieldUnit': raw['expected_yield_unit']?.toString() ?? 'kg',
        'status': parsedStatus,
        'updated': 'Imported from partition',
        'isLocal': true,
        'plantationDate': raw['plantationDate'],
        'harvestingDate': raw['harvestingDate'],
      };
    }).toList();
  }

  double _parseAreaValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _normalizeUnit(String? unit) {
    final raw = unit?.trim() ?? '';
    if (raw.isEmpty) return 'Acres';
    final lower = raw.toLowerCase();
    switch (lower) {
      case 'acre':
      case 'acres':
        return 'Acres';
      case 'hectare':
      case 'hectares':
        return 'Hectares';
      case 'cent':
      case 'cents':
        return 'Cent';
      default:
        return '${raw[0].toUpperCase()}${raw.substring(1)}';
    }
  }

  String _unitToApi(String unit) {
    switch (unit.trim().toLowerCase()) {
      case 'acres':
      case 'acre':
        return 'acres';
      case 'hectares':
      case 'hectare':
        return 'hectares';
      case 'cent':
      case 'cents':
        return 'cent';
      default:
        return unit.trim().toLowerCase();
    }
  }

  List<Map<String, dynamic>> _parcelsFromApi(LandPartitionModel model) {
    return model.data.map((segment) {
      final cropName = segment.cropName.trim().isEmpty ? 'Unknown Crop' : segment.cropName;
      final unit = _normalizeUnit(
        segment.areaUnit.trim().isNotEmpty
            ? segment.areaUnit
            : (model.summary.landUnit.trim().isNotEmpty
            ? model.summary.landUnit
            : widget.landUnit),
      );
      return <String, dynamic>{
        'id': segment.segmentId,
        'name': '$cropName Plot',
        'areaValue': _parseAreaValue(segment.areaValue),
        'areaUnit': unit,
        'crop': cropName,
        'productId': segment.productId,
        'expectedYieldValue': segment.expectedYieldValue != null
            ? double.tryParse(segment.expectedYieldValue!)
            : null,
        'expectedYieldUnit': segment.expectedYieldUnit ?? 'kg',
        'status': _normalizeStatus(segment.status),
        'updated': 'Synced from server',
        'isLocal': false,
        'plantationDate': segment.plantationDate,
        'harvestingDate': segment.harvestingDate,
      };
    }).toList();
  }

  void _syncFromApi(LandPartitionModel model) {
    final parcels = _parcelsFromApi(model);
    if (!mounted) return;
    setState(() {
      _parcels = parcels;
      _apiLandUnit = model.summary.landUnit;
      _summary = model.summary;
      _apiSynced = true;
      _ensureParcelIds();
    });
  }

  String _normalizeStatus(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'fallow') return 'Fallow';
    if (normalized == 'harvested') return 'Harvested';
    if (normalized == 'active') return 'Active';
    if (normalized.isEmpty) return 'Active';
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  void _ensureParcelIds() {
    for (final parcel in _parcels) {
      final rawId = parcel['id'];
      if (rawId is int) {
        if (rawId >= _nextParcelId) {
          _nextParcelId = rawId + 1;
        }
        continue;
      }
      parcel['id'] = _nextParcelId++;
    }
  }

  int _createParcelId() => _nextParcelId++;
  int _findParcelIndexById(int parcelId) => _parcels.indexWhere((item) => item['id'] == parcelId);

  String get _primaryUnit {
    if (_parcels.isNotEmpty) return _normalizeUnit(_parcels.first['areaUnit']?.toString());
    if (_apiLandUnit != null && _apiLandUnit!.trim().isNotEmpty) return _normalizeUnit(_apiLandUnit);
    return _normalizeUnit(widget.landUnit);
  }

  List<Map<String, dynamic>> get _filteredParcels {
    if (_selectedFilter == 'All') return _parcels;
    return _parcels.where((item) => item['status'].toString() == _selectedFilter).toList();
  }

  double get _totalArea => _parcels.fold<double>(0.0, (sum, item) => sum + _parseAreaValue(item['areaValue']));

  // Farmer's real total land. Falls back to the constructor value (from
  // onboarding) until the land-partition summary has loaded from the API.
  double get _farmerTotalLand => _summary?.totalLand ?? widget.totalLand;

  // Cultivated = everything currently allocated to a crop partition
  // (regardless of active/harvested), matching Total = Cultivated + Fallow.
  double get _cultivatedLand => _summary?.allocatedLand ?? _totalArea;

  // Fallow is derived, never manually entered: whatever isn't cultivated.
  double get _computedFallowLand {
    if (_summary != null) return _summary!.availableLand;
    final remaining = _farmerTotalLand - _totalArea;
    return remaining < 0 ? 0.0 : remaining;
  }

  // How much more land can still be allocated to crops right now.
  double get _availableRoomForNewParcel => _farmerTotalLand - _totalArea;

  Color _statusColor(String status) {
    switch (status) {
      case 'Active': return Colors.green;
      case 'Fallow': return Colors.orange;
      case 'Harvested': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  String _displayDate(dynamic value) {
    final parsed = _parseDate(value);
    if (parsed == null) return 'Not set';
    return MaterialLocalizations.of(context).formatMediumDate(parsed);
  }

  Future<void> _refreshLandData() async {
    setState(() {
      _apiSynced = false;
    });

    ref.invalidate(landPartitionProvider);

    await ref.read(landPartitionProvider.future);
  }

  Widget _buildGlassContainer({required Widget child, double? margin}) {
    return Container(
      margin: margin != null ? EdgeInsets.all(margin) : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStatsCard(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.88),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.farmerColor.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.edit_rounded, size: 13, color: AppColors.farmerColor.withValues(alpha: 0.6)),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.farmerColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final landAsync = ref.watch(landPartitionProvider);
    landAsync.whenData((model) {
      if (_apiSynced) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_apiSynced) _syncFromApi(model);
      });
    });

    if (landAsync.isLoading && !_apiSynced) {
      return Scaffold(
        backgroundColor: AppColors.loginBackground,
        appBar: CustomAppBar(
          showBackButton: false,
          title: 'Land Manage',
          backgroundColor: AppColors.farmerColor,
          elevation: 0,
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const CircularProgressIndicator(color: AppColors.farmerColor),
          ),
        ),
      );
    }

    if (landAsync.hasError && !_apiSynced) {
      final error = landAsync.error;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          showBackButton: false,
          title: 'Land Manage',
          backgroundColor: AppColors.farmerColor,
          elevation: 0,
        ),
        body: Center(
          child: _buildGlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.farmerColor.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading land partitions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _apiSynced = false;
                      });
                      ref.invalidate(landPartitionProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.farmerColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    ),
                    child: const Text("Retry", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      appBar: CustomAppBar(
        showBackButton: false,
        title: 'Land Manage',
        backgroundColor: AppColors.farmerColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stats Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                _buildStatsCard(
                  'Total Land',
                  '${_farmerTotalLand.toStringAsFixed(1)} $_primaryUnit',
                  Icons.terrain_rounded,
                  onTap: _showEditTotalLandSheet,
                ),
                const SizedBox(width: 10),
                _buildStatsCard('Cultivated', '${_cultivatedLand.toStringAsFixed(1)} $_primaryUnit', Icons.check_circle_outline),
                const SizedBox(width: 10),
                _buildStatsCard('Fallow', '${_computedFallowLand.toStringAsFixed(1)} $_primaryUnit', Icons.hourglass_empty),
              ],
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ['All', 'Active', 'Fallow', 'Harvested'].length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final filter = ['All', 'Active', 'Fallow', 'Harvested'][index];
                final selected = _selectedFilter == filter;
                return FilterChip(
                  label: Text(filter),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedFilter = filter),
                  selectedColor: AppColors.farmerColor,
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  checkmarkColor: Colors.white,
                  elevation: selected ? 2 : 0,
                  shadowColor: Colors.black.withValues(alpha: 0.05),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: selected ? BorderSide.none : BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // List Section
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshLandData,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _filteredParcels.length + 1,
                itemBuilder: (context, index) {
                  if (index == _filteredParcels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20,bottom: 15),
                      child: ElevatedButton.icon(
                        onPressed: _addParcel,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add New Plot', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: AppColors.farmerColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    );
                  }
              
                  final item = _filteredParcels[index];
                  final parcelId = item['id'] as int?;
                  final status = item['status'].toString();
                  final statusColor = _statusColor(status);
                  final cropName = item['crop']?.toString() ?? 'Not set';
                  final areaValue = _parseAreaValue(item['areaValue']);
                  final areaText = '${areaValue.toStringAsFixed(2)} ${item['areaUnit']}';
                  final expectedYieldValue = item['expectedYieldValue'] as double?;
                  final expectedYieldUnit = item['expectedYieldUnit']?.toString() ?? 'kg';
                  final plantationText = _displayDate(item['plantationDate']);
                  final harvestingText = _displayDate(item['harvestingDate']);
              
                  return _buildGlassContainer(
                    margin: 3,
                    child: Column(
                      children: [
                        // Header Section
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.farmerColor,
                                AppColors.farmerColor.withValues(alpha: 0.85),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                                ),
                                child: Icon(Icons.terrain_rounded, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'].toString(),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.grass_rounded, size: 12, color: Colors.white.withValues(alpha: 0.8)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            cropName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withValues(alpha: 0.8),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: parcelId == null ? null : () => _deleteParcel(parcelId),
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Icon(Icons.delete_outline, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                                ),
                              ),
                            ],
                          ),
                        ),
              
                        // Content Section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Area Badge
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.farmerColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.farmerColor.withValues(alpha: 0.15)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.square_foot_rounded, size: 16, color: AppColors.farmerColor.withValues(alpha: 0.7)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Area: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      areaText,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.farmerColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (expectedYieldValue != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.grain_rounded, size: 16, color: Colors.orange.withValues(alpha: 0.8)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Expected Yield: ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${expectedYieldValue.toStringAsFixed(2)} $expectedYieldUnit',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
              
                              const SizedBox(height: 16),
              
                              // Dates Section
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.event_available_rounded, size: 14, color: AppColors.textSecondary),
                                              const SizedBox(width: 6),
                                              Text('Planted', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            plantationText,
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.2)),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.event_repeat_rounded, size: 14, color: AppColors.textSecondary),
                                              const SizedBox(width: 6),
                                              Text('Harvest', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            harvestingText,
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
              
                              const SizedBox(height: 16),
              
                              // Action Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: parcelId == null ? null : () => _updateParcel(parcelId),
                                  icon: Icon(Icons.edit_outlined, size: 18),
                                  label: Text('Edit Details', style: TextStyle(fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.farmerColor,
                                    side: BorderSide(color: AppColors.farmerColor.withValues(alpha: 0.4)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Form methods remain the same but with updated UI
  Future<Map<String, dynamic>?> _showParcelForm({
    Map<String, dynamic>? initialData,
    required String title,
    required String actionLabel,
    // How much more land can be allocated in this form. For edits this
    // already accounts for the parcel's own current area (i.e. it's the
    // max this parcel's area field may hold, not just the leftover room).
    required double maxAllowedArea,
  }) async {
    final formKey = GlobalKey<FormState>();
    // final nameController = TextEditingController(text: initialData?['name']?.toString() ?? '');
    final areaController = TextEditingController(text: (initialData?['areaValue'] ?? '').toString());
    final yieldController = TextEditingController(
      text: initialData?['expectedYieldValue'] != null ? initialData!['expectedYieldValue'].toString() : '',
    );

    String selectedStatus = _normalizeStatus(initialData?['status']?.toString() ?? 'Active');
    if (selectedStatus == 'Fallow') selectedStatus = 'Active'; // fallow is derived, not user-selectable
    String selectedUnit = _normalizeUnit(initialData?['areaUnit']?.toString() ?? _primaryUnit);
    String selectedYieldUnit = initialData?['expectedYieldUnit']?.toString() ?? 'kg';
    DateTime? selectedPlantationDate = _parseDate(initialData?['plantationDate']);
    DateTime? selectedHarvestingDate = _parseDate(initialData?['harvestingDate']);

    int? selectedProductId = initialData?['productId'] as int?;
    String? selectedProductName = initialData?['crop']?.toString();
    String? selectedCategoryName;

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.loginBackground,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.loginBackground,
                // gradient: LinearGradient(
                //   begin: Alignment.topLeft,
                //   end: Alignment.bottomRight,
                //   colors: [Colors.white, Colors.grey.shade50],
                // ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.farmerColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F3A2C),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // CustomTextField(
                      //   controller: nameController,
                      //   label: 'Plot Name',
                      //   hintText: 'Enter plot name',
                      //   prefixIcon: Icons.terrain_rounded,
                      //   validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter plot name' : null,
                      // ),
                      // const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: CustomTextField(
                              controller: areaController,
                              label: 'Area',
                              hintText: 'Enter area',
                              prefixIcon: Icons.square_foot_rounded,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                final area = double.tryParse((value ?? '').trim());
                                return (area == null || area <= 0) ? 'Enter valid area' : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _customDropdownField(
                              label: 'Unit',
                              value: selectedUnit,
                              options: const ['Acres', 'Hectares', 'Cent'],
                              onChanged: (value) => setSheetState(() => selectedUnit = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Crop',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final selection = await showCropPickerSheet(
                            context,
                            categories: _cropCategories,
                            categoriesLoading: _cropCategoriesLoading,
                          );
                          if (selection == null) return;
                          setSheetState(() {
                            selectedProductId = selection.productId;
                            selectedProductName = selection.productName;
                            selectedCategoryName = selection.categoryName;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedProductId != null
                                  ? AppColors.farmerColor.withValues(alpha: 0.55)
                                  : Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.grass_rounded, size: 18,
                                  color: selectedProductId != null ? AppColors.farmerColor : AppColors.textSecondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: selectedProductId != null
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(selectedProductName ?? '',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.farmerColor)),
                                          if (selectedCategoryName != null)
                                            Text(selectedCategoryName!,
                                                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                        ],
                                      )
                                    : Text('Select crop / product',
                                        style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                              ),
                              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: CustomTextField(
                              controller: yieldController,
                              label: 'Expected Yield',
                              hintText: 'Enter expected quantity',
                              prefixIcon: Icons.grain_rounded,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                final yieldValue = double.tryParse((value ?? '').trim());
                                return (yieldValue == null || yieldValue <= 0) ? 'Enter valid yield' : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _customDropdownField(
                              label: 'Unit',
                              value: selectedYieldUnit,
                              options: const ['kg', 'ton'],
                              onChanged: (value) => setSheetState(() => selectedYieldUnit = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _datePickerTile(
                              label: 'Plantation Date',
                              value: selectedPlantationDate,
                              icon: Icons.event_available_rounded,
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedPlantationDate ?? DateTime.now(),
                                  firstDate: now.subtract(const Duration(days: 30)),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setSheetState(() {
                                    selectedPlantationDate = picked;
                                    if (selectedHarvestingDate != null && !selectedHarvestingDate!.isAfter(picked)) {
                                      selectedHarvestingDate = null;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _datePickerTile(
                              label: 'Harvesting Date',
                              value: selectedHarvestingDate,
                              icon: Icons.event_repeat_rounded,
                              onTap: () async {
                                if (selectedPlantationDate == null) {
                                  CustomSnackBar.error(context, 'Select plantation date first');
                                  return;
                                }
                                final minHarvest = selectedPlantationDate!.add(const Duration(days: 1));
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedHarvestingDate?.isAfter(minHarvest) == true ? selectedHarvestingDate! : minHarvest,
                                  firstDate: minHarvest,
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) setSheetState(() => selectedHarvestingDate = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _customDropdownField(
                        label: 'Status',
                        value: selectedStatus,
                        options: const ['Active', 'Harvested'],
                        onChanged: (value) => setSheetState(() => selectedStatus = value),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Unallocated land is automatically fallow — it isn\'t set here.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            if (!formKey.currentState!.validate()) {
                              CustomSnackBar.error(context, 'Please fill all required fields');
                              return;
                            }
                            if (selectedProductId == null) {
                              CustomSnackBar.error(context, 'Please select a crop');
                              return;
                            }
                            final parsedArea = double.tryParse(areaController.text.trim());
                            if (parsedArea == null || parsedArea <= 0) {
                              CustomSnackBar.error(context, 'Please enter a valid land area');
                              return;
                            }
                            if (parsedArea - maxAllowedArea > 0.01) {
                              CustomSnackBar.error(
                                context,
                                'This exceeds the farmer\'s available land by ${(parsedArea - maxAllowedArea).toStringAsFixed(2)} $_primaryUnit',
                              );
                              return;
                            }
                            final parsedYield = double.tryParse(yieldController.text.trim());
                            if (parsedYield == null || parsedYield <= 0) {
                              CustomSnackBar.error(context, 'Please enter a valid expected yield');
                              return;
                            }
                            if (selectedPlantationDate == null || selectedHarvestingDate == null) {
                              CustomSnackBar.error(context, 'Please select plantation and harvesting dates');
                              return;
                            }
                            if (!selectedHarvestingDate!.isAfter(selectedPlantationDate!)) {
                              CustomSnackBar.error(context, 'Harvesting date must be after plantation date');
                              return;
                            }
                            Navigator.of(sheetContext).pop(<String, dynamic>{
                              'name': '${selectedProductName ?? ''} Plot',
                              'areaValue': parsedArea,
                              'areaUnit': selectedUnit,
                              'crop': selectedProductName ?? '',
                              'productId': selectedProductId,
                              'expectedYieldValue': parsedYield,
                              'expectedYieldUnit': selectedYieldUnit,
                              'status': selectedStatus,
                              'updated': 'Updated just now',
                              'plantationDate': selectedPlantationDate!.toIso8601String(),
                              'harvestingDate': selectedHarvestingDate!.toIso8601String(),
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: AppColors.farmerColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _customDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: options.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePickerTile({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.farmerColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasValue ? MaterialLocalizations.of(context).formatMediumDate(value!) : 'Select date',
                    style: TextStyle(
                      color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 13.5,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.farmerColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showEditTotalLandSheet() async {
    final controller = TextEditingController(text: _farmerTotalLand.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();
    final unit = _primaryUnit;
    final cultivated = _cultivatedLand;

    final newTotal = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.loginBackground,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Total Land', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  'Currently cultivated: ${cultivated.toStringAsFixed(2)} $unit. Total land can\'t go below this.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: controller,
                  label: 'Total Land ($unit)',
                  hintText: 'Enter total land',
                  prefixIcon: Icons.terrain_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final v = double.tryParse((value ?? '').trim());
                    if (v == null || v <= 0) return 'Enter a valid land size';
                    if (v - cultivated < -0.01) return 'Can\'t be less than cultivated land';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.of(sheetContext).pop(double.parse(controller.text.trim()));
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppColors.farmerColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (newTotal == null) return;

    try {
      await ref.read(landRepoProvider).updateTotalLand(
        totalLand: newTotal,
        landUnit: _unitToApi(unit),
      );
      ref.invalidate(landPartitionProvider);
      if (mounted) CustomSnackBar.success(context, 'Total land updated');
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _addParcel() async {
    final created = await _showParcelForm(
      title: 'Add Land Plot',
      actionLabel: 'Save Plot',
      maxAllowedArea: _availableRoomForNewParcel < 0 ? 0 : _availableRoomForNewParcel,
    );
    if (created == null) return;
    final plantationDate = _parseDate(created['plantationDate']);
    final harvestingDate = _parseDate(created['harvestingDate']);
    if (plantationDate == null || harvestingDate == null) {
      CustomSnackBar.error(context, 'Missing plantation/harvesting dates');
      return;
    }
    final productId = created['productId'] as int?;
    if (productId == null) {
      CustomSnackBar.error(context, 'Please select a crop');
      return;
    }
    try {
      await ref.read(landRepoProvider).createLandPartition(
        productId: productId,
        areaValue: _parseAreaValue(created['areaValue']),
        areaUnit: _unitToApi((created['areaUnit'] ?? _primaryUnit).toString()),
        expectedYieldValue: (created['expectedYieldValue'] as num?)?.toDouble(),
        expectedYieldUnit: created['expectedYieldUnit']?.toString() ?? 'kg',
        plantationDate: plantationDate,
        harvestingDate: harvestingDate,
        status: (created['status'] ?? '').toString().toLowerCase(),
      );
      if (!mounted) return;
      setState(() {
        created['id'] = _createParcelId();
        created['isLocal'] = true;
        created['updated'] = 'Added just now';
        _selectedFilter = 'All';
        _parcels.add(created);
      });
      ref.invalidate(landPartitionProvider);
      CustomSnackBar.success(context, 'Land plot added successfully');
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Failed to add plot: $e');
    }
  }

  Future<void> _updateParcel(int parcelId) async {
    final parcelIndex = _findParcelIndexById(parcelId);
    if (parcelIndex < 0 || parcelIndex >= _parcels.length) {
      CustomSnackBar.error(context, 'Unable to update this plot');
      return;
    }
    final existingArea = _parseAreaValue(_parcels[parcelIndex]['areaValue']);
    final maxAllowedArea = _availableRoomForNewParcel + existingArea;
    final updated = await _showParcelForm(
      initialData: _parcels[parcelIndex],
      title: 'Update Land Plot',
      actionLabel: 'Save Changes',
      maxAllowedArea: maxAllowedArea < 0 ? 0 : maxAllowedArea,
    );
    if (updated == null) return;
    final isLocal = _parcels[parcelIndex]['isLocal'] == true;
    final plantationDate = _parseDate(updated['plantationDate']);
    final harvestingDate = _parseDate(updated['harvestingDate']);
    final productId = updated['productId'] as int?;
    if (!isLocal) {
      if (plantationDate == null || harvestingDate == null) {
        CustomSnackBar.error(context, 'Missing plantation/harvesting dates');
        return;
      }
      if (productId == null) {
        CustomSnackBar.error(context, 'Please select a crop');
        return;
      }
      try {
        await ref.read(landRepoProvider).updateLandPartition(
          segmentId: parcelId,
          productId: productId,
          areaValue: _parseAreaValue(updated['areaValue']),
          areaUnit: _unitToApi((updated['areaUnit'] ?? _primaryUnit).toString()),
          expectedYieldValue: (updated['expectedYieldValue'] as num?)?.toDouble(),
          expectedYieldUnit: updated['expectedYieldUnit']?.toString() ?? 'kg',
          plantationDate: plantationDate,
          harvestingDate: harvestingDate,
          status: (updated['status'] ?? '').toString().toLowerCase(),
        );
      } catch (e) {
        if (mounted) CustomSnackBar.error(context, 'Update failed: $e');
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      updated['id'] = parcelId;
      updated['isLocal'] = isLocal;
      _selectedFilter = 'All';
      _parcels[parcelIndex] = updated;
    });
    if (!isLocal) ref.invalidate(landPartitionProvider);
    CustomSnackBar.success(context, 'Land plot updated successfully');
  }

  Future<void> _deleteParcel(int parcelId) async {
    final parcelIndex = _findParcelIndexById(parcelId);
    if (parcelIndex < 0 || parcelIndex >= _parcels.length) {
      CustomSnackBar.error(context, 'Unable to delete this plot');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Land Plot'),
        content: const Text('Are you sure you want to delete this plot?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final isLocal = _parcels[parcelIndex]['isLocal'] == true;
    if (!isLocal) {
      try {
        await ref.read(landRepoProvider).deleteLandPartition(segmentId: parcelId);
      } catch (e) {
        if (mounted) CustomSnackBar.error(context, 'Delete failed: $e');
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _parcels.removeAt(parcelIndex);
      _selectedFilter = 'All';
    });
    if (!isLocal) ref.invalidate(landPartitionProvider);
    CustomSnackBar.success(context, 'Land plot deleted successfully');
  }
}

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const LandManageScreen();
}
