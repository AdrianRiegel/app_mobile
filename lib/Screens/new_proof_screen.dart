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
                (entry) => _questionCard(entry.key + 1, entry.key, entry.value),
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

  Widget _questionCard(int number, int index, Question question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
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
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.accent,
                ),
                tooltip: 'Editar questão',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: () => _openEditQuestionSheet(index),
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
      builder: (sheetContext) => _QuestionFormSheet(
        questionNumber: _questions.length + 1,
        onSave: (newQuestion) {
          Navigator.pop(sheetContext);
          setState(() => _questions.add(newQuestion));
          _showFeedback('Questão ${_questions.length} adicionada com sucesso');
        },
      ),
    );
  }

  void _openEditQuestionSheet(int index) {
    if (index < 0 || index >= _questions.length) return;
    final question = _questions[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _QuestionFormSheet(
        questionNumber: index + 1,
        initialQuestion: question,
        onSave: (updatedQuestion) {
          Navigator.pop(sheetContext);
          setState(() => _questions[index] = updatedQuestion);
          _showFeedback('Questão ${index + 1} atualizada com sucesso');
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

class _QuestionFormSheet extends StatefulWidget {
  const _QuestionFormSheet({
    required this.questionNumber,
    this.initialQuestion,
    required this.onSave,
  });

  final int questionNumber;
  final Question? initialQuestion;
  final ValueChanged<Question> onSave;

  @override
  State<_QuestionFormSheet> createState() => _QuestionFormSheetState();
}

class _QuestionFormSheetState extends State<_QuestionFormSheet> {
  late final TextEditingController _statementController;
  late final List<TextEditingController> _optionsControllers;
  late int _correctIndex;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuestion;
    _statementController = TextEditingController(
      text: initial?.statement ?? '',
    );
    _optionsControllers = List.generate(4, (i) {
      final text = (initial != null && i < initial.options.length)
          ? initial.options[i]
          : '';
      return TextEditingController(text: text);
    });
    _correctIndex = initial?.correctIndex ?? 0;
  }

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
    final isEditing = widget.initialQuestion != null;
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
                isEditing
                    ? 'Editar questão ${widget.questionNumber}'
                    : 'Questão ${widget.questionNumber}',
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
                label: isEditing ? 'Salvar alterações' : 'Adicionar à prova',
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

    widget.onSave(
      Question(
        statement: statement,
        options: options,
        correctIndex: _correctIndex,
      ),
    );
  }
}
