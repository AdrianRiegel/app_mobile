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
  final _titleController = TextEditingController();
  DateTime? _dataAplicacao;
  bool _salvando = false;

  final List<Question> _questions = [];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataAplicacao ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (escolhida != null && mounted) {
      setState(() => _dataAplicacao = escolhida);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const StandardAppBar(title: 'Nova prova'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            Text(
              'Título da prova',
              style: TextStyle(
                color: context.colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration(
                hint: 'Ex: Avaliação bimestral — Cap. 4',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Data de aplicação',
              style: TextStyle(
                color: context.colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _selecionarData,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: context.colors.input,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.colors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dataAplicacao == null
                          ? 'Selecionar data'
                          : AvaliacaoRepository.formatarData(_dataAplicacao!),
                      style: TextStyle(
                        fontSize: 14,
                        color: _dataAplicacao == null
                            ? context.colors.muted
                            : context.colors.text,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: context.colors.accent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Questões adicionadas',
                  style: TextStyle(
                    color: context.colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_questions.length} '
                  '${_questions.length == 1 ? 'questão' : 'questões'}',
                  style: TextStyle(color: context.colors.muted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_questions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Nenhuma questão adicionada. Use o botão abaixo para '
                  'montar a prova.',
                  style: TextStyle(color: context.colors.muted, fontSize: 12),
                ),
              ),
            ..._questions.asMap().entries.map(
              (entry) => _questionCard(entry.key + 1, entry.key, entry.value),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _openAddQuestionSheet,
              icon: Icon(Icons.add, size: 18, color: context.colors.accent),
              label: Text(
                'Adicionar questão',
                style: TextStyle(
                  color: context.colors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.colors.accent, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ],
        ),
      ),
      // Como bottomNavigationBar, os SnackBars (ex.: "Questão adicionada")
      // aparecem acima do botão em vez de cobri-lo.
      bottomNavigationBar: Container(
        color: context.colors.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: PrimaryButton(
              label: _salvando ? 'Salvando...' : 'Salvar prova',
              onPressed: _salvando ? null : _save,
            ),
          ),
        ),
      ),
    );
  }

  Widget _questionCard(int number, int index, Question question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.border),
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
                  style: TextStyle(
                    color: context.colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.successLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Correta: ${question.correctLetter}',
                  style: TextStyle(
                    color: context.colors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: context.colors.accent,
                ),
                tooltip: 'Editar questão',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: () => _openEditQuestionSheet(index),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: context.colors.danger,
                ),
                tooltip: 'Remover questão',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: () => _removerQuestao(index),
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
                        ? context.colors.success
                        : context.colors.border,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${String.fromCharCode(97 + entry.key)}) ${entry.value}',
                      style: TextStyle(
                        color: entry.key == question.correctIndex
                            ? context.colors.text
                            : context.colors.muted,
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

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: context.colors.input,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.colors.accent, width: 1.5),
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
        dataAplicacao: _dataAplicacao,
        respostas: [
          for (final question in _questions)
            String.fromCharCode(65 + question.correctIndex),
        ],
      );
      if (!mounted) return;
      Navigator.pop(context, assessment);
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _showFeedback('Não foi possível salvar a prova');
    }
  }

  /// Remove a questão (as seguintes são renumeradas) e oferece desfazer.
  void _removerQuestao(int index) {
    final removida = _questions[index];
    setState(() => _questions.removeAt(index));

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Questão ${index + 1} removida'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () {
            if (!mounted) return;
            setState(() => _questions.insert(index, removida));
          },
        ),
      ),
    );
  }

  void _showFeedback(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
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
        decoration: BoxDecoration(
          color: context.colors.surface,
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
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text(
                isEditing
                    ? 'Editar questão ${widget.questionNumber}'
                    : 'Questão ${widget.questionNumber}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.text,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Enunciado da questão',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.colors.muted,
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
                  fillColor: context.colors.input,
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.colors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Alternativas (Selecione a correta)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.colors.muted,
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
                              ? context.colors.success
                              : context.colors.muted,
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
                            fillColor: context.colors.input,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: context.colors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: context.colors.accent,
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
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.colors.accent,
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
