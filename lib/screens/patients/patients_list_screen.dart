import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/patients_provider.dart';

class PatientsListScreen extends ConsumerWidget {
  const PatientsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(searchedPatientsProvider);
    final searchController = TextEditingController(text: ref.watch(patientSearchProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text('المجلي - قائمة المرضى'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن مريض...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                ref.read(patientSearchProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ),
      body: patientsAsync.when(
        data: (patients) => ListView.builder(
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(patient.fullName),
              subtitle: Text(patient.phone ?? 'لا يوجد رقم هاتف'),
              onTap: () {
                // Navigate to patient details
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open add patient screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
