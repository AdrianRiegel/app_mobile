import 'package:flutter/material.dart';

import '../components/components.dart';
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
      appBar: StandardAppBar(
        title: 'Notas · ${proofTitle.replaceFirst('Avaliação ', '')}',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: StatSummaryCard(
                  label: 'Média da turma',
                  value: '7.8',
                  showBorder: false,
                  valueFontSize: 24,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatSummaryCard(
                  label: 'Aplicadas',
                  value: '28/28',
                  showBorder: false,
                  valueFontSize: 24,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
                ),
              ),
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
            (student) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _studentCard(
                name: student.$1,
                initials: student.$2,
                grade: student.$3,
                detail: student.$4,
                passing: student.$5,
              ),
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
    return AppListItemCard(
      leading: Container(
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
      title: name,
      titleFontSize: 14,
      subtitle: Text(detail, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      trailing: StatusBadge(
        label: grade,
        background: passing ? AppColors.successLight : AppColors.neutralLight,
        foreground: passing ? AppColors.success : AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        horizontalPadding: 9,
        verticalPadding: 5,
        borderRadius: 18,
      ),
    );
  }
}
