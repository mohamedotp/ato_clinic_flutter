import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lab_order.dart';

class LabService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<LabOrder>> getOrders(String clinicId) async {
    final data = await _client
        .from('lab_orders')
        .select('*, patients(full_name, phone), profiles!doctor_id(full_name), lab_order_items(*)')
        .eq('clinic_id', clinicId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => LabOrder.fromJson(e)).toList();
  }

  Future<LabOrder> createOrder(Map<String, dynamic> orderData, List<Map<String, dynamic>> items) async {
    final order = await _client.from('lab_orders').insert(orderData).select().single();
    if (items.isNotEmpty) {
      final itemsWithOrderId = items.map((i) => {...i, 'order_id': order['id']}).toList();
      await _client.from('lab_order_items').insert(itemsWithOrderId);
    }
    return getOrderById(order['id']);
  }

  Future<LabOrder> getOrderById(String id) async {
    final data = await _client
        .from('lab_orders')
        .select('*, patients(full_name, phone), profiles!doctor_id(full_name), lab_order_items(*)')
        .eq('id', id)
        .single();
    return LabOrder.fromJson(data);
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await _client.from('lab_orders').update({'status': status, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id);
  }

  Future<void> updateItemResult(String itemId, String resultValue, String? notes) async {
    await _client.from('lab_order_items').update({
      'result_value': resultValue,
      'status': 'completed',
      'result_date': DateTime.now().toIso8601String(),
      'notes': notes,
    }).eq('id', itemId);
  }

  Future<List<LabTest>> getTests(String clinicId) async {
    final data = await _client
        .from('lab_tests')
        .select()
        .eq('clinic_id', clinicId)
        .eq('is_active', true)
        .order('name');
    return (data as List).map((e) => LabTest.fromJson(e)).toList();
  }

  Future<void> deleteOrder(String id) async {
    await _client.from('lab_orders').delete().eq('id', id);
  }
}
