import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProofGradesScreen extends StatelessWidget {
  const ProofGradesScreen({
    super.key,
    required this.proofTitle,
    required this.className,
  });

  final String proofTitle;
  final String className;

  @override
  Widget build(BuildContext context) {
    const students = [
      ('Ana Beatriz', 'AB', '9.0', '9 acertos de 10', true),
      ('Carlos Dias', 'CD', '6.0', '6 acertos de 10', false),
      ('Elisa Ferreira', 'EF', '8.0', '8 acertos de 10', true),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 20),
          color: AppColors.text,
        ),
        title: Text(
          'Notas · ${proofTitle.replaceFirst('Avaliação ', '')}',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Expanded(child: _summaryCard('Média da turma', '7.8')),
              const SizedBox(width: 10),
              Expanded(child: _summaryCard('Aplicadas', '28/28')),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$className · $proofTitle',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...students.map(
            (student) => _studentCard(
              name: student.$1,
              initials: student.$2,
              grade: student.$3,
              detail: student.$4,
              passing: student.$5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentCard({
    required String name,
    required String initials,
    required String grade,
    required String detail,
    required bool passing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: passing ? AppColors.successLight : const Color(0xFFEEF0F3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              grade,
              style: TextStyle(
                color: passing ? AppColors.success : AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
