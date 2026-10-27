import 'package:flutter/material.dart';

import '../components/components.dart';
import '../theme/app_colors.dart';
import 'assessments_screen.dart';
import 'class_detail_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final Color cardColor = Colors.white;
  final Color borderColor = AppColors.border;
  final Color textColor = AppColors.text;
  final Color mutedColor = AppColors.muted;
  final Color accentColor = AppColors.accent;
  final Color accentLightColor = AppColors.accentLight;
  final Color inputBgColor = const Color(0xFFFAFAFB);
  int _selectedIndex = 1;
  int _currentPage = 1;
  static const int _pageSize = 5;
  final TextEditingController _searchController = TextEditingController();

  final List<_Turma> _turmas = [
    _Turma('turma-3a', '3º Ano A - Matemática', '2026', '1º semestre', 28, false),
    _Turma('turma-2b', '2º Ano B - Física', '2026', '1º semestre', 24, true),
    _Turma('turma-1c', '1º Ano C - Química', '2026', '1º semestre', 31, false),
    _Turma('turma-8a', '8º Ano A - Ciências', '2026', '1º semestre', 26, false),
    _Turma('turma-9b', '9º Ano B - História', '2026', '1º semestre', 22, false),
    _Turma('turma-7c', '7º Ano C - Geografia', '2026', '1º semestre', 25, false),
    _Turma('turma-2a', '2º Ano A - Física', '2026', '2º semestre', 27, false),
    _Turma('turma-3b', '3º Ano B - Matemática', '2026', '2º semestre', 29, false),
    _Turma('turma-1a', '1º Ano A - Química', '2026', '2º semestre', 30, false),
    _Turma('turma-6a', '6º Ano A - Ciências', '2026', '2º semestre', 21, false),
    _Turma('turma-5b', '5º Ano B - Português', '2026', '2º semestre', 23, false),
    _Turma('turma-4c', '4º Ano C - Matemática', '2026', '2º semestre', 20, false),
  ];

  List<_Turma> get _filteredClasses {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _turmas;
    return _turmas
        .where((turma) => turma.titulo.toLowerCase().contains(query))
        .toList();
  }

  int get _totalPages => (_filteredClasses.length / _pageSize).ceil().clamp(1, 999999).toInt();

  List<_Turma> get _visibleClasses {
    final start = (_currentPage - 1) * _pageSize;
    return _filteredClasses.skip(start).take(_pageSize).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: const CustomMiniEndFloatLocation(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(Icons.arrow_back, size: 20, color: AppColors.text),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    'Turmas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: inputBgColor,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 18, color: mutedColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() => _currentPage = 1),
                              style: TextStyle(fontSize: 13, color: textColor),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Buscar turma por nome',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: mutedColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          if (velocity < -250 && _currentPage < _totalPages) {
                            setState(() => _currentPage++);
                          } else if (velocity > 250 && _currentPage > 1) {
                            setState(() => _currentPage--);
                          }
                        },
                        child: _visibleClasses.isEmpty
                            ? Center(
                                child: Text(
                                  'Nenhuma turma encontrada',
                                  style: TextStyle(color: mutedColor),
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: _visibleClasses.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (context, index) =>
                                    _buildTurmaItem(_visibleClasses[index]),
                              ),
                      ),
                    ),
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
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
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
        onPressed: _openNovaTurmaSheet,
        backgroundColor: AppColors.accent,
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

  Widget _buildTurmaItem(_Turma turma) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassDetailScreen(
                titulo: turma.titulo,
                classId: turma.id,
                initialStudentCount: turma.studentCount,
              ),
            ),
          );
        },
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
                child: Icon(Icons.people_outline, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      turma.titulo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      turma.subtitulo,
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Ações da turma',
                onSelected: (action) {
                  if (action == 'edit') _openEditClassSheet(turma);
                  if (action == 'delete') _deleteClass(turma);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar turma'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: !turma.hasAppliedAssessments,
                    child: Text(
                      turma.hasAppliedAssessments
                          ? 'Excluir (há provas aplicadas)'
                          : 'Excluir turma',
                    ),
                  ),
                ],
                child: Icon(Icons.more_vert, size: 18, color: mutedColor),
              ),
            ],
          ),
        ),
      ),
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
          color: enabled ? AppColors.accent : AppColors.muted.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  void _openNovaTurmaSheet() {
    _openClassSheet();
  }

  void _openEditClassSheet(_Turma turma) {
    _openClassSheet(turma: turma);
  }

  void _openClassSheet({_Turma? turma}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _NovaTurmaSheet(
        initialClass: turma,
        onSave: (descricao, ano, semestre) {
          Navigator.pop(sheetContext);
          setState(() {
            if (turma == null) {
              _turmas.add(
                _Turma(
                  'turma-${DateTime.now().microsecondsSinceEpoch}',
                  descricao,
                  ano,
                  semestre,
                  0,
                  false,
                ),
              );
              _currentPage = _totalPages;
            } else {
              turma.titulo = descricao;
              turma.ano = ano;
              turma.semestre = semestre;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                turma == null ? 'Turma "$descricao" criada' : 'Turma atualizada',
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteClass(_Turma turma) async {
    if (turma.hasAppliedAssessments) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir turma?'),
        content: Text('A turma "${turma.titulo}" será removida desta demonstração.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true || !mounted || turma.hasAppliedAssessments) return;
    setState(() {
      _turmas.remove(turma);
      if (_currentPage > _totalPages) _currentPage = _totalPages;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Turma "${turma.titulo}" excluída')),
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

class _Turma {
  _Turma(
    this.id,
    this.titulo,
    this.ano,
    this.semestre,
    this.studentCount,
    this.hasAppliedAssessments,
  );

  final String id;
  String titulo;
  String ano;
  String semestre;
  int studentCount;
  final bool hasAppliedAssessments;

  String get subtitulo => '$ano · $semestre · $studentCount alunos';
}

class _NovaTurmaSheet extends StatefulWidget {
  const _NovaTurmaSheet({
    this.initialClass,
    required this.onSave,
  });

  final _Turma? initialClass;
  final void Function(String descricao, String ano, String semestre) onSave;

  @override
  State<_NovaTurmaSheet> createState() => _NovaTurmaSheetState();
}

class _NovaTurmaSheetState extends State<_NovaTurmaSheet> {
  late final TextEditingController _descricaoController = TextEditingController(
    text: widget.initialClass?.titulo,
  );
  late final TextEditingController _semestreController = TextEditingController(
    text: widget.initialClass?.semestre ?? '1º semestre',
  );
  late final TextEditingController _anoController = TextEditingController(
    text: widget.initialClass?.ano ?? '2026',
  );

  @override
  void dispose() {
    _descricaoController.dispose();
    _semestreController.dispose();
    _anoController.dispose();
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
              widget.initialClass == null ? 'Nova turma' : 'Editar turma',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
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
              label: widget.initialClass == null
                  ? 'Criar turma'
                  : 'Salvar alterações',
              verticalPadding: 14,
              fontSize: 13,
              onPressed: () {
                final descricao = _descricaoController.text.trim();
                final ano = _anoController.text.trim();
                final semestre = _semestreController.text.trim();
                if (descricao.isEmpty || ano.isEmpty || semestre.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preencha descrição, semestre e ano'),
                    ),
                  );
                  return;
                }
                widget.onSave(descricao, ano, semestre);
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
