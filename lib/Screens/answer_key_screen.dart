import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/assessment.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';

class AnswerKeyScreen extends StatefulWidget {
  const AnswerKeyScreen({super.key, required this.assessment});

  final Assessment assessment;

  @override
  State<AnswerKeyScreen> createState() => _AnswerKeyScreenState();
}

class _AnswerKeyScreenState extends State<AnswerKeyScreen> {
  static const _options = ['A', 'B', 'C', 'D', 'E'];
  late final List<String?> _answers;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _answers = [
      for (final questao in widget.assessment.gabarito)
        questao.alternativaCorreta,
    ];
  }

  Future<void> _salvar() async {
    if (_answers.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marque a alternativa correta de todas as questões'),
        ),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final atualizada = await AvaliacaoRepository().salvarGabarito(
        widget.assessment,
        _answers.cast<String>(),
      );
      if (!mounted) return;
      Navigator.pop(context, atualizada);
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o gabarito')),
      );
    }
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
                itemCount: _answers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _questionRow(index),
              ),
            ),
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: PrimaryButton(
                label: _salvando ? 'Salvando...' : 'Salvar gabarito',
                icon: Icons.check,
                verticalPadding: 14,
                fontSize: 13,
                onPressed: _salvando ? null : _salvar,
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
