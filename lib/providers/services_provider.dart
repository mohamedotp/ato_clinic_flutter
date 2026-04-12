import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medical_service.dart';
import '../services/medical_service_service.dart';

final medicalServiceService = Provider((ref) => MedicalServiceService());

final servicesProvider = FutureProvider<List<MedicalService>>((ref) async {
  return ref.watch(medicalServiceService).getServices();
});

final serviceCategoryFilterProvider = StateProvider<String>((ref) => 'الكل');

final filteredServicesProvider = Provider<AsyncValue<List<MedicalService>>>((ref) {
  final servicesAsync = ref.watch(servicesProvider);
  final filter = ref.watch(serviceCategoryFilterProvider);

  return servicesAsync.whenData((services) {
    if (filter == 'الكل') return services;
    return services.where((s) => s.category == filter).toList();
  });
});
