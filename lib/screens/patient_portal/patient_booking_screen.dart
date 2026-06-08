import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class PatientBookingScreen extends ConsumerStatefulWidget {
  const PatientBookingScreen({super.key});

  @override
  ConsumerState<PatientBookingScreen> createState() => _PatientBookingScreenState();
}

class _PatientBookingScreenState extends ConsumerState<PatientBookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  String? _selectedService;

  final List<String> _timeSlots = [
    '09:00 ص', '10:00 ص', '11:00 ص', '12:00 م',
    '01:00 م', '04:00 م', '05:00 م', '06:00 م',
  ];

  final List<Map<String, dynamic>> _services = [
    {'id': '1', 'name': 'استشارة طبية', 'price': '200 ج.م'},
    {'id': '2', 'name': 'متابعة دورية', 'price': '100 ج.م'},
    {'id': '3', 'name': 'فحص شامل', 'price': '500 ج.م'},
  ];

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006D63);
    const scaffoldBg = Color(0xFFF8FAF9);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'حجز موعد',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Service
            const Text(
              'اختر نوع الخدمة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ).animate().fade().slideX(),
            const SizedBox(height: 16),
            ..._services.map((service) {
              final isSelected = _selectedService == service['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedService = service['id']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey[200]!,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.medical_services_outlined,
                          color: isSelected ? Colors.white : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          service['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        service['price'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white70 : primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade().slideY();
            }).toList(),

            const SizedBox(height: 24),

            // Select Date
            const Text(
              'اختر التاريخ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ).animate().fade(delay: 200.ms),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: primaryColor,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: primaryColor),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ).animate().fade(delay: 300.ms),

            const SizedBox(height: 24),

            // Select Time
            const Text(
              'اختر الوقت',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ).animate().fade(delay: 400.ms),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _timeSlots.map((time) {
                final isSelected = _selectedTime == time;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = time),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? primaryColor : Colors.grey[200]!),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                      ],
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ).animate().fade(delay: 500.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _selectedService != null && _selectedTime != null
              ? () {
                  // Book Logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تأكيد طلب الحجز بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.pop();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text(
            'تأكيد الحجز',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
