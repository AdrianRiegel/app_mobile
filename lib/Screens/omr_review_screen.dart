import 'package:flutter/material.dart';

import '../components/components.dart';
import '../services/omr/omr_models.dart';
import '../theme/app_colors.dart';

class OmrReviewScreen extends StatefulWidget {
  const OmrReviewScreen({
    super.key,
    required this.result,
    this.studentName = 'Aluno',
  });

  final OmrProcessingResult result;
  final String studentName;

  @override
  State<OmrReviewScreen> createState() => _OmrReviewScreenState();
}

class _OmrReviewScreenState extends State<OmrReviewScreen> {
  late List<String?> _selectedAnswers;

  @override
  void initState() {
    super.initState();
    _selectedAnswers = widget.result.questions
        .map((q) => q.detectedLetter)
        .toList();
  }

  void _confirm() {
    Navigator.pop(context, _selectedAnswers);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    const options = ['A', 'B', 'C', 'D', 'E'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const StandardAppBar(title: 'Revisão do Cartão'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E6),
                border: Border.all(color: const Color(0xFFFFD573)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFD98200),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Revisão manual necessária',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A5300),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.reviewReason ??
                              'Algumas marcações possuem baixa confiança ou ambiguidade. '
                                  'Confirme as alternativas marcadas por ${widget.studentName}.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A5300),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Respostas Detectadas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.result.questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              final currentSelection = _selectedAnswers[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(
                    color: question.needsReview
                        ? const Color(0xFFFFD573)
                        : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Questão ${question.questao}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        if (question.isMultipleMarked)
                          _statusTag(
                            'Dupla marcação',
                            const Color(0xFFFFEBEB),
                            Colors.red[700]!,
                          )
                        else if (question.isAmbiguous)
                          _statusTag(
                            'Rasura/Ambígua',
                            const Color(0xFFFFF4D4),
                            const Color(0xFFB36B00),
                          )
                        else if (question.isBlank)
                          _statusTag('Em branco', AppColors.neutralLight, AppColors.muted)
                        else
                          _statusTag('OK', AppColors.successLight, AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final opt in options)
                          ChoiceChip(
                            label: Text(opt),
                            selected: currentSelection == opt,
                            selectedColor: AppColors.accent,
                            labelStyle: TextStyle(
                              color: currentSelection == opt
                                  ? Colors.white
                                  : AppColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedAnswers[index] = selected ? opt : null;
                              });
                            },
                          ),
                        ChoiceChip(
                          label: const Text('Em branco'),
                          selected: currentSelection == null,
                          selectedColor: AppColors.muted,
                          labelStyle: TextStyle(
                            color: currentSelection == null
                                ? Colors.white
                                : AppColors.muted,
                            fontSize: 11,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedAnswers[index] = null);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Confirmar respostas e continuar',
              verticalPadding: 14,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTag(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
