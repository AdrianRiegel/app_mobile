import 'package:flutter/material.dart';

import '../components/components.dart';
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
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                children: [
                  _tabButton('Alunos', 0),
                  const SizedBox(width: 8),
                  _tabButton('Provas', 1),
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

  Widget _tabButton(String label, int index) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? AppColors.border : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
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
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openNovoAlunoSheet,
                        icon: const Icon(
                          Icons.person_add_alt,
                          size: 15,
                          color: AppColors.accent,
                        ),
                        label: const Text(
                          'Adicionar',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: _openImportarCsvSheet,
                        icon: const Icon(
                          Icons.file_upload_outlined,
                          size: 15,
                          color: AppColors.accent,
                        ),
                        label: const Text(
                          'Importar CSV',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_alunos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(
                    child: Text(
                      'Nenhum aluno cadastrado nesta turma',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
                )
              else
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
        if (_provas.isEmpty)
          const Center(
            child: Text(
              'Nenhuma avaliação cadastrada para esta turma',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          )
        else
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
            tooltip: 'Editar aluno',
            onPressed: () => _openEditarAlunoSheet(aluno),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
            tooltip: 'Excluir aluno',
            onPressed: () => _confirmarExclusaoAluno(aluno),
          ),
        ],
      ),
    );
  }

  Widget _buildProvaItem(Assessment prova) {
    final concluida = prova.isCompleted;
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
      trailing: StatusBadge.assessment(prova.status),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => concluida
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
      MaterialPageRoute(builder: (_) => NewProofScreen(turma: widget.turma)),
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
      builder: (sheetContext) => _AlunoFormSheet(
        titulo: 'Novo aluno(a)',
        botaoTexto: 'Adicionar aluno',
        onSubmit: (nome, matricula) async {
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

  void _openEditarAlunoSheet(Aluno aluno) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AlunoFormSheet(
        titulo: 'Editar aluno(a)',
        botaoTexto: 'Salvar alterações',
        nomeInicial: aluno.nome,
        matriculaInicial: aluno.matricula,
        onSubmit: (nome, matricula) async {
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
            final atualizado = await _alunoRepository.editar(
              id: aluno.id,
              turmaId: widget.turma.id,
              nome: nomeLimpo,
              matricula: matriculaLimpa,
            );
            if (!mounted) return;
            setState(() {
              final idx = _alunos.indexWhere((a) => a.id == aluno.id);
              if (idx != -1) _alunos[idx] = atualizado;
            });
            messenger.showSnackBar(
              SnackBar(content: Text('Aluno(a) "$nomeLimpo" atualizado(a)')),
            );
          } on MatriculaDuplicadaException catch (e) {
            messenger.showSnackBar(SnackBar(content: Text(e.message)));
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Não foi possível editar o aluno')),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmarExclusaoAluno(Aluno aluno) async {
    final temProva = await _alunoRepository.turmaTemProvaAplicada(widget.turma.id);
    if (!mounted) return;

    if (temProva) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Exclusão não permitida'),
          content: const Text(
            'Não é possível excluir o aluno pois a turma já possui prova aplicada.',
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
        title: const Text('Excluir aluno'),
        content: Text('Deseja realmente excluir o aluno "${aluno.nome}"?'),
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
        await _alunoRepository.excluir(
          alunoId: aluno.id,
          turmaId: widget.turma.id,
        );
        if (!mounted) return;
        setState(() => _alunos.removeWhere((a) => a.id == aluno.id));
        messenger.showSnackBar(
          SnackBar(content: Text('Aluno "${aluno.nome}" removido')),
        );
      } on AlunoComProvaAplicadaException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      } catch (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir o aluno')),
        );
      }
    }
  }

  void _openImportarCsvSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ImportarAlunosCsvSheet(
        onImport: (conteudoCsv) async {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(sheetContext);

          final resultado = CsvImportService.parseStudents(conteudoCsv);
          if (!resultado.temAlunos) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  resultado.erros.isNotEmpty
                      ? resultado.erros.first
                      : 'Nenhum aluno identificado no texto CSV informado',
                ),
              ),
            );
            return;
          }

          try {
            final adicionados = await _alunoRepository.importarAlunos(
              turmaId: widget.turma.id,
              novosAlunos: [
                for (final row in resultado.alunos)
                  (nome: row.nome, matricula: row.matricula),
              ],
            );
            if (!mounted) return;
            _carregar();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  '$adicionados alunos importados com sucesso!'
                  '${resultado.erros.isNotEmpty ? ' (${resultado.erros.length} erros)' : ''}',
                ),
              ),
            );
          } catch (_) {
            if (!mounted) return;
            messenger.showSnackBar(
              const SnackBar(content: Text('Erro ao importar alunos do CSV')),
            );
          }
        },
      ),
    );
  }
}

class _AlunoFormSheet extends StatefulWidget {
  const _AlunoFormSheet({
    required this.titulo,
    required this.botaoTexto,
    required this.onSubmit,
    this.nomeInicial = '',
    this.matriculaInicial = '',
  });

  final String titulo;
  final String botaoTexto;
  final String nomeInicial;
  final String matriculaInicial;
  final void Function(String nome, String matricula) onSubmit;

  @override
  State<_AlunoFormSheet> createState() => _AlunoFormSheetState();
}

class _AlunoFormSheetState extends State<_AlunoFormSheet> {
  late final TextEditingController _nomeController;
  late final TextEditingController _matriculaController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.nomeInicial);
    _matriculaController = TextEditingController(text: widget.matriculaInicial);
  }

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
            Text(
              widget.titulo,
              style: const TextStyle(
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
              label: widget.botaoTexto,
              verticalPadding: 14,
              fontSize: 13,
              onPressed: () {
                widget.onSubmit(
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

class _ImportarAlunosCsvSheet extends StatefulWidget {
  const _ImportarAlunosCsvSheet({required this.onImport});

  final void Function(String conteudoCsv) onImport;

  @override
  State<_ImportarAlunosCsvSheet> createState() => _ImportarAlunosCsvSheetState();
}

class _ImportarAlunosCsvSheetState extends State<_ImportarAlunosCsvSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
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
              'Importar Alunos via Planilha (CSV)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cole o conteúdo CSV com as colunas "nome" e "matricula" (separadas por vírgula ou ponto-e-vírgula):',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 6,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: "nome,matricula\nLucas Pereira,2026101\nFernanda Lima,2026102",
                hintStyle: const TextStyle(color: AppColors.muted, fontSize: 11),
                filled: true,
                fillColor: AppColors.input,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Processar e Importar',
              verticalPadding: 14,
              fontSize: 13,
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  widget.onImport(_controller.text);
                }
              },
            ),
            const SizedBox(height: 8),
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
