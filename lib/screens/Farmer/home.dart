import 'dart:async';

import 'package:client/global/colortheme.dart';
import 'package:client/models/dashboard_model.dart';
import 'package:client/models/market_demand_model.dart';
import 'package:client/repository/home_repository.dart';
import 'package:client/screens/Farmer/profile_screen.dart';
import 'package:client/screens/Farmer/notification_screen.dart';
import 'package:client/repository/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';

class FarmerHomeScreen extends ConsumerStatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  ConsumerState<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends ConsumerState<FarmerHomeScreen> {
  static const String _adminPhone = '9019814347';
  int selectedMonth = DateTime.now().month;
  bool _monthInitialized = false;

  Timer? _carouselTimer;
  bool _imagesPreloaded = false;
  int _currentPage = 0;
  final PageController _carouselController = PageController();

  final List<String> monthNames = [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December",
  ];

  final List<Color> segmentColors = [
    const Color(0xFF27AE60),
    const Color(0xFF3498DB),
    const Color(0xFFE67E22),
    const Color(0xFF9B59B6),
    const Color(0xFFE74C3C),
  ];

  final List<Map<String, String>> banners = [
    {
      'title': 'Welcome to Apom Farmer',
      'subtitle': 'Better prices for your crops.',
      'image': 'assets/images/ban1.jpg',
    },    
    {
      'title': 'From Farm to Market',
      'subtitle': 'Sell directly with confidence.',
      'image': 'assets/images/ban3.jpeg',
    },
    {
      'title': 'Trusted Crop Procurement',
      'subtitle': 'Quality checked, fairly priced.',
      'image': 'assets/images/ban2.jpg',
    },
  ];

  // ── Lifecycle ─────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _preloadAndStartCarousel(),
    );
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  // ── Carousel ──────────────────────────────────────────────────

  Future<void> _preloadAndStartCarousel() async {
    if (!mounted) return;
    await Future.wait(
      banners.map((b) => precacheImage(AssetImage(b['image']!), context)),
    );
    if (!mounted) return;
    setState(() => _imagesPreloaded = true);
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % banners.length;
      if (_carouselController.hasClients) {
        _carouselController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // ── Month helpers ─────────────────────────────────────────────

  int _normalizeMonth(int month) =>
      (month < 1 || month > 12) ? DateTime.now().month : month;

  void _initializeSelectedMonth(int apiMonth) {
    if (_monthInitialized) return;
    final normalized = _normalizeMonth(apiMonth);
    _monthInitialized = true;
    if (normalized == selectedMonth) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => selectedMonth = normalized);
    });
  }

  // ── Demand helpers ────────────────────────────────────────────

  Map<String, double> _demandForMonth(DashboardModel dashboard) {
    final monthData = dashboard.data.allMonthlyDemand[selectedMonth];
    if (monthData != null && monthData.slices.isNotEmpty) {
      return monthData.ratioMap;
    }
    return {};
  }

  String _topCropForMonth(
      DashboardModel dashboard, Map<String, double> demandMap) {
    final monthData = dashboard.data.allMonthlyDemand[selectedMonth];
    if (monthData != null && monthData.topCrop.isNotEmpty) {
      return monthData.topCrop;
    }
    if (demandMap.isEmpty) return "Crops";
    return demandMap.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  bool _isLiveData(DashboardModel dashboard) =>
      dashboard.data.allMonthlyDemand[selectedMonth]?.isLive ?? false;

  int? _dataYear(DashboardModel dashboard) =>
      dashboard.data.allMonthlyDemand[selectedMonth]?.dataYear;

  String _insightLabel(DashboardModel dashboard, MarketDemandModel? market) {
    if (market != null) return market.data.insightLabel;
    final live = _isLiveData(dashboard);
    final year = _dataYear(dashboard);
    if (live && year != null) {
      return "Based on actual orders from ${monthNames[selectedMonth - 1]} $year";
    }
    return "Estimated demand — actual data available after first full year";
  }

  List<_CropLegendRow> _buildLegendRows(
      Map<String, double> demandMap, MarketDemandModel? market) {
    if (market != null) {
      return market.data.slices
          .map((s) => _CropLegendRow(
                crop: s.crop,
                ratio: s.ratio,
                totalKg: s.totalKg,
                orderCount: s.orderCount,
              ))
          .toList();
    }
    return demandMap.entries
        .map((e) => _CropLegendRow(crop: e.key, ratio: e.value))
        .toList();
  }

  // ── Actions ───────────────────────────────────────────────────

  Future<void> _contactAdmin() async {
    final uri = Uri(scheme: 'tel', path: _adminPhone);
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dial pad')),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.loginBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.loginBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Error loading dashboard:\n$err",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(dashboardProvider),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (dashboard) {
        final apiCurrentMonth = _normalizeMonth(dashboard.data.currentMonth);
        _initializeSelectedMonth(apiCurrentMonth);

        final marketDemandAsync =
            ref.watch(marketDemandProvider(selectedMonth));
        final marketDemand = marketDemandAsync.value;

        final fullName = dashboard.data.fullName.trim();
        final displayName = fullName.isEmpty
            ? "Farmer"
            : fullName.split(RegExp(r"\s+")).first;
        final profilePhotoUrl = dashboard.data.profilePhotoUrl.trim();
        final hasProfilePhoto = profilePhotoUrl.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.loginBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSize.width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FarmerProfileScreen(),
                          ),
                        ),
                        child: CircleAvatar(
                          radius: AppSize.width * 0.07,
                          backgroundImage: hasProfilePhoto
                              ? NetworkImage(profilePhotoUrl)
                              : null,
                          backgroundColor:
                              AppColors.farmerColor.withOpacity(0.2),
                          child: hasProfilePhoto
                              ? null
                              : Icon(Icons.person,
                                  color: AppColors.farmerColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome back,",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Consumer(
                        builder: (context, ref, _) {
                          final unreadCountAsync = ref.watch(unreadCountProvider);
                          final unreadCount = unreadCountAsync.value ?? 0;
                          return _NotificationBell(
                            unreadCount: unreadCount,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: AppSize.height * 0.015),

                  // ── Carousel ───────────────────────────────────
                  SizedBox(
                    height: 200,
                    child: _imagesPreloaded
                        ? Stack(
                            children: [
                              PageView.builder(
                                controller: _carouselController,
                                itemCount: banners.length,
                                onPageChanged: (index) =>
                                    setState(() => _currentPage = index),
                                itemBuilder: (context, index) {
                                  final banner = banners[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      image: DecorationImage(
                                        image: AssetImage(banner['image']!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(24),
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomLeft,
                                          end: Alignment.topRight,
                                          colors: [
                                            Colors.black.withOpacity(0.65),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            banner['title']!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            banner['subtitle']!,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 20,
                                left: 32,
                                child: Row(
                                  children: List.generate(
                                    banners.length,
                                    (index) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.only(right: 6),
                                      width: _currentPage == index ? 22 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _currentPage == index
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.4),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color:
                                  AppColors.farmerColor.withOpacity(0.08),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primaryGreen),
                            ),
                          ),
                  ),

                  SizedBox(height: AppSize.height * 0.025),

                  // ── Hero earnings card ─────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.farmerColor,
                          AppColors.farmerColor.withOpacity(0.78),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.farmerColor.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                monthNames[dashboard.data.currentMonth - 1]
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white60,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Monthly Earnings',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '₹ ${dashboard.data.monthlyEarnings.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppSize.height * 0.025),

                  // ── Activity Insights label ────────────────────
                  const Text(
                    'Activity Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Stat cards grid ────────────────────────────
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.50,
                    children: [
                      _buildStatCard(
                        Icons.grass_rounded,
                        AppColors.farmerColor,
                        'AVAILABLE',
                        '${dashboard.data.availableCrops} Crops',
                      ),
                      _buildStatCard(
                        Icons.local_shipping_outlined,
                        Colors.orange,
                        'TOTAL SOLD',
                        '${dashboard.data.totalSoldTons} Tons',
                      ),
                      _buildStatCard(
                        Icons.pending_actions_outlined,
                        Colors.redAccent,
                        'PENDING PICKUPS',
                        '${dashboard.data.pendingPickups}',
                      ),
                      _buildStatCard(
                        Icons.bar_chart_rounded,
                        Colors.indigo,
                        'TOTAL EARNINGS',
                        '₹ ${dashboard.data.totalEarnings.toStringAsFixed(0)}',
                      ),
                    ],
                  ),

                  SizedBox(height: AppSize.height * 0.03),

                  // ── Weekly pickup chart ────────────────────────
                  const Text(
                    "This Week's Pickups",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWeeklyPickupCard(dashboard.data.weeklyPickups),

                  SizedBox(height: AppSize.height * 0.03),

                  // ── Market Demand ──────────────────────────────
                  const Text(
                    'Market Demand Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDemandCard(
                    dashboard: dashboard,
                    marketDemand: marketDemand,
                    apiCurrentMonth: apiCurrentMonth,
                  ),

                  SizedBox(height: AppSize.height * 0.04),

                  // ── Quick Actions ──────────────────────────────
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _contactAdmin,
                      icon: const Icon(Icons.headset_mic_rounded,
                          color: Colors.white),
                      label: const Text(
                        "Contact Admin",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.farmerColor,
                        padding: EdgeInsets.symmetric(
                            vertical: AppSize.height * 0.022),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),              
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Widgets ───────────────────────────────────────────────────

  Widget _buildStatCard(
    IconData icon,
    Color color,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPickupCard(WeeklyChart chart) {
    final hasData = chart.data.isNotEmpty && !chart.isAllZero;
    final maxY = chart.maxValue <= 0 ? 100.0 : chart.maxValue * 1.25;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        height: 180,
        child: !hasData
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 36,
                        color: AppColors.farmerColor.withOpacity(0.35)),
                    const SizedBox(height: 8),
                    const Text(
                      'No completed pickups this week',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) {
                        if (rod.toY <= 0) return null;
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(0)} kg',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.shade100,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= chart.labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              chart.labels[idx],
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(chart.data.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: chart.data[i],
                          gradient: LinearGradient(
                            colors: [
                              AppColors.farmerColor.withOpacity(0.7),
                              AppColors.farmerColor,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
                ),
              ),
      ),
    );
  }

  Widget _buildDemandCard({
    required DashboardModel dashboard,
    required MarketDemandModel? marketDemand,
    required int apiCurrentMonth,
  }) {
    final demandMap = marketDemand != null
        ? marketDemand.data.ratioMap
        : _demandForMonth(dashboard);

    final legendRows = _buildLegendRows(demandMap, marketDemand);
    final topCrop =
        (marketDemand?.data.topSuggestedCrop.trim().isNotEmpty == true)
            ? marketDemand!.data.topSuggestedCrop
            : _topCropForMonth(dashboard, demandMap);
    final monthLabel =
        (marketDemand?.data.monthName.trim().isNotEmpty == true)
            ? marketDemand!.data.monthName
            : monthNames[selectedMonth - 1];
    final insightLabel = _insightLabel(dashboard, marketDemand);
    final isLive = marketDemand?.data.isLive ?? _isLiveData(dashboard);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insight source label
          Row(
            children: [
              Icon(
                isLive
                    ? Icons.insights_rounded
                    : Icons.info_outline_rounded,
                size: 14,
                color:
                    isLive ? AppColors.farmerColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  insightLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isLive
                        ? AppColors.farmerColor
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Month selector
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = selectedMonth == month;
                final isCurrentMonth = apiCurrentMonth == month;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => selectedMonth = month),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.farmerColor
                            : AppColors.farmerColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected || isCurrentMonth
                              ? AppColors.farmerColor
                              : AppColors.farmerColor.withOpacity(0.2),
                          width: isCurrentMonth ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          monthNames[index].substring(0, 3),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.farmerColor,
                            fontWeight: isSelected || isCurrentMonth
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Donut + legend or empty state
          demandMap.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.farmerColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'No demand data for this month',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: PieChart(
                        PieChartData(
                          sections: demandMap.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            final i = entry.key;
                            final e = entry.value;
                            return PieChartSectionData(
                              value: e.value,
                              color:
                                  segmentColors[i % segmentColors.length],
                              title: '',
                              radius: 24,
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            legendRows.asMap().entries.map((entry) {
                          final i = entry.key;
                          final row = entry.value;
                          final color =
                              segmentColors[i % segmentColors.length];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(top: 3),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        row.crop,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        row.totalKg != null
                                            ? '${row.totalKg!.toStringAsFixed(0)} kg · ${row.orderCount ?? 0} orders'
                                            : '${(row.ratio * 100).toInt()}%',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

          const SizedBox(height: 14),

          // Top crop callout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.farmerColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up_rounded,
                    color: AppColors.farmerColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$topCrop is the top crop for $monthLabel!',
                    style:
                        const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting classes ─────────────────────────────────────────

class _CropLegendRow {
  final String crop;
  final double ratio;
  final double? totalKg;
  final int? orderCount;

  const _CropLegendRow({
    required this.crop,
    required this.ratio,
    this.totalKg,
    this.orderCount,
  });
}

class _NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationBell({
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.farmerColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            color: AppColors.farmerColor,
            onPressed: onTap,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}