import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/assessment.dart';
import '../services/database/database.dart';
import '../services/random_exam_service.dart';
import '../theme/app_colors.dart';
import 'answer_key_screen.dart';
import 'correction_start_screen.dart';
import 'exam_statistics_screen.dart';

class AssessmentDetailScreen extends StatefulWidget {
  const AssessmentDetailScreen({super.key, required this.assessment});

  final Assessment assessment;

  @override
  State<AssessmentDetailScreen> createState() => _AssessmentDetailScreenState();
}

class _AssessmentDetailScreenState extends State<AssessmentDetailScreen> {
  late Assessment assessment = widget.assessment;
  bool _carregandoEstatisticas = false;

  /// Recarrega após correções ou alterações.
  Future<void> _recarregar() async {
    try {
      final atualizada = await AvaliacaoRepository().buscar(assessment.id);
      if (mounted) setState(() => assessment = atualizada);
    } catch (_) {
      // Mantém os dados já exibidos.
    }
  }

  void _openEditarInformacoes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EditarProvaSheet(
        assessment: assessment,
        onSave: (novoTitulo, novaDisciplina, novaData) async {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(sheetContext);

          try {
            final atualizada = await AvaliacaoRepository().editar(
              id: assessment.id,
              titulo: novoTitulo,
              disciplina: novaDisciplina,
              dataAplicacao: novaData,
            );
            if (!mounted) return;
            setState(() => assessment = atualizada);
            messenger.showSnackBar(
              const SnackBar(content: Text('Informações da prova atualizadas com sucesso')),
            );
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Não foi possível atualizar a avaliação')),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmarExclusao() async {
    if (assessment.status == AssessmentStatus.completed) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Exclusão não permitida'),
          content: const Text(
            'Esta avaliação já foi aplicada e possui notas registradas. Não é possível excluí-la.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      return;
    }

    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir avaliação'),
        content: Text('Deseja realmente excluir a avaliação "${assessment.title}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirma == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await AvaliacaoRepository().excluir(assessment.id);
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Avaliação excluída com sucesso')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Erro ao excluir avaliação: $e')),
        );
      }
    }
  }

  void _gerarProvaRandomicaPdf() {
    final variantes = RandomExamService.gerarVariantes(
      assessment: assessment,
      quantidade: 2,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VisualizarVariantesSheet(variantes: variantes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = assessment.totalStudents == 0
        ? 0.0
        : assessment.correctedStudents / assessment.totalStudents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: 'Detalhes da avaliação',
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle, size: 20, color: AppColors.accent),
            tooltip: 'Gerar PDF randômico',
            onPressed: _gerarProvaRandomicaPdf,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.accent),
            tooltip: 'Editar informações',
            onPressed: _openEditarInformacoes,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
            tooltip: 'Excluir avaliação',
            onPressed: _confirmarExclusao,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessment.title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${assessment.subject} · ${assessment.className}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                StatusBadge.assessment(
                  assessment.status,
                  horizontalPadding: 8,
                  verticalPadding: 5,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          Icons.quiz_outlined,
                          '${assessment.totalQuestions}',
                          'Questões',
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      Expanded(
                        child: _metric(
                          Icons.people_outline,
                          '${assessment.totalStudents}',
                          'Alunos',
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      Expanded(
                        child: _metric(
                          Icons.event_outlined,
                          assessment.dateLabel,
                          'Data',
                          smallValue: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Correções realizadas',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                      Text(
                        '${assessment.correctedStudents} de ${assessment.totalStudents} alunos',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gabarito',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => _openAnswerKey(context),
                  child: const Text(
                    'Editar',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(assessment.gabarito.length, (index) {
                  final answer =
                      assessment.gabarito[index].alternativaCorreta ?? '–';
                  return Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 8,
                          ),
                        ),
                        Text(
                          answer,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Iniciar correção',
              icon: Icons.qr_code_scanner,
              verticalPadding: 14,
              onPressed: () => _iniciarCorrecao(context),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Configurar gabarito',
              icon: Icons.edit_note_outlined,
              verticalPadding: 14,
              onPressed: () => _openAnswerKey(context),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: _carregandoEstatisticas
                  ? 'Carregando...'
                  : 'Ver estatísticas',
              icon: Icons.bar_chart,
              verticalPadding: 14,
              onPressed: _carregandoEstatisticas
                  ? null
                  : () => _openStatistics(context),
            ),
            if (assessment.status != AssessmentStatus.completed) ...[
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Encerrar correção',
                icon: Icons.check_circle_outline,
                verticalPadding: 14,
                borderColor: AppColors.accent,
                onPressed: () => _confirmarEncerramento(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEncerramento(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Encerrar correção?'),
        content: const Text(
          'Ao encerrar, os alunos que não possuem nota registrada receberão nota 0 automaticamente e a avaliação será marcada como concluída.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Encerrar correção'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      final ausentes = await ResultadoRepository().encerrarCorrecao(
        avaliacao: assessment,
      );
      if (!mounted) return;
      await _recarregar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Correção encerrada com sucesso. $ausentes aluno(s) ausente(s) receberam nota 0.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível encerrar a correção')),
      );
    }
  }

  Future<void> _iniciarCorrecao(BuildContext context) async {
    if (!assessment.gabaritoConfigurado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure o gabarito antes de iniciar a correção'),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CorrectionStartScreen(assessment: assessment),
      ),
    );
    _recarregar();
  }

  Future<void> _openStatistics(BuildContext context) async {
    if (assessment.correctedStudents == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corrija ao menos uma prova para ver as estatísticas'),
        ),
      );
      return;
    }

    setState(() => _carregandoEstatisticas = true);
    try {
      final statistics = await EstatisticasRepository().daAvaliacao(assessment);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamStatisticsScreen(statistics: statistics),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar as estatísticas'),
        ),
      );
    } finally {
      if (mounted) setState(() => _carregandoEstatisticas = false);
    }
  }

  Widget _metric(
    IconData icon,
    String value,
    String label, {
    bool smallValue = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.text,
            fontSize: smallValue ? 9 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 9),
        ),
      ],
    );
  }

  Future<void> _openAnswerKey(BuildContext context) async {
    final saved = await Navigator.push<Assessment>(
      context,
      MaterialPageRoute(
        builder: (_) => AnswerKeyScreen(assessment: assessment),
      ),
    );
    if (saved != null && context.mounted) {
      setState(() => assessment = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gabarito salvo com sucesso')),
      );
    }
  }
}

class _EditarProvaSheet extends StatefulWidget {
  const _EditarProvaSheet({
    required this.assessment,
    required this.onSave,
  });

  final Assessment assessment;
  final void Function(String titulo, String disciplina, DateTime data) onSave;

  @override
  State<_EditarProvaSheet> createState() => _EditarProvaSheetState();
}

class _EditarProvaSheetState extends State<_EditarProvaSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  late DateTime _dataAplicacao;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.assessment.title);
    _subjectController = TextEditingController(text: widget.assessment.subject);
    _dataAplicacao = widget.assessment.dataAplicacao ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataAplicacao,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (escolhida != null && mounted) {
      setState(() => _dataAplicacao = escolhida);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const Text(
              'Editar Informações da Prova',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 14),
            LabeledTextField(
              label: 'Título da avaliação',
              controller: _titleController,
              dense: true,
            ),
            const SizedBox(height: 12),
            LabeledTextField(
              label: 'Disciplina',
              controller: _subjectController,
              dense: true,
            ),
            const SizedBox(height: 12),
            const Text(
              'Data de aplicação',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _selecionarData,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AvaliacaoRepository.formatarData(_dataAplicacao),
                      style: const TextStyle(fontSize: 13, color: AppColors.text),
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Salvar alterações',
              verticalPadding: 14,
              fontSize: 13,
              onPressed: () {
                final titulo = _titleController.text.trim();
                final disciplina = _subjectController.text.trim();
                if (titulo.isNotEmpty && disciplina.isNotEmpty) {
                  widget.onSave(titulo, disciplina, _dataAplicacao);
                }
              },
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
    );
  }
}

class _VisualizarVariantesSheet extends StatefulWidget {
  const _VisualizarVariantesSheet({required this.variantes});

  final List<RandomizedExamVariant> variantes;

  @override
  State<_VisualizarVariantesSheet> createState() =>
      _VisualizarVariantesSheetState();
}

class _VisualizarVariantesSheetState extends State<_VisualizarVariantesSheet> {
  int _varianteSelecionada = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.variantes.isEmpty) {
      return const SizedBox();
    }
    final variante = widget.variantes[_varianteSelecionada];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PDF da Prova Randômica',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: widget.variantes.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final ativa = idx == _varianteSelecionada;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(item.variantLabel),
                  selected: ativa,
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: ativa ? Colors.white : AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _varianteSelecionada = idx);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Gabarito desta versão: ${variante.gabaritoResumido}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.input,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: Text(
                  variante.gerarLayoutProvaPdf(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.4,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Exportar / Baixar Prova e Gabarito',
            icon: Icons.picture_as_pdf_outlined,
            verticalPadding: 13,
            fontSize: 13,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${variante.variantLabel} gerada com sucesso para impressão!',
                  ),
                ),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
