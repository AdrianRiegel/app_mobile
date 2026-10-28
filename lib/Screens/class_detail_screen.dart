import 'package:flutter/material.dart';

import '../components/inputs/csv_file_picker.dart';
import '../data/mock_assessments.dart';
import '../models/assessment.dart';
import '../services/csv_import_service.dart';
import '../theme/app_colors.dart';
import 'assessment_detail_screen.dart';
import 'new_proof_screen.dart';
import 'proof_grades_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({super.key, required this.turma});

  final Turma turma;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final _alunoRepository = AlunoRepository();
  final _avaliacaoRepository = AvaliacaoRepository();
  int _tabIndex = 0;

  List<Aluno> _alunos = [];
  List<Assessment> _provas = [];
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
      final (alunos, provas) = await (
        _alunoRepository.listarPorTurma(widget.turma.id),
        _avaliacaoRepository.listar(turmaId: widget.turma.id),
      ).wait;
      if (!mounted) return;
      setState(() {
        _alunos = alunos;
        _provas = provas;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: _tabIndex == 1
            ? 'Provas · ${widget.turma.nome}'
            : widget.turma.descricao,
        showDivider: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.more_vert, size: 18, color: AppColors.muted),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _tab('Alunos', 0),
                  const SizedBox(width: 18),
                  _tab('Provas', 1),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.border),
            Expanded(child: _buildConteudo()),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, int index) {
    final active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.accent : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (_erro) {
      return LoadErrorView(onRetry: _carregar);
    }
    return _tabIndex == 0 ? _buildAlunosTab() : _buildProvasTab();
  }

  Widget _buildAlunosTab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_alunos.length} alunos',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openNovoAlunoSheet,
                        icon: const Icon(
                          Icons.person,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        label: const Text(
                          'Adicionar',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: AppColors.accent,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          fixedSize: const Size(90, 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _openImportarCsvSheet,
                        icon: Icon(
                          Icons.import_export,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        label: const Text(
                          'Importar',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: AppColors.accent,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          fixedSize: const Size(80, 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._alunos.map(
                (aluno) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildAlunoItem(aluno),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: PrimaryButton(
            label: 'Ver provas da turma',
            icon: Icons.assignment_outlined,
            verticalPadding: 13,
            fontSize: 13,
            onPressed: () => setState(() => _tabIndex = 1),
          ),
        ),
      ],
    );
  }

  Widget _buildProvasTab() {
    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: _provas.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _buildProvaItem(_provas[index]),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _createAssessment,
            backgroundColor: AppColors.accent,
            elevation: 4,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildAlunoItem(Aluno aluno) {
    return AppListItemCard(
      leading: _avatar(aluno.nome),
      title: aluno.nome,
      subtitle: Text(
        'Matrícula ${aluno.matricula}',
        style: const TextStyle(fontSize: 11, color: AppColors.muted),
      ),
    );
  }

  Widget _buildProvaItem(_Prova prova) {
    final aplicada = prova.status == 'Aplicada';
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          final assessment =
              prova.assessment ??
              Assessment(
                title: prova.titulo,
                subject: 'Matemática',
                className: widget.titulo.split(' - ').first,
                dateLabel: 'Sem data',
                status: AssessmentStatus.draft,
                totalQuestions: 10,
                correctedStudents: 0,
                totalStudents: _alunos.length,
              );
          if (aplicada) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProofGradesScreen(
                  proofTitle: assessment.title,
                  className: widget.titulo.split(' - ').first,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssessmentDetailScreen(assessment: assessment),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentLightColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prova.titulo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prova.info,
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: aplicada
                      ? const Color(0xFFE4F6ED)
                      : const Color(0xFFEEF0F3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  prova.status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: aplicada ? const Color(0xFF1F9D6E) : mutedColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      title: prova.title,
      subtitle: Text(
        '${prova.totalQuestions} questões · ${prova.dateLabel}',
        style: const TextStyle(fontSize: 11, color: AppColors.muted),
      ),
      trailing: StatusBadge(
        label: aplicada ? 'Aplicada' : prova.statusLabel,
        background: aplicada ? AppColors.successLight : AppColors.neutralLight,
        foreground: aplicada ? AppColors.success : AppColors.muted,
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => aplicada
                ? ProofGradesScreen(assessment: prova)
                : AssessmentDetailScreen(assessment: prova),
          ),
        );
        _carregar();
      },
    );
  }

  Future<void> _createAssessment() async {
    final assessment = await Navigator.push<Assessment>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NewProofScreen(className: widget.titulo.split(' - ').first),
      ),
    );
    if (assessment == null || !mounted) {
      return;
    }

    setState(() => _provas.insert(0, assessment));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avaliação criada como rascunho')),
    );
  }

  Widget _avatar(String nome) {
    final parts = nome.trim().split(' ');
    final initials = parts.length > 1
        ? '${parts.first[0]}${parts.last[0]}'
        : parts.first.substring(0, 1);
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.accentLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
      ),
    );
  }

  void _openNovoAlunoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _NovoAlunoSheet(
        onCreate: (nome, matricula) async {
          final nomeLimpo = nome.trim();
          final matriculaLimpa = matricula.trim();
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(sheetContext);

          if (nomeLimpo.isEmpty || matriculaLimpa.isEmpty) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Preencha nome e matrícula do aluno'),
              ),
            );
            return;
          }

          try {
            final aluno = await _alunoRepository.adicionar(
              turmaId: widget.turma.id,
              nome: nomeLimpo,
              matricula: matriculaLimpa,
            );
            if (!mounted) return;
            setState(() => _alunos.insert(0, aluno));
            messenger.showSnackBar(
              SnackBar(content: Text('Aluno(a) "$nomeLimpo" adicionado(a)')),
            );
          } on MatriculaDuplicadaException catch (e) {
            messenger.showSnackBar(SnackBar(content: Text(e.message)));
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Não foi possível adicionar o aluno'),
              ),
            );
          }
        },
      ),
    );
  }

  void _openImportarCsvSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ImportarCsvSheet(
        onImport: (novos) {
          Navigator.pop(sheetContext);

          final existentes = _alunos.map((aluno) => aluno.matricula).toSet();
          final adicionados = novos
              .map((row) => _Aluno(row.nome, 'Matrícula ${row.matricula}'))
              .where((aluno) => !existentes.contains(aluno.matricula))
              .toList();
          final ignorados = novos.length - adicionados.length;

          setState(() => _alunos.insertAll(0, adicionados));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ignorados == 0
                    ? '${adicionados.length} aluno(s) importado(s)'
                    : '${adicionados.length} aluno(s) importado(s) · '
                          '$ignorados já cadastrado(s)',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImportarCsvSheet extends StatefulWidget {
  const _ImportarCsvSheet({required this.onImport});

  final void Function(List<CsvStudentRow> alunos) onImport;

  @override
  State<_ImportarCsvSheet> createState() => _ImportarCsvSheetState();
}

class _ImportarCsvSheetState extends State<_ImportarCsvSheet> {
  CsvImportResult? _result;

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final canImport = result != null && result.alunos.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: SafeArea(
        top: false,
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
              'Importar alunos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Use um arquivo .csv com as colunas nome e matrícula, '
              'separadas por vírgula ou ponto e vírgula.',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            CsvFilePicker(
              onChanged: (file) => setState(() {
                _result = file == null
                    ? null
                    : CsvImportService.parseStudents(file.content);
              }),
            ),
            if (result != null) ...[
              const SizedBox(height: 12),
              Flexible(child: _buildResumo(result)),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: canImport
                  ? () => widget.onImport(result.alunos)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.muted,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                canImport
                    ? 'Importar ${result.alunos.length} aluno(s)'
                    : 'Importar alunos',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

  Widget _buildResumo(CsvImportResult result) {
    return ListView(
      shrinkWrap: true,
      children: [
        _resumoLinha(
          Icons.check_circle_outline,
          AppColors.success,
          '${result.alunos.length} aluno(s) prontos para importar',
        ),
        if (result.erros.isNotEmpty) ...[
          const SizedBox(height: 6),
          _resumoLinha(
            Icons.warning_amber_rounded,
            AppColors.warning,
            '${result.erros.length} linha(s) ignorada(s)',
          ),
          ...result.erros.map(
            (erro) => Padding(
              padding: const EdgeInsets.only(left: 22, top: 4),
              child: Text(
                erro,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _resumoLinha(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _NovoAlunoSheet extends StatefulWidget {
  const _NovoAlunoSheet({required this.onCreate});

  final void Function(String nome, String matricula) onCreate;

  @override
  State<_NovoAlunoSheet> createState() => _NovoAlunoSheetState();
}

class _NovoAlunoSheetState extends State<_NovoAlunoSheet> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _matriculaController.dispose();
    super.dispose();
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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
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
              'Novo aluno(a)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 14),
            LabeledTextField(
              label: 'Nome',
              controller: _nomeController,
              hintText: 'Ex: João da Silva',
              dense: true,
            ),
            const SizedBox(height: 12),
            LabeledTextField(
              label: 'Matrícula',
              controller: _matriculaController,
              hintText: 'Ex: 2026044',
              dense: true,
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Adicionar aluno',
              verticalPadding: 14,
              fontSize: 13,
              onPressed: () {
                widget.onCreate(
                  _nomeController.text,
                  _matriculaController.text,
                );
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
