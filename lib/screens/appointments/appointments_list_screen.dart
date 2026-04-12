import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../providers/appointments_provider.dart';
import '../../widgets/modals/add_edit_appointment_modal.dart';

class AppointmentsListScreen extends ConsumerWidget {
  const AppointmentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);
    const primaryColor = Color(0xFF0D9488);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('جدول المواعيد', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: appointmentsAsync.when(
        data: (appointments) => _buildAppointmentsList(context, ref, appointments),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddEditAppointmentModal.show(context),
        backgroundColor: primaryColor,
        child: const Icon(Icons.calendar_month, color: Colors.white),
      ),
    );
  }

  Widget _buildAppointmentsList(BuildContext context, WidgetRef ref, List<Appointment> appointments) {
    if (appointments.isEmpty) return const Center(child: Text('لا توجد مواعيد مسجلة'));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _AppointmentCard(
          appointment: appointment,
          onEdit: () => AddEditAppointmentModal.show(context, appointment: appointment),
          onDelete: () => _deleteAppointment(context, ref, appointment.id),
        );
      },
    );
  }

  Future<void> _deleteAppointment(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الموعد'),
        content: const Text('هل أنت متأكد من حذف هذا الموعد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(appointmentService).deleteAppointment(id);
      ref.invalidate(appointmentsProvider);
    }
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AppointmentCard({required this.appointment, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(appointment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20)),
            ],
          ),
          const Spacer(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(appointment.patient?.fullName ?? 'مريض غير معروف', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(appointment.appointmentTime ?? '--:--', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(DateFormat('yyyy/MM/dd').format(appointment.appointmentDate ?? DateTime.now()), style: const TextStyle(color: Colors.grey)),
                    const SizedBox(width: 4),
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(appointment.statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF0D9488).withOpacity(0.1),
            child: Text(appointment.patient?.fullName[0] ?? 'أ', style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed: return Colors.green;
      case AppointmentStatus.cancelled: return Colors.red;
      case AppointmentStatus.completed: return Colors.blue;
      case AppointmentStatus.no_show: return Colors.orange;
      case AppointmentStatus.scheduled: return Colors.blueGrey;
    }
  }
}
