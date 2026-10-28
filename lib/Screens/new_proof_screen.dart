import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/question.dart';
import '../models/turma.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';

class NewProofScreen extends StatefulWidget {
  const NewProofScreen({super.key, required this.turma});

  final Turma turma;

  @override
  State<NewProofScreen> createState() => _NewProofScreenState();
}

class _NewProofScreenState extends State<NewProofScreen> {
  final _titleController = TextEditingController(
    text: 'Avaliação bimestral — Cap. 4',
  );
  bool _salvando = false;

  final List<Question> _questions = [
    const Question(
      statement: 'Qual é o resultado de 7 × 8?',
      options: ['54', '56', '58', '60'],
      correctIndex: 1,
    ),
    const Question(
      statement: 'Qual fração equivale a 0,5?',
      options: ['1/2', '1/4', '2/3', '3/4'],
      correctIndex: 0,
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
      appBar: const StandardAppBar(title: 'Nova prova'),
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
                Text(
                  '${_questions.length} questões',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_questions.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Nenhuma questão cadastrada ainda. Toque em "Adicionar questão".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              )
            else
              ..._questions.asMap().entries.map(
                (entry) => _questionCard(entry.key + 1, entry.value),
              ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Adicionar questão',
              icon: Icons.add,
              verticalPadding: 14,
              foregroundColor: AppColors.text,
              onPressed: _openAddQuestionSheet,
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: _salvando ? 'Salvando...' : 'Salvar prova',
              verticalPadding: 15,
              onPressed: _salvando ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(int number, Question question) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '$number. ${question.statement}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Correta: ${question.correctLetter}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
                    size: 18,
                    color: entry.key == question.correctIndex
                        ? AppColors.success
                        : AppColors.border,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${String.fromCharCode(97 + entry.key)}) ${entry.value}',
                      style: TextStyle(
                        color: entry.key == question.correctIndex
                            ? AppColors.text
                            : AppColors.muted,
                        fontSize: 12,
                        fontWeight: entry.key == question.correctIndex
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
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

  void _openAddQuestionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddQuestionSheet(
        questionNumber: _questions.length + 1,
        onAdd: (newQuestion) {
          Navigator.pop(sheetContext);
          setState(() => _questions.add(newQuestion));
          _showFeedback('Questão ${_questions.length} adicionada com sucesso');
        },
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

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showFeedback('Informe um título para salvar a prova');
      return;
    }

    if (_questions.isEmpty) {
      _showFeedback('Adicione ao menos uma questão à prova');
      return;
    }

    setState(() => _salvando = true);
    try {
      final assessment = await AvaliacaoRepository().criar(
        turma: widget.turma,
        titulo: title,
        disciplina: widget.turma.disciplina,
        totalQuestoes: _questions.length,
        respostas: [for (final question in _questions) question.correctLetter],
      );
      if (!mounted) return;
      Navigator.pop(context, assessment);
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _showFeedback('Não foi possível salvar a prova');
    }
  }

  void _showFeedback(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _AddQuestionSheet extends StatefulWidget {
  const _AddQuestionSheet({
    required this.questionNumber,
    required this.onAdd,
  });

  final int questionNumber;
  final ValueChanged<Question> onAdd;

  @override
  State<_AddQuestionSheet> createState() => _AddQuestionSheetState();
}

class _AddQuestionSheetState extends State<_AddQuestionSheet> {
  final _statementController = TextEditingController();
  final List<TextEditingController> _optionsControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int _correctIndex = 0;

  @override
  void dispose() {
    _statementController.dispose();
    for (final c in _optionsControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 4, bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text(
                'Questão ${widget.questionNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Enunciado da questão',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _statementController,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Ex: Qual é a fórmula da água?',
                  filled: true,
                  fillColor: AppColors.input,
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Alternativas (Selecione a correta)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(4, (index) {
                final letter = String.fromCharCode(65 + index);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _correctIndex == index
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: _correctIndex == index
                              ? AppColors.success
                              : AppColors.muted,
                        ),
                        onPressed: () => setState(() => _correctIndex = index),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _optionsControllers[index],
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Alternativa $letter',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: AppColors.input,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Adicionar à prova',
                verticalPadding: 14,
                fontSize: 13,
                onPressed: _submit,
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final messenger = ScaffoldMessenger.of(context);
    final statement = _statementController.text.trim();
    if (statement.isEmpty) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Informe o enunciado da questão')),
      );
      return;
    }

    final options = _optionsControllers.map((c) => c.text.trim()).toList();
    if (options.any((opt) => opt.isEmpty)) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Preencha todas as 4 alternativas')),
      );
      return;
    }

    widget.onAdd(
      Question(
        statement: statement,
        options: options,
        correctIndex: _correctIndex,
      ),
    );
  }
}
