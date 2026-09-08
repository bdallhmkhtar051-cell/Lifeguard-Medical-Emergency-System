import 'package:flutter/material.dart';

import 'access_models.dart';

/// Shows the generated text without saving it into the patient's health record.
class AiMedicalSummaryDialog extends StatelessWidget {
  const AiMedicalSummaryDialog({required this.summary, super.key});

  final AiMedicalSummary summary;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
          SizedBox(width: 10),
          Expanded(child: Text('AI Medical Summary')),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(summary.summary, style: const TextStyle(height: 1.55)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Text(
                summary.disclaimer,
                style: const TextStyle(
                  color: Color(0xFF9A3412),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Generated temporarily with ${summary.model}. This text is not stored in the patient record.',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
