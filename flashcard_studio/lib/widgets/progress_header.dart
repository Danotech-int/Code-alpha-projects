import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class ProgressHeader extends StatelessWidget {
  const ProgressHeader({super.key, required this.index, required this.total});
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'YOUR STUDY SESSION',
              style: TextStyle(
                letterSpacing: 1.6,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
          ),
          Text(
            '${total == 0 ? 0 : index + 1} / $total',
            style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 14),
      LinearProgressIndicator(
        value: total == 0 ? 0 : (index + 1) / total,
        minHeight: 6,
        borderRadius: BorderRadius.circular(8),
        backgroundColor: const Color(0xFFE2E6DB),
        semanticsLabel: 'Card ${total == 0 ? 0 : index + 1} of $total',
      ),
    ],
  );
}
