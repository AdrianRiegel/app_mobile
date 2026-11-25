import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../components/components.dart';
import '../models/statistics.dart';
import '../services/database/database.dart';
import '../services/pdf/relatorio_pdf.dart';
import '../theme/app_colors.dart';

/// Salva/compartilha o PDF gerado. No celular abre o menu de
/// compartilhamento (salvar em arquivos, enviar, imprimir); na web baixa.
typedef CompartilharPdf = Future<void> Function(Uint8List bytes, String nome);

Future<void> _compartilharComPrinting(Uint8List bytes, String nome) async {
  await Printing.sharePdf(bytes: bytes, filename: nome);
}

enum TipoRelatorio {
  desempenho('Desempenho da turma (notas por aluno)'),
  estatisticas('Estatísticas das provas (acerto por questão)');

  const TipoRelatorio(this.label);

  final String label;
}

/// Tela 7 — Gerar relatório (PDF).
///
/// Permite escolher a turma, o tipo de relatório e, opcionalmente, uma
/// prova. Gera o PDF com os dados do banco e exibe a prévia ao vivo.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.compartilharPdf});

  /// Troca a forma de salvar o PDF (usado nos testes).
  final CompartilharPdf? compartilharPdf;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<ClassStatistics> _classes = [];
  bool _carregando = true;
  bool _erro = false;

  late ClassStatistics _selectedClass;
  ExamStatistics? _selectedExam; // null = todas as provas
  TipoRelatorio _tipo = TipoRelatorio.desempenho;

  Uint8List? _previewBytes;
  String? _previewFileName;
  List<Uint8List> _previewPages = [];
  bool _carregandoPrevia = false;
  bool _erroPrevia = false;
  int _previewRequestId = 0;

  bool _gerando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      final classes = await EstatisticasRepository().porTurma();
      if (!mounted) return;
      setState(() {
        _classes = classes;
        if (classes.isNotEmpty) _selectedClass = classes.first;
        _carregando = false;
      });
      if (classes.isNotEmpty) {
        _atualizarPrevia();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = true;
        _carregando = false;
      });
    }
  }

  Future<void> _atualizarPrevia() async {
    if (_classes.isEmpty) return;
    final requestId = ++_previewRequestId;
    setState(() {
      _carregandoPrevia = true;
      _erroPrevia = false;
    });

    try {
      final (bytes, nome) = await _montarPdf();
      final paginas = await _rasterizarPaginas(bytes);
      if (!mounted || requestId != _previewRequestId) return;
      setState(() {
        _previewBytes = bytes;
        _previewFileName = nome;
        _previewPages = paginas;
        _carregandoPrevia = false;
      });
    } catch (_) {
      if (!mounted || requestId != _previewRequestId) return;
      setState(() {
        _erroPrevia = true;
        _carregandoPrevia = false;
      });
    }
  }

  Future<List<Uint8List>> _rasterizarPaginas(Uint8List bytes) async {
    try {
      final info = await Printing.info();
      if (!info.canRaster) return const [];
      final paginas = <Uint8List>[];
      await for (final pagina in Printing.raster(bytes, dpi: 110)) {
        paginas.add(await pagina.toPng());
      }
      return paginas;
    } catch (_) {
      // Ambientes sem suporte nativo de rasterização (ex.: testes headless)
      // usam o resumo estruturado como prévia.
      return const [];
    }
  }

  void _abrirPreviaTelaCheia() {
    final bytes = _previewBytes;
    final nome = _previewFileName;
    if (bytes == null || nome == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(
          title: 'Prévia do PDF',
          fileName: nome,
          bytes: bytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const StandardAppBar(title: 'Relatório'),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.accent),
      );
    }
    if (_erro) {
      return LoadErrorView(onRetry: _carregar);
    }
    if (_classes.isEmpty) {
      return EmptyStateView(
        icon: Icons.picture_as_pdf_outlined,
        iconBackground: context.colors.accentLight,
        iconColor: context.colors.accent,
        title: 'Nenhuma turma cadastrada',
        message: 'Cadastre turmas e corrija provas para gerar relatórios.',
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            children: [
              const _FieldLabel('Turma'),
              _dropdown<ClassStatistics>(
                value: _selectedClass,
                items: _classes,
                labelBuilder: (c) => c.displayName,
                onChanged: (value) {
                  if (value == null || value == _selectedClass) return;
                  setState(() {
                    _selectedClass = value;
                    _selectedExam = null;
                    _previewBytes = null;
                    _previewPages = [];
                  });
                  _atualizarPrevia();
                },
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Tipo de relatório'),
              _dropdown<TipoRelatorio>(
                value: _tipo,
                items: TipoRelatorio.values,
                labelBuilder: (tipo) => tipo.label,
                onChanged: (value) {
                  if (value == null || value == _tipo) return;
                  setState(() {
                    _tipo = value;
                    _previewBytes = null;
                    _previewPages = [];
                  });
                  _atualizarPrevia();
                },
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Prova (opcional)'),
              _dropdown<ExamStatistics?>(
                value: _selectedExam,
                items: <ExamStatistics?>[null, ..._selectedClass.exams],
                labelBuilder: (e) => e?.assessmentTitle ?? 'Todas as provas',
                onChanged: (value) {
                  if (value == _selectedExam) return;
                  setState(() {
                    _selectedExam = value;
                    _previewBytes = null;
                    _previewPages = [];
                  });
                  _atualizarPrevia();
                },
              ),
              const SizedBox(height: 20),
              _previewBox(),
            ],
          ),
        ),
        Container(
          color: context.colors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: PrimaryButton(
            label: _gerando ? 'Gerando PDF...' : 'Gerar e baixar PDF',
            loading: _gerando,
            icon: Icons.download_outlined,
            verticalPadding: 14,
            fontSize: 13,
            onPressed: _gerando ? null : _generate,
          ),
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.colors.input,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: context.colors.muted, size: 20),
          style: TextStyle(color: context.colors.text, fontSize: 13),
          borderRadius: BorderRadius.circular(10),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                child: Text(
                  labelBuilder(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _previewBox() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.input,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.picture_as_pdf_outlined,
                size: 16,
                color: context.colors.accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Prévia do relatório em PDF',
                  style: TextStyle(
                    color: context.colors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_previewBytes != null)
                TextButton.icon(
                  onPressed: _abrirPreviaTelaCheia,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    Icons.open_in_full,
                    size: 14,
                    color: context.colors.accent,
                  ),
                  label: Text(
                    'Ampliar',
                    style: TextStyle(
                      color: context.colors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_erroPrevia)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 30,
                    color: context.colors.danger,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Não foi possível carregar a prévia.',
                    style: TextStyle(color: context.colors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _atualizarPrevia,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          else if (_previewPages.isNotEmpty)
            _renderedPages()
          else ...[
            if (_carregandoPrevia)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Renderizando páginas do PDF...',
                  style: TextStyle(color: context.colors.muted, fontSize: 11),
                ),
              ),
            _previewContent(),
          ],
        ],
      ),
    );
  }

  Widget _renderedPages() {
    return Column(
      children: [
        for (var i = 0; i < _previewPages.length; i++) ...[
          GestureDetector(
            onTap: _abrirPreviaTelaCheia,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: context.colors.border),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(
                _previewPages[i],
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Página ${i + 1} de ${_previewPages.length}',
            style: TextStyle(color: context.colors.muted, fontSize: 10),
          ),
          if (i < _previewPages.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _previewContent() {
    final exams = _selectedExam != null
        ? [_selectedExam!]
        : _selectedClass.exams;
    final average = exams.isEmpty
        ? 0
        : (exams.fold<int>(0, (sum, e) => sum + e.averageScore) / exams.length)
              .round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tipo == TipoRelatorio.desempenho
                ? 'Relatório de desempenho'
                : 'Relatório de estatísticas',
            style: TextStyle(
              color: context.colors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'EduTurmas · gerado em ${_todayLabel()}',
            style: TextStyle(color: context.colors.muted, fontSize: 10),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: context.colors.border),
          ),
          _previewLine(
            'Tipo',
            _tipo == TipoRelatorio.desempenho
                ? 'Notas por aluno'
                : 'Acerto por questão',
          ),
          _previewLine('Turma', _selectedClass.displayName),
          _previewLine(
            'Prova',
            _selectedExam?.assessmentTitle ?? 'Todas as provas',
          ),
          _previewLine('Acerto médio', '$average%'),
          const SizedBox(height: 14),
          Text(
            'Provas incluídas',
            style: TextStyle(
              color: context.colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (exams.isEmpty)
            Text(
              'Nenhuma prova corrigida para esta turma.',
              style: TextStyle(color: context.colors.muted, fontSize: 11),
            )
          else
            for (final exam in exams)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${exam.assessmentTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.text,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      '${exam.averageScore}% · mais errada ${exam.hardestQuestion}',
                      style: TextStyle(
                        color: context.colors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _previewLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(color: context.colors.muted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: context.colors.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    setState(() => _gerando = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final (bytes, nome) = _previewBytes != null && _previewFileName != null
          ? (_previewBytes!, _previewFileName!)
          : await _montarPdf();
      await (widget.compartilharPdf ?? _compartilharComPrinting)(bytes, nome);
      if (!mounted) return;
      setState(() {
        _previewBytes = bytes;
        _previewFileName = nome;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Relatório gerado: $nome')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível gerar o relatório. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  Future<(Uint8List, String)> _montarPdf() async {
    switch (_tipo) {
      case TipoRelatorio.estatisticas:
        final bytes = await RelatorioPdf.estatisticas(
          turma: _selectedClass,
          prova: _selectedExam,
        );
        return (
          bytes,
          RelatorioPdf.nomeArquivo('estatisticas', _selectedClass.displayName),
        );
      case TipoRelatorio.desempenho:
        final desempenho = await RelatorioRepository().desempenhoDaTurma(
          _selectedClass.turmaId,
          avaliacaoId: _selectedExam?.assessmentId,
        );
        final bytes = await RelatorioPdf.desempenhoTurma(
          desempenho,
          provaSelecionada: _selectedExam?.assessmentTitle,
        );
        return (
          bytes,
          RelatorioPdf.nomeArquivo('desempenho', _selectedClass.displayName),
        );
    }
  }

  String _todayLabel() {
    const months = [
      'jan.',
      'fev.',
      'mar.',
      'abr.',
      'mai.',
      'jun.',
      'jul.',
      'ago.',
      'set.',
      'out.',
      'nov.',
      'dez.',
    ];
    final now = DateTime.now();
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: context.colors.text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
