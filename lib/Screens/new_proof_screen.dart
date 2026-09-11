import 'package:flutter/material.dart';

import '../models/assessment.dart';
import '../theme/app_colors.dart';

class NewProofScreen extends StatefulWidget {
  const NewProofScreen({super.key, required this.className});

  final String className;

  @override
  State<NewProofScreen> createState() => _NewProofScreenState();
}

class _QuestionDraft {
  const _QuestionDraft(this.statement, this.options, this.correctIndex);

  final String statement;
  final List<String> options;
  final int correctIndex;
}

class _NewProofScreenState extends State<NewProofScreen> {
  final _titleController = TextEditingController(
    text: 'Avaliação bimestral — Cap. 4',
  );

  final List<_QuestionDraft> _questions = const [
    _QuestionDraft(
      'Qual é o resultado de 7 × 8?',
      ['54', '56', '58'],
      1,
    ),
    _QuestionDraft(
      'Qual fração equivale a 0,5?',
      ['1/2', '1/4'],
      0,
    ),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Nova prova',
          style: TextStyle(
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
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            const Text(
              'Título da prova',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Questões',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => _showFeedback('Importação simulada'),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEEF0F3),
                    foregroundColor: AppColors.muted,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    'Importar prova',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._questions.asMap().entries.map(
              (entry) => _questionCard(entry.key + 1, entry.value),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showFeedback('Editor de questão disponível na próxima etapa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Adicionar questão',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Salvar prova',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(int number, _QuestionDraft question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ${question.statement}',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          ...question.options.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    entry.key == question.correctIndex
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: entry.key == question.correctIndex
                        ? AppColors.success
                        : AppColors.border,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${String.fromCharCode(97 + entry.key)}) ${entry.value}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.input,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showFeedback('Informe um título para salvar a prova');
      return;
    }

    Navigator.pop(
      context,
      Assessment(
        title: title,
        subject: 'Matemática',
        className: widget.className,
        dateLabel: 'Sem data',
        status: AssessmentStatus.draft,
        totalQuestions: _questions.length,
        correctedStudents: 0,
        totalStudents: 28,
      ),
    );
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
