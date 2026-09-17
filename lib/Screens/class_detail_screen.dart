import 'package:flutter/material.dart';

import '../data/mock_assessments.dart';
import '../models/assessment.dart';
import 'assessment_detail_screen.dart';
import 'new_proof_screen.dart';
import 'proof_grades_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({super.key, required this.titulo});

  final String titulo;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final Color bgColor = const Color(0xFFF0F1F4);
  final Color cardColor = const Color(0xFFFFFFFF);
  final Color borderColor = const Color(0xFFE2E4E9);
  final Color textColor = const Color(0xFF1B1D22);
  final Color mutedColor = const Color(0xFF6B7078);
  final Color accentColor = const Color(0xFF4F5BD5);
  final Color accentLightColor = const Color(0xFFECEEFB);
  final Color backIconBg = const Color(0xFFF2F3F5);
  final Color inputBgColor = const Color(0xFFF8F8F9);

  int _tabIndex = 0;

  final List<_Aluno> _alunos = [
    _Aluno('Ana Beatriz', 'Matrícula 2026041'),
    _Aluno('Carlos Dias', 'Matrícula 2026042'),
    _Aluno('Elisa Ferreira', 'Matrícula 2026043'),
  ];

  final List<_Prova> _provas = mockAssessments
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: backIconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_back, size: 16, color: textColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _tabIndex == 1
                          ? 'Provas · ${widget.titulo.split(' - ').first}'
                          : widget.titulo,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.more_vert, size: 18, color: mutedColor),
                ],
              ),
            ),
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
            Container(height: 1, color: borderColor),
            Expanded(
              child: _tabIndex == 0 ? _buildAlunosTab() : _buildProvasTab(),
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
                color: active ? accentColor : Colors.transparent,
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
              color: active ? accentColor : mutedColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlunosTab() {
    final Color accentColor = const Color(0xFF4F5BD5);
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
                    style: TextStyle(fontSize: 11, color: mutedColor),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openNovoAlunoSheet,
                        icon: Icon(Icons.person, size: 16, color: accentColor),
                        label: Text(
                          'Adicionar',
                          style: TextStyle(fontSize: 12.0, color: accentColor),
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
                        icon: Icon(
                          Icons.import_export,
                          size: 16,
                          color: accentColor,
                        ),
                        label: Text(
                          'Importar',
                          style: TextStyle(fontSize: 12.0, color: accentColor),
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
              ..._alunos.map(_buildAlunoItem),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _tabIndex = 1),
              icon: const Icon(Icons.assignment_outlined, size: 16),
              label: const Text(
                'Ver provas da turma',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
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
            backgroundColor: accentColor,
            elevation: 4,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildAlunoItem(_Aluno aluno) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _avatar(aluno.nome),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aluno.nome,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  aluno.matricula,
                  style: TextStyle(fontSize: 11, color: mutedColor),
                ),
              ],
            ),
          ),
        ],
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
    );
  }

  Future<void> _createAssessment() async {
    final assessment = await Navigator.push<Assessment>(
      context,
      MaterialPageRoute(
        builder: (_) => NewProofScreen(
          className: widget.titulo.split(' - ').first,
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
      decoration: BoxDecoration(
        color: accentLightColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accentColor,
        ),
      ),
    );
  }

  void _openNovoAlunoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NovoAlunoSheet(
        accentColor: accentColor,
        borderColor: borderColor,
        textColor: textColor,
        mutedColor: mutedColor,
        inputBgColor: inputBgColor,
        onCreate: (nome, matricula) {
          final nomeLimpo = nome.trim();
          final matriculaLimpa = matricula.trim();

          if (nomeLimpo.isEmpty || matriculaLimpa.isEmpty) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Preencha nome e matrícula do aluno'),
              ),
            );
            return;
          }

          Navigator.pop(context);
          setState(() {
            _alunos.insert(0, _Aluno(nomeLimpo, 'Matrícula $matriculaLimpa'));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Aluno(a) "$nomeLimpo" adicionado(a)')),
          );
        },
      ),
    );
  }
}

class _NovoAlunoSheet extends StatefulWidget {
  const _NovoAlunoSheet({
    required this.accentColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.inputBgColor,
    required this.onCreate,
  });

  final Color accentColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final Color inputBgColor;
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
                  color: widget.borderColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Text(
              'Novo aluno(a)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: widget.textColor,
              ),
            ),
            const SizedBox(height: 14),
            _label('Nome'),
            _field(_nomeController, hint: 'Ex: João da Silva'),
            const SizedBox(height: 12),
            _label('Matrícula'),
            _field(_matriculaController, hint: 'Ex: 2026044'),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                widget.onCreate(
                  _nomeController.text,
                  _matriculaController.text,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Adicionar aluno',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
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
                    color: widget.accentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: widget.mutedColor,
      ),
    ),
  );

  Widget _field(
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13, color: widget.textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: widget.mutedColor.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: widget.inputBgColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: widget.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: widget.accentColor, width: 1.5),
        ),
      ),
    );
  }
}

class _Aluno {
  final String nome;
  final String matricula;
  const _Aluno(this.nome, this.matricula);
}

class _Prova {
  final String titulo;
  final String info;
  final String status;
  final Assessment? assessment;

  const _Prova(this.titulo, this.info, this.status, {this.assessment});
}
