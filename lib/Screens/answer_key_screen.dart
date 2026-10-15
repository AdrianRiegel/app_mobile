import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/assessment.dart';
import '../theme/app_colors.dart';

class AnswerKeyScreen extends StatefulWidget {
  const AnswerKeyScreen({super.key, required this.assessment});

  final Assessment assessment;

  @override
  State<AnswerKeyScreen> createState() => _AnswerKeyScreenState();
}

class _AnswerKeyScreenState extends State<AnswerKeyScreen> {
  static const _options = ['A', 'B', 'C', 'D', 'E'];
  late final List<String> _answers;

  @override
  void initState() {
    super.initState();
    _answers = List.generate(
      widget.assessment.totalQuestions,
      (index) => _options[index % _options.length],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const StandardAppBar(title: 'Configurar gabarito'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.assessment.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.assessment.className} · ${widget.assessment.totalQuestions} questões',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                itemCount: widget.assessment.totalQuestions,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _questionRow(index),
              ),
            ),
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: PrimaryButton(
                label: 'Salvar gabarito',
                icon: Icons.check,
                verticalPadding: 14,
                fontSize: 13,
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionRow(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${index + 1}.',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _options.map((option) {
                final selected = _answers[index] == option;
                return GestureDetector(
                  onTap: () => setState(() => _answers[index] = option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accent
                          : AppColors.accentLight,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
