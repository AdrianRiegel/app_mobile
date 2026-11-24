import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/question.dart';
import '../models/turma.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';
import 'question_form_screen.dart';

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
              onPressed: _abrirNovaQuestao,
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
              loading: _salvando,
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
                onPressed: () => _abrirEdicaoQuestao(index),
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

  Future<void> _abrirNovaQuestao() async {
    final novas = await Navigator.push<List<Question>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            QuestionFormScreen(questionNumber: _questions.length + 1),
      ),
    );
    if (novas == null || novas.isEmpty || !mounted) return;
    setState(() => _questions.addAll(novas));
    _showFeedback(
      novas.length == 1
          ? 'Questão ${_questions.length} adicionada com sucesso'
          : '${novas.length} questões importadas com sucesso',
    );
  }

  Future<void> _abrirEdicaoQuestao(int index) async {
    if (index < 0 || index >= _questions.length) return;
    final editada = await Navigator.push<List<Question>>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionFormScreen(
          questionNumber: index + 1,
          initialQuestion: _questions[index],
        ),
      ),
    );
    if (editada == null || editada.isEmpty || !mounted) return;
    setState(() => _questions[index] = editada.first);
    _showFeedback('Questão ${index + 1} atualizada com sucesso');
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
