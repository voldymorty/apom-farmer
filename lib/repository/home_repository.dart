import 'package:client/config/api_config.dart';
import 'package:client/models/dashboard_model.dart';
import 'package:client/models/market_demand_model.dart';
import 'package:client/utils/auth_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeRepository {
  Future<DashboardModel> getDashboard() async {
    final url = ApiConfig.getDashboardUrl();

    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load dashboard (${response.statusCode}): ${response.body}",
      );
    }

    return dashboardModelFromJson(response.body);
  }

  Future<MarketDemandModel> getMarketDemand(int month) async {
    final url = ApiConfig.getmarketdemandUrl(month.toString());

    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load market demand (${response.statusCode}): ${response.body}",
      );
    }

    return marketDemandModelFromJson(response.body);
  }
}

final homeRepoProvider = Provider((ref) => HomeRepository());

final dashboardProvider = FutureProvider<DashboardModel>((ref) async {
  return ref.watch(homeRepoProvider).getDashboard();
});

// final marketDemandProvider = FutureProvider.family<MarketDemandModel, int>((
//   ref,
//   month,
// ) async {
//   return ref.watch(homeRepoProvider).getMarketDemand(month);
// });

final marketDemandProvider =
    FutureProvider.family<MarketDemandModel?, int>((ref, month) async {
  try {
    return await ref.watch(homeRepoProvider).getMarketDemand(month);
  } catch (_) {
    return null;
  }
});