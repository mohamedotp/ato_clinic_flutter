import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clinic_material.dart';
import '../services/material_service.dart';
import 'auth_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────
class MaterialsState {
  final List<ClinicMaterial> materials;
  final bool isLoading;
  final String? error;

  const MaterialsState({
    this.materials = const [],
    this.isLoading = false,
    this.error,
  });

  MaterialsState copyWith({
    List<ClinicMaterial>? materials,
    bool? isLoading,
    String? error,
  }) {
    return MaterialsState(
      materials: materials ?? this.materials,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class MaterialsNotifier extends StateNotifier<MaterialsState> {
  final MaterialService _service = MaterialService();
  final String clinicId;

  MaterialsNotifier(this.clinicId) : super(const MaterialsState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final materials = await _service.getMaterials(clinicId);
      state = state.copyWith(materials: materials, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  Future<void> addMaterial(Map<String, dynamic> data) async {
    try {
      data['clinic_id'] = clinicId;
      final newMat = await _service.addMaterial(data);
      state = state.copyWith(
        materials: [...state.materials, newMat]
          ..sort((a, b) => a.name.compareTo(b.name)),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateMaterial(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateMaterial(id, data);
      await _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteMaterial(String id) async {
    try {
      await _service.deleteMaterial(id);
      state = state.copyWith(
        materials: state.materials.where((m) => m.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> restockMaterial(String id, double qty, String userId) async {
    try {
      await _service.restockMaterial(clinicId, id, qty, userId);
      await _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> issueMaterial(String id, double qty, String userId, String notes) async {
    try {
      await _service.issueMaterial(clinicId, id, qty, userId, notes);
      await _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final materialsProvider =
    StateNotifierProvider.family<MaterialsNotifier, MaterialsState, String>(
  (ref, clinicId) => MaterialsNotifier(clinicId),
);

// Convenience provider that auto-reads clinicId from auth
final clinicMaterialsProvider =
    StateNotifierProvider<MaterialsNotifier, MaterialsState>((ref) {
  final authState = ref.watch(authProvider);
  final clinicId = authState is AuthAuthenticated
      ? authState.profile?.clinicId ?? ''
      : '';
  return MaterialsNotifier(clinicId);
});

// ─── Patient Usage State & Provider ──────────────────────────────────────────
class PatientUsageState {
  final List<MaterialUsage> usages;
  final bool isLoading;
  final String? error;

  const PatientUsageState({
    this.usages = const [],
    this.isLoading = false,
    this.error,
  });

  PatientUsageState copyWith({
    List<MaterialUsage>? usages,
    bool? isLoading,
    String? error,
  }) {
    return PatientUsageState(
      usages: usages ?? this.usages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PatientUsageNotifier extends StateNotifier<PatientUsageState> {
  final MaterialService _service = MaterialService();
  final String patientId;

  PatientUsageNotifier(this.patientId) : super(const PatientUsageState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final usages = await _service.getPatientUsage(patientId);
      state = state.copyWith(usages: usages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  Future<void> addUsage(Map<String, dynamic> data) async {
    try {
      final usage = await _service.addUsage(data);
      state = state.copyWith(usages: [usage, ...state.usages]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteUsage(String usageId) async {
    try {
      await _service.deleteUsage(usageId);
      state = state.copyWith(
        usages: state.usages.where((u) => u.id != usageId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final patientUsageProvider =
    StateNotifierProvider.family<PatientUsageNotifier, PatientUsageState, String>(
  (ref, patientId) => PatientUsageNotifier(patientId),
);

// ─── Material History Provider ────────────────────────────────────────────────
class MaterialHistoryNotifier extends StateNotifier<PatientUsageState> {
  final MaterialService _service = MaterialService();
  final String materialId;

  MaterialHistoryNotifier(this.materialId) : super(const PatientUsageState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final usages = await _service.getMaterialHistory(materialId);
      state = state.copyWith(usages: usages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();
}

final materialHistoryProvider =
    StateNotifierProvider.family<MaterialHistoryNotifier, PatientUsageState, String>(
  (ref, materialId) => MaterialHistoryNotifier(materialId),
);

// ─── Clinic-wide Usage History Provider ──────────────────────────────────────
class ClinicUsageNotifier extends StateNotifier<PatientUsageState> {
  final MaterialService _service = MaterialService();
  final String clinicId;

  ClinicUsageNotifier(this.clinicId) : super(const PatientUsageState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final usages = await _service.getClinicUsage(clinicId);
      state = state.copyWith(usages: usages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();
}

final clinicUsageProvider =
    StateNotifierProvider.family<ClinicUsageNotifier, PatientUsageState, String>(
  (ref, clinicId) => ClinicUsageNotifier(clinicId),
);
