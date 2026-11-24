import 'package:flutter/material.dart';

import '../components/components.dart';
import '../components/inputs/csv_file_picker.dart';
import '../models/question.dart';
import '../services/csv_import_service.dart';
import '../theme/app_colors.dart';

/// Página para criar ou editar questões de uma prova.
///
/// Ao criar, permite preencher uma questão ou importar várias de um CSV.
/// Fecha devolvendo as questões (`List<Question>`), ou `null` se cancelada.
class QuestionFormScreen extends StatefulWidget {
  const QuestionFormScreen({
    super.key,
    required this.questionNumber,
    this.initialQuestion,
    this.csvPicker = CsvImportService.pickCsvFile,
  });

  final int questionNumber;

  /// Questão em edição; sem ela, a página cria questões novas.
  final Question? initialQuestion;

  /// Permite substituir o seletor de arquivo (ex.: em testes).
  final Future<CsvFile?> Function() csvPicker;

  bool get isEditing => initialQuestion != null;

  @override
  State<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends State<QuestionFormScreen> {
  static const _totalAlternativas = 4;

  late final _statementController = TextEditingController(
    text: widget.initialQuestion?.statement ?? '',
  );
  late final _optionsControllers = List.generate(_totalAlternativas, (i) {
    final options = widget.initialQuestion?.options ?? const <String>[];
    return TextEditingController(text: i < options.length ? options[i] : '');
  });
  late int _correctIndex = widget.initialQuestion?.correctIndex ?? 0;

  final _csvController = TextEditingController();
  CsvProofQuestionsResult? _csvResultado;

  @override
  void dispose() {
    _statementController.dispose();
    for (final controller in _optionsControllers) {
      controller.dispose();
    }
    _csvController.dispose();
    super.dispose();
  }

  void _atualizarCsv(String conteudo) {
    setState(() {
      _csvResultado = conteudo.trim().isEmpty
          ? null
          : CsvImportService.parseProofQuestions(conteudo);
    });
  }

  void _mostrarAviso(String mensagem) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(mensagem)));
  }

  void _salvarManual() {
    final statement = _statementController.text.trim();
    if (statement.isEmpty) {
      _mostrarAviso('Informe o enunciado da questão');
      return;
    }
    final options = _optionsControllers.map((c) => c.text.trim()).toList();
    if (options.any((option) => option.isEmpty)) {
      _mostrarAviso('Preencha todas as $_totalAlternativas alternativas');
      return;
    }
    Navigator.pop(context, [
      Question(
        statement: statement,
        options: options,
        correctIndex: _correctIndex,
      ),
    ]);
  }

  void _importarCsv() {
    final questoes = _csvResultado?.questoes ?? const <Question>[];
    if (questoes.isEmpty) return;
    Navigator.pop(context, questoes);
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.isEditing
        ? 'Editar questão ${widget.questionNumber}'
        : 'Questão ${widget.questionNumber}';

    if (widget.isEditing) {
      return Scaffold(
        backgroundColor: context.colors.background,
        appBar: StandardAppBar(title: titulo),
        body: SafeArea(top: false, child: _formularioManual()),
        bottomNavigationBar: _barraInferior(
          PrimaryButton(
            label: 'Salvar alterações',
            verticalPadding: 14,
            fontSize: 13,
            onPressed: _salvarManual,
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabs = DefaultTabController.of(context);
          return Scaffold(
            backgroundColor: context.colors.background,
            appBar: StandardAppBar(title: titulo),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  TabBar(
                    labelColor: context.colors.accent,
                    unselectedLabelColor: context.colors.muted,
                    indicatorColor: context.colors.accent,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Preencher', icon: Icon(Icons.edit_note, size: 20)),
                      Tab(
                        text: 'Importar CSV',
                        icon: Icon(Icons.file_upload_outlined, size: 20),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [_formularioManual(), _importacaoCsv()],
                    ),
                  ),
                ],
              ),
            ),
            // O botão muda conforme a aba ativa.
            bottomNavigationBar: AnimatedBuilder(
              animation: tabs,
              builder: (context, _) => _barraInferior(
                tabs.index == 0
                    ? PrimaryButton(
                        label: 'Adicionar à prova',
                        verticalPadding: 14,
                        fontSize: 13,
                        onPressed: _salvarManual,
                      )
                    : PrimaryButton(
                        label: _rotuloImportar,
                        icon: Icons.playlist_add,
                        verticalPadding: 14,
                        fontSize: 13,
                        onPressed: (_csvResultado?.temQuestoes ?? false)
                            ? _importarCsv
                            : null,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  String get _rotuloImportar {
    final total = _csvResultado?.questoes.length ?? 0;
    if (total == 0) return 'Importar questões';
    return total == 1 ? 'Importar 1 questão' : 'Importar $total questões';
  }

  Widget _barraInferior(Widget botao) {
    return Container(
      color: context.colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: botao,
        ),
      ),
    );
  }

  Widget _rotulo(String texto) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: context.colors.muted,
      ),
    );
  }

  InputDecoration _decoracao(String hint, {bool dense = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.colors.muted, fontSize: 12),
      isDense: dense,
      filled: true,
      fillColor: context.colors.input,
      contentPadding: dense
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : const EdgeInsets.all(12),
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

  Widget _formularioManual() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        _rotulo('Enunciado da questão'),
        const SizedBox(height: 6),
        TextField(
          controller: _statementController,
          minLines: 3,
          maxLines: 6,
          style: TextStyle(fontSize: 13, color: context.colors.text),
          decoration: _decoracao('Ex: Qual é a fórmula da água?'),
        ),
        const SizedBox(height: 18),
        _rotulo('Alternativas (selecione a correta)'),
        const SizedBox(height: 8),
        for (var index = 0; index < _totalAlternativas; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip:
                      'Marcar alternativa ${String.fromCharCode(65 + index)} '
                      'como correta',
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
                    style: TextStyle(fontSize: 13, color: context.colors.text),
                    decoration: _decoracao(
                      'Alternativa ${String.fromCharCode(65 + index)}',
                      dense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _importacaoCsv() {
    final resultado = _csvResultado;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Text(
          'Importe várias questões de uma vez. Cada linha é uma questão, com '
          'as colunas enunciado, a, b, c, d e correta (letra de A a D), '
          'separadas por ponto e vírgula ou vírgula.',
          style: TextStyle(fontSize: 12, color: context.colors.muted, height: 1.4),
        ),
        const SizedBox(height: 12),
        CsvFilePicker(
          hint: 'Formato: ${CsvImportService.proofQuestionsColumns}',
          picker: widget.csvPicker,
          onChanged: (file) {
            _csvController.text = file?.content ?? '';
            _atualizarCsv(_csvController.text);
          },
        ),
        const SizedBox(height: 12),
        _rotulo('Ou cole o conteúdo do CSV'),
        const SizedBox(height: 6),
        TextField(
          controller: _csvController,
          minLines: 5,
          maxLines: 10,
          onChanged: _atualizarCsv,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: context.colors.text,
          ),
          decoration: _decoracao(
            'enunciado;a;b;c;d;correta\n'
            'Quanto é 7 × 8?;54;56;58;60;B\n'
            'Qual fração equivale a 0,5?;1/2;1/4;2/3;3/4;A',
          ),
        ),
        if (resultado != null) ...[
          const SizedBox(height: 16),
          _resumoCsv(resultado),
        ],
      ],
    );
  }

  Widget _resumoCsv(CsvProofQuestionsResult resultado) {
    const maxErros = 5;
    final total = resultado.questoes.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              total > 0 ? Icons.check_circle_outline : Icons.error_outline,
              size: 18,
              color: total > 0 ? context.colors.success : context.colors.danger,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                total == 1
                    ? '1 questão pronta para importar'
                    : '$total questões prontas para importar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.text,
                ),
              ),
            ),
          ],
        ),
        for (final (index, questao) in resultado.questoes.indexed)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 24),
            child: Text(
              '${index + 1}. ${questao.statement} '
              '(correta: ${questao.correctLetter})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: context.colors.muted),
            ),
          ),
        if (resultado.erros.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.dangerLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resultado.erros.length == 1
                      ? '1 linha ignorada'
                      : '${resultado.erros.length} linhas ignoradas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.danger,
                  ),
                ),
                for (final erro in resultado.erros.take(maxErros))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      erro,
                      style: TextStyle(fontSize: 11, color: context.colors.danger),
                    ),
                  ),
                if (resultado.erros.length > maxErros)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'e mais ${resultado.erros.length - maxErros}',
                      style: TextStyle(fontSize: 11, color: context.colors.danger),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
