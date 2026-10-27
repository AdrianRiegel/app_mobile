import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../components/components.dart';
import '../data/mock_assessments.dart';
import '../models/assessment.dart';
import '../theme/app_colors.dart';
import '../services/proof_qr_payload.dart';
import 'assessment_detail_screen.dart';
import 'new_proof_screen.dart';
import 'proof_grades_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({
    super.key,
    required this.titulo,
    this.classId = 'turma-3a',
    this.initialStudentCount = 12,
  });

  final String titulo;
  final String classId;
  final int initialStudentCount;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final Color cardColor = Colors.white;
  final Color borderColor = AppColors.border;
  final Color textColor = AppColors.text;
  final Color mutedColor = AppColors.muted;
  final Color accentColor = AppColors.accent;
  final Color accentLightColor = AppColors.accentLight;
  int _tabIndex = 0;
  int _studentPage = 1;
  static const int _studentPageSize = 5;

  List<_Aluno> get _visibleStudents => _alunos.skip((_studentPage - 1) * _studentPageSize).take(_studentPageSize).toList();
  int get _studentPageCount => (_alunos.length / _studentPageSize).ceil().clamp(1, 999999).toInt();

  final List<_Aluno> _alunos = [];

  static const _sampleStudents = [
    'Ana Beatriz', 'Carlos Dias', 'Elisa Ferreira', 'João da Silva',
    'Mariana Costa', 'Lucas Mendes', 'Julia Santos', 'Rafael Souza',
    'Sofia Lima', 'Thiago Gomes', 'Beatriz Alves', 'Pedro Henrique',
  ];

  @override
  void initState() {
    super.initState();
    _provas = mockAssessments
        .where((assessment) => assessment.classId == widget.classId)
        .map(
          (assessment) => _Prova(
            assessment.title,
            '${assessment.totalQuestions} questões · ${assessment.dateLabel}',
            assessment.status == AssessmentStatus.completed
                ? 'Aplicada'
                : assessment.statusLabel,
            assessment: assessment,
          ),
        )
        .toList();
    for (var index = 0; index < widget.initialStudentCount; index++) {
      final number = 2026041 + index;
      final name = index < _sampleStudents.length ? _sampleStudents[index] : 'Aluno ${index + 1}';
      _alunos.add(_Aluno('aluno-$number', name, 'Matrícula $number'));
    }
  }

  late final List<_Prova> _provas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: _tabIndex == 1
            ? 'Provas · ${widget.titulo.split(' - ').first}'
            : widget.titulo,
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
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity < -250 && _tabIndex == 0) setState(() => _tabIndex = 1);
                  if (velocity > 250 && _tabIndex == 1) setState(() => _tabIndex = 0);
                },
                child: _tabIndex == 0 ? _buildAlunosTab() : _buildProvasTab(),
              ),
            ),
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
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openNovoAlunoSheet,
                        icon: const Icon(Icons.person, size: 16, color: AppColors.accent),
                        label: const Text(
                          'Adicionar',
                          style: TextStyle(fontSize: 12.0, color: AppColors.accent),
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
                        onPressed: () => {},
                        icon: const Icon(
                          Icons.import_export,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        label: const Text(
                          'Importar',
                          style: TextStyle(fontSize: 12.0, color: AppColors.accent),
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
              ..._visibleStudents.map(_buildAlunoItem),
              if (_studentPageCount > 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: _studentPage > 1 ? () => setState(() => _studentPage--) : null, child: const Text('‹ Anterior')),
                    Text('Página $_studentPage de $_studentPageCount', style: TextStyle(fontSize: 11, color: mutedColor)),
                    TextButton(onPressed: _studentPage < _studentPageCount ? () => setState(() => _studentPage++) : null, child: const Text('Próxima ›')),
                  ],
                ),
              ],
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

  Widget _buildAlunoItem(_Aluno aluno) {
    return AppListItemCard(
      leading: _avatar(aluno.nome),
      title: aluno.nome,
      subtitle: Text(
        aluno.matricula,
        style: const TextStyle(fontSize: 11, color: AppColors.muted),
      ),
    );
  }

  Widget _buildProvaItem(_Prova prova) {
    final aplicada = prova.status == 'Aplicada';
    final assessment = prova.assessment ?? Assessment(
      id: 'prova-${prova.titulo.hashCode.abs()}',
      classId: widget.classId,
      title: prova.titulo,
      subject: 'Matemática',
      className: widget.titulo.split(' - ').first,
      dateLabel: 'Sem data',
      status: AssessmentStatus.draft,
      totalQuestions: 10,
      correctedStudents: 0,
      totalStudents: _alunos.length,
    );
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
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
              IconButton(
                tooltip: 'Gerar QR Code por aluno',
                onPressed: () => _showStudentQr(assessment),
                icon: Icon(Icons.qr_code_2, size: 21, color: accentColor),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentQr(Assessment assessment) {
    if (_alunos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastre ao menos um aluno para gerar o QR Code')));
      return;
    }
    var selectedStudentId = _alunos.first.id;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final student = _alunos.firstWhere((item) => item.id == selectedStudentId);
          final payload = ProofQrPayload(
            classId: widget.classId,
            proofId: assessment.id,
            studentId: student.id,
          ).encode();
          return AlertDialog(
            title: const Text('QR Code individual'),
            content: SizedBox(
              width: 280,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedStudentId,
                  items: _alunos.map((item) => DropdownMenuItem(value: item.id, child: Text(item.nome))).toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedStudentId = value);
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 210,
                  height: 210,
                  child: QrImageView(data: payload, size: 210, backgroundColor: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Turma ${widget.classId} · Prova ${assessment.id} · Aluno ${student.id}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fechar'))],
          );
        },
      ),
    );
  }

  Future<void> _createAssessment() async {
    final assessment = await Navigator.push<Assessment>(
      context,
      MaterialPageRoute(
        builder: (_) => NewProofScreen(
          className: widget.titulo.split(' - ').first,
          classId: widget.classId,
        ),
      ),
    );
    if (assessment == null || !mounted) {
      return;
    }

    setState(() {
      _provas.insert(
        0,
        _Prova(
          assessment.title,
          '${assessment.totalQuestions} questões',
          'Rascunho',
          assessment: assessment,
        ),
      );
    });
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
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _NovoAlunoSheet(
        onCreate: (nome, matricula) {
          final nomeLimpo = nome.trim();
          final matriculaLimpa = matricula.trim();

          if (nomeLimpo.isEmpty || matriculaLimpa.isEmpty) {
            Navigator.pop(sheetContext);
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Preencha nome e matrícula do aluno'),
              ),
            );
            return;
          }

          if (_alunos.any((aluno) => aluno.id == 'aluno-$matriculaLimpa')) {
            Navigator.pop(sheetContext);
            messenger.showSnackBar(
              const SnackBar(content: Text('Já existe um aluno com essa matrícula')),
            );
            return;
          }

          Navigator.pop(sheetContext);
          setState(() {
            _alunos.insert(0, _Aluno('aluno-$matriculaLimpa', nomeLimpo, 'Matrícula $matriculaLimpa'));
            _studentPage = 1;
          });
          messenger.showSnackBar(
            SnackBar(content: Text('Aluno(a) "$nomeLimpo" adicionado(a)')),
          );
        },
      ),
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

class _Aluno {
  final String id;
  final String nome;
  final String matricula;
  const _Aluno(this.id, this.nome, this.matricula);
}

class _Prova {
  final String titulo;
  final String info;
  final String status;
  final Assessment? assessment;

  const _Prova(this.titulo, this.info, this.status, {this.assessment});
}
