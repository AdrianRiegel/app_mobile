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
      backgroundColor: context.colors.background,
      appBar: const StandardAppBar(title: 'Revisão do Cartão'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.colors.warningLight,
                border: Border.all(color: context.colors.warning),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: context.colors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revisão manual necessária',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.colors.warning,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.reviewReason ??
                              'Algumas marcações possuem baixa confiança ou ambiguidade. '
                                  'Confirme as alternativas marcadas por ${widget.studentName}.',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Respostas Detectadas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.text,
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
                  color: context.colors.surface,
                  border: Border.all(
                    color: question.needsReview
                        ? context.colors.warning
                        : context.colors.border,
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
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.colors.text,
                          ),
                        ),
                        if (question.isMultipleMarked)
                          _statusTag(
                            'Dupla marcação',
                            context.colors.dangerLight,
                            context.colors.danger,
                          )
                        else if (question.isAmbiguous)
                          _statusTag(
                            'Rasura/Ambígua',
                            context.colors.warningLight,
                            context.colors.warning,
                          )
                        else if (question.isBlank)
                          _statusTag('Em branco', context.colors.neutralLight, context.colors.muted)
                        else
                          _statusTag('OK', context.colors.successLight, context.colors.success),
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
                            selectedColor: context.colors.accent,
                            labelStyle: TextStyle(
                              color: currentSelection == opt
                                  ? Colors.white
                                  : context.colors.text,
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
                          selectedColor: context.colors.muted,
                          labelStyle: TextStyle(
                            color: currentSelection == null
                                ? Colors.white
                                : context.colors.muted,
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
