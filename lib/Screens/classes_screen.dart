import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/turma.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';
import 'assessments_screen.dart';
import 'class_detail_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  static const _turmasPorPagina = 8;

  final _repository = TurmaRepository();
  int _selectedIndex = 1;
  int _currentPage = 1;
  String _busca = '';

  List<Turma> _turmas = [];
  bool _carregando = true;
  bool _erro = false;

  List<Turma> get _turmasFiltradas {
    final termo = _busca.trim().toLowerCase();
    if (termo.isEmpty) return _turmas;
    return _turmas
        .where((turma) => turma.descricao.toLowerCase().contains(termo))
        .toList();
  }

  int get _totalPages =>
      (_turmasFiltradas.length / _turmasPorPagina).ceil().clamp(1, 999);

  List<Turma> get _turmasDaPagina => _turmasFiltradas
      .skip((_currentPage - 1) * _turmasPorPagina)
      .take(_turmasPorPagina)
      .toList();

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
      final turmas = await _repository.listar();
      if (!mounted) return;
      setState(() {
        _turmas = turmas;
        _currentPage = _currentPage.clamp(1, _totalPages);
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
      backgroundColor: context.colors.background,
      floatingActionButtonLocation: const CustomMiniEndFloatLocation(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Text(
                    'Turmas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.colors.text,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    SearchField(
                      hintText: 'Buscar turma por nome',
                      onChanged: (value) => setState(() {
                        _busca = value;
                        _currentPage = 1;
                      }),
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _buildLista()),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _pageButton(
                          '‹ Anterior',
                          enabled: _currentPage > 1,
                          onTap: () => setState(() => _currentPage--),
                        ),
                        Text(
                          'Página $_currentPage de $_totalPages',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.muted,
                          ),
                        ),
                        _pageButton(
                          'Próxima ›',
                          enabled: _currentPage < _totalPages,
                          onTap: () => setState(() => _currentPage++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNovaTurmaSheet(),
        backgroundColor: context.colors.accent,
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
            return;
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AssessmentsScreen(),
              ),
            );
            return;
          }
          if (index == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Perfil estará disponível em uma próxima entrega',
                ),
              ),
            );
            return;
          }
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  Widget _buildLista() {
    if (_carregando) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.accent),
      );
    }
    if (_erro) {
      return LoadErrorView(onRetry: _carregar);
    }
    final turmas = _turmasDaPagina;
    if (turmas.isEmpty) {
      return EmptyStateView(
        icon: Icons.people_outline,
        iconBackground: context.colors.accentLight,
        iconColor: context.colors.accent,
        title: _turmas.isEmpty
            ? 'Nenhuma turma cadastrada'
            : 'Nenhuma turma encontrada',
        message: _turmas.isEmpty
            ? 'Toque em + para criar a primeira turma.'
            : 'Tente buscar por outro nome.',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: turmas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildTurmaItem(turmas[index]),
    );
  }

  Widget _buildTurmaItem(Turma turma) {
    return AppListItemCard(
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: context.colors.accentLight,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          Icons.people_outline,
          size: 18,
          color: context.colors.accent,
        ),
      ),
      title: turma.descricao,
      trailing: PopupMenuButton<String>(
        tooltip: 'Ações da turma',
        onSelected: (value) {
          if (value == 'editar') {
            _openNovaTurmaSheet(turma: turma);
          } else {
            _excluirTurma(turma);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'editar', child: Text('Editar turma')),
          PopupMenuItem(value: 'excluir', child: Text('Excluir turma')),
        ],
      ),
      subtitle: Text(
        turma.resumo,
        style: TextStyle(fontSize: 11, color: context.colors.muted),
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassDetailScreen(turma: turma),
          ),
        );
        // O total de alunos pode ter mudado dentro da turma.
        _carregar();
      },
    );
  }

  Widget _pageButton(
    String label, {
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: enabled
              ? context.colors.accent
              : context.colors.muted.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Future<void> _excluirTurma(Turma turma) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir turma'),
        content: Text(
          'Excluir "${turma.descricao}" e seus alunos e rascunhos? Turmas com provas aplicadas não podem ser excluídas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    try {
      await _repository.excluir(turma.id);
      if (!mounted) return;
      _carregar();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is TurmaComProvaAplicadaException
                ? error.toString()
                : 'Não foi possível excluir a turma',
          ),
        ),
      );
    }
  }

  void _openNovaTurmaSheet({Turma? turma}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _NovaTurmaSheet(
        turma: turma,
        onCreate: (descricao, semestre, ano) async {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(sheetContext);
          try {
            if (turma == null) {
              await _repository.criar(
                descricao: descricao,
                semestre: semestre,
                ano: ano,
              );
            } else {
              await _repository.editar(
                id: turma.id,
                descricao: descricao,
                semestre: semestre,
                ano: ano,
              );
            }
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  'Turma "$descricao" ${turma == null ? "criada" : "atualizada"}',
                ),
              ),
            );
            _carregar();
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Não foi possível criar a turma')),
            );
          }
        },
      ),
    );
  }
}

class CustomMiniEndFloatLocation extends FloatingActionButtonLocation {
  const CustomMiniEndFloatLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final Offset standardOffset = FloatingActionButtonLocation.miniEndFloat
        .getOffset(scaffoldGeometry);

    double dxAdjustment = -10.0;
    double dyAdjustment = -30.0;

    return Offset(
      standardOffset.dx + dxAdjustment,
      standardOffset.dy + dyAdjustment,
    );
  }
}

class _NovaTurmaSheet extends StatefulWidget {
  const _NovaTurmaSheet({required this.onCreate, this.turma});

  final Turma? turma;

  final void Function(String descricao, int semestre, int ano) onCreate;

  @override
  State<_NovaTurmaSheet> createState() => _NovaTurmaSheetState();
}

class _NovaTurmaSheetState extends State<_NovaTurmaSheet> {
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _semestreController = TextEditingController(
    text: '1º semestre',
  );
  final TextEditingController _anoController = TextEditingController(
    text: '${DateTime.now().year}',
  );

  @override
  void initState() {
    super.initState();
    final turma = widget.turma;
    if (turma != null) {
      _descricaoController.text = turma.descricao;
      _semestreController.text = '${turma.semestre}º semestre';
      _anoController.text = '${turma.ano}';
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _semestreController.dispose();
    _anoController.dispose();
    super.dispose();
  }

  void _criar() {
    final descricao = _descricaoController.text.trim();
    // Aceita "1º semestre", "1" etc.: usa apenas os dígitos.
    final semestre = int.tryParse(
      _semestreController.text.replaceAll(RegExp(r'\D'), ''),
    );
    final ano = int.tryParse(_anoController.text.trim());

    final String? erro;
    if (descricao.isEmpty) {
      erro = 'Informe a descrição da turma';
    } else if (semestre == null || semestre < 1 || semestre > 2) {
      erro = 'Informe o semestre (1 ou 2)';
    } else if (ano == null || ano < 2000 || ano > 2100) {
      erro = 'Informe um ano válido';
    } else {
      erro = null;
    }

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
      return;
    }
    widget.onCreate(descricao, semestre!, ano!);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
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
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Text(
              widget.turma == null ? 'Nova turma' : 'Editar turma',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.colors.text,
              ),
            ),
            const SizedBox(height: 14),
            LabeledTextField(
              label: 'Descrição',
              controller: _descricaoController,
              hintText: 'Ex: 3º Ano A - Matemática',
              dense: true,
            ),
            const SizedBox(height: 12),
            LabeledTextField(
              label: 'Semestre',
              controller: _semestreController,
              dense: true,
            ),
            const SizedBox(height: 12),
            LabeledTextField(
              label: 'Ano',
              controller: _anoController,
              keyboardType: TextInputType.number,
              dense: true,
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: widget.turma == null ? 'Criar turma' : 'Salvar alterações',
              verticalPadding: 14,
              fontSize: 13,
              onPressed: _criar,
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
                    color: context.colors.accent,
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
