import 'package:flutter/material.dart';
import '../../../models/workspace_note.dart';
import 'base_node_wrapper.dart';

class PrescriptionNodeWidget extends StatelessWidget {
  final WorkspaceNote note;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String title) onTitleChange;
  final Function(String colorHex) onColorChange;
  final Function(Map<String, dynamic> metadata) onMetadataChange;
  final Function(double x, double y) onPositionUpdate;
  final Function(String id, Offset localPosition)? onConnectStart;
  final VoidCallback? onToggleLock;
  final VoidCallback? onClearConnections;

  const PrescriptionNodeWidget({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onTitleChange,
    required this.onColorChange,
    required this.onMetadataChange,
    required this.onPositionUpdate,
    this.onConnectStart,
    this.onToggleLock,
    this.onClearConnections,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = note.metadata ?? {};
    final medications = (metadata['medications'] as List<dynamic>?) ?? [];

    return BaseNodeWrapper(
      note: note,
      isSelected: isSelected,
      onTap: onTap,
      onDelete: onDelete,
      onTitleChange: onTitleChange,
      onColorChange: onColorChange,
      onPositionUpdate: onPositionUpdate,
      onConnectStart: onConnectStart,
      onToggleLock: onToggleLock,
      onClearConnections: onClearConnections,
      icon: Icons.medication_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الأدوية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.teal),
                onPressed: () {
                  final newList = [...medications, {'name': '', 'dose': '', 'instruction': ''}];
                  onMetadataChange({...metadata, 'medications': newList});
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final med = medications[index] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: med['name'],
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(hintText: 'اسم الدواء', isDense: true, border: InputBorder.none),
                                onChanged: (val) {
                                  final newList = List<Map<String, dynamic>>.from(medications);
                                  newList[index] = {...newList[index], 'name': val};
                                  onMetadataChange({...metadata, 'medications': newList});
                                },
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: med['dose'],
                                style: const TextStyle(fontSize: 11),
                                decoration: const InputDecoration(hintText: 'الجرعة', isDense: true, border: InputBorder.none),
                                onChanged: (val) {
                                  final newList = List<Map<String, dynamic>>.from(medications);
                                  newList[index] = {...newList[index], 'dose': val};
                                  onMetadataChange({...metadata, 'medications': newList});
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 14, color: Colors.red),
                              onPressed: () {
                                final newList = List<Map<String, dynamic>>.from(medications);
                                newList.removeAt(index);
                                onMetadataChange({...metadata, 'medications': newList});
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const Divider(height: 8),
                        TextFormField(
                          initialValue: med['instruction'],
                          style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                          decoration: const InputDecoration(hintText: 'تعليمات (مثلاً: قبل الأكل)', isDense: true, border: InputBorder.none),
                          onChanged: (val) {
                            final newList = List<Map<String, dynamic>>.from(medications);
                            newList[index] = {...newList[index], 'instruction': val};
                            onMetadataChange({...metadata, 'medications': newList});
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
