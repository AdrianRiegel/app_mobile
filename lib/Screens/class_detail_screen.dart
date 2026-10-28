import 'package:flutter/material.dart';

import '../components/components.dart';
import '../components/inputs/csv_file_picker.dart';
import '../models/aluno.dart';
import '../models/assessment.dart';
import '../models/turma.dart';
import '../services/csv_import_service.dart';
import '../services/database/database.dart';
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
                        icon: const Icon(
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

  Widget _buildProvaItem(Assessment prova) {
    final aplicada = prova.status == AssessmentStatus.completed;
    return AppListItemCard(
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(
          Icons.description_outlined,
          size: 18,
          color: AppColors.accent,
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
    final criada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NewProofScreen(turma: widget.turma),
      ),
    );
    if (criada == true && mounted) {
      _carregar();
    }
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
        onImport: (novos) async {
          Navigator.pop(sheetContext);

          final existentes = _alunos.map((aluno) => aluno.matricula).toSet();
          int importados = 0;
          int duplicados = 0;

          for (final row in novos) {
            if (existentes.contains(row.matricula)) {
              duplicados++;
              continue;
            }
            try {
              final aluno = await _alunoRepository.adicionar(
                turmaId: widget.turma.id,
                nome: row.nome,
                matricula: row.matricula,
              );
              if (!mounted) return;
              setState(() => _alunos.insert(0, aluno));
              existentes.add(aluno.matricula);
              importados++;
            } catch (_) {
              duplicados++;
            }
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                duplicados == 0
                    ? '$importados aluno(s) importado(s)'
                    : '$importados aluno(s) importado(s) · '
                        '$duplicados já cadastrado(s) ou ignorado(s)',
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
