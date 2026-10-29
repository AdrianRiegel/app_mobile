import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/assessment.dart';
import '../services/database/database.dart';
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

  /// Recarrega após correções, que mudam o progresso e o status.
  Future<void> _recarregar() async {
    try {
      final atualizada = await AvaliacaoRepository().buscar(assessment.id);
      if (mounted) setState(() => assessment = atualizada);
    } catch (_) {
      // Mantém os dados já exibidos.
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = assessment.totalStudents == 0
        ? 0.0
        : assessment.correctedStudents / assessment.totalStudents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const StandardAppBar(title: 'Detalhes da avaliação'),
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
                StatusBadge(
                  label: assessment.statusLabel,
                  background: assessment.status.badgeBackground,
                  foreground: assessment.status.badgeForeground,
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
                        '${assessment.correctedStudents}/${assessment.totalStudents}',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.accentLight,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
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
