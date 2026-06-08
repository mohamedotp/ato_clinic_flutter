import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  static const String _patientsBox = 'patientsBox';
  static const String _authBox = 'authBox';
  static const String _visitsBox = 'visitsBox';
  static const String _workspaceBox = 'workspaceBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_patientsBox);
    await Hive.openBox(_authBox);
    await Hive.openBox(_visitsBox);
    await Hive.openBox(_workspaceBox);
  }

  // --- Patients ---
  static Box get patientsBox => Hive.box(_patientsBox);
  
  static Future<void> savePatients(List<dynamic> patientsJson) async {
    await patientsBox.put('all', jsonEncode(patientsJson));
  }
  
  static List<dynamic>? getPatients() {
    final data = patientsBox.get('all');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  // --- Profile ---
  static Box get authBox => Hive.box(_authBox);

  static Future<void> saveProfile(Map<String, dynamic> profileJson) async {
    await authBox.put('profile', jsonEncode(profileJson));
  }

  static Map<String, dynamic>? getProfile() {
    final data = authBox.get('profile');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  static Future<void> saveClinicStatus(Map<String, dynamic> statusJson) async {
    await authBox.put('clinic_status', jsonEncode(statusJson));
  }

  static Map<String, dynamic>? getClinicStatus() {
    final data = authBox.get('clinic_status');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  // --- Visits ---
  static Box get visitsBox => Hive.box(_visitsBox);

  static Future<void> savePatientVisits(String patientId, List<dynamic> visitsJson) async {
    await visitsBox.put('patient_$patientId', jsonEncode(visitsJson));
  }

  static List<dynamic>? getPatientVisits(String patientId) {
    final data = visitsBox.get('patient_$patientId');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  // --- Workspace ---
  static Box get workspaceBox => Hive.box(_workspaceBox);

  static Future<void> savePatientNotes(String patientId, List<dynamic> notesJson) async {
    await workspaceBox.put('notes_$patientId', jsonEncode(notesJson));
  }

  static List<dynamic>? getPatientNotes(String patientId) {
    final data = workspaceBox.get('notes_$patientId');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  static Future<void> savePatientConnections(String patientId, List<dynamic> connectionsJson) async {
    await workspaceBox.put('connections_$patientId', jsonEncode(connectionsJson));
  }

  static List<dynamic>? getPatientConnections(String patientId) {
    final data = workspaceBox.get('connections_$patientId');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }
}
