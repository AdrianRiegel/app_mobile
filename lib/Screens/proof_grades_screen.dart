import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/aluno.dart';
import '../models/assessment.dart';
import '../models/resultado.dart';
import '../models/usuario.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';

class ProofGradesScreen extends StatefulWidget {
  const ProofGradesScreen({super.key, required this.assessment});

  final Assessment assessment;

  @override
  State<ProofGradesScreen> createState() => _ProofGradesScreenState();
}

class _ProofGradesScreenState extends State<ProofGradesScreen> {
  List<(Aluno, Resultado)> _notas = [];
  bool _carregando = true;
  bool _erro = false;

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
      final (alunos, resultados) = await (
        AlunoRepository().listarPorTurma(widget.assessment.turmaId),
        ResultadoRepository().listarPorAvaliacao(widget.assessment.id),
      ).wait;
      final resultadoPorAluno = {
        for (final resultado in resultados) resultado.alunoId: resultado,
      };
      if (!mounted) return;
      setState(() {
        _notas = [
          for (final aluno in alunos)
            if (resultadoPorAluno[aluno.id] case final resultado?)
              (aluno, resultado),
        ];
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = true;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final proofTitle = widget.assessment.title;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: 'Notas · ${proofTitle.replaceFirst('Avaliação ', '')}',
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _erro
          ? LoadErrorView(onRetry: _carregar)
          : _buildNotas(),
    );
  }

  Widget _buildNotas() {
    final media = _notas.isEmpty
        ? 0.0
        : _notas.fold<double>(0, (soma, nota) => soma + nota.$2.notaCalculada) /
              _notas.length;
    final proofTitle = widget.assessment.title;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: StatSummaryCard(
                label: 'Média da turma',
                value: media.toStringAsFixed(1),
                showBorder: false,
                valueFontSize: 24,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatSummaryCard(
                label: 'Aplicadas',
                value: '${_notas.length}/${widget.assessment.totalStudents}',
                showBorder: false,
                valueFontSize: 24,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '${widget.assessment.className} · $proofTitle',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ..._notas.map(
          (nota) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _studentCard(
              name: nota.$1.nome,
              initials: iniciaisDoNome(nota.$1.nome),
              grade: nota.$2.notaCalculada.toStringAsFixed(1),
              detail:
                  '${nota.$2.totalAcertos} acertos de ${nota.$2.respostas.length}',
              passing: nota.$2.aprovado,
            ),
          ),
        ),
      ],
    );
  }

  Widget _studentCard({
    required String name,
    required String initials,
    required String grade,
    required String detail,
    required bool passing,
  }) {
    return AppListItemCard(
      leading: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppColors.accentLight,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: name,
      titleFontSize: 14,
      subtitle: Text(
        detail,
        style: const TextStyle(color: AppColors.muted, fontSize: 11),
      ),
      trailing: StatusBadge(
        label: grade,
        background: passing ? AppColors.successLight : AppColors.neutralLight,
        foreground: passing ? AppColors.success : AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        horizontalPadding: 9,
        verticalPadding: 5,
        borderRadius: 18,
      ),
    );
  }
}
