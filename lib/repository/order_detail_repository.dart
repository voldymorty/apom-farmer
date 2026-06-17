import 'package:client/config/api_config.dart';
import 'package:client/models/order_Detail_Model.dart';
import 'package:client/utils/auth_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderDetailRepository {
  Future<OrderDetailModel> getOrderDetail({required int cropId}) async {
    final url = ApiConfig.getOrderdetailUrl(cropId);
    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load order detail (${response.statusCode}): ${response.body}",
      );
    }

    return orderDetailModelFromJson(response.body);
  }
}

final orderDetailRepoProvider = Provider((ref) => OrderDetailRepository());

final orderDetailProvider = FutureProvider.family<OrderDetailModel, int>((
  ref,
  cropId,
) async {
  return ref.watch(orderDetailRepoProvider).getOrderDetail(cropId: cropId);
});
