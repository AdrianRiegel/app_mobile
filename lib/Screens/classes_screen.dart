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
  int _selectedIndex = 1;
  int _currentPage = 1;
  final int _totalPages = 3;

  final List<_Turma> _turmas = const [
    _Turma('3º Ano A - Matemática', '2026 · 1º semestre · 28 alunos'),
    _Turma('2º Ano B - Física', '2026 · 1º semestre · 24 alunos'),
    _Turma('1º Ano C - Química', '2026 · 1º semestre · 31 alunos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: const CustomMiniEndFloatLocation(),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
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
                    const SearchField(hintText: 'Buscar turma por nome'),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _turmas.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final turma = _turmas[index];
                          return _buildTurmaItem(turma);
                        },
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
    return AppListItemCard(
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(Icons.people_outline, size: 18, color: AppColors.accent),
      ),
      title: turma.titulo,
      subtitle: Text(
        turma.subtitulo,
        style: const TextStyle(fontSize: 11, color: AppColors.muted),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassDetailScreen(titulo: turma.titulo),
          ),
        );
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
          color: enabled ? AppColors.accent : AppColors.muted.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  void _openNovaTurmaSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NovaTurmaSheet(
        onCreate: (descricao) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Turma "$descricao" criada')));
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

class _Turma {
  final String titulo;
  final String subtitulo;
  const _Turma(this.titulo, this.subtitulo);
}

class _NovaTurmaSheet extends StatefulWidget {
  const _NovaTurmaSheet({required this.onCreate});

  final ValueChanged<String> onCreate;

  @override
  State<_NovaTurmaSheet> createState() => _NovaTurmaSheetState();
}

class _NovaTurmaSheetState extends State<_NovaTurmaSheet> {
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _semestreController = TextEditingController(
    text: '1º semestre',
  );
  final TextEditingController _anoController = TextEditingController(
    text: '2026',
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
            const Text(
              'Nova turma',
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
              label: 'Criar turma',
              verticalPadding: 14,
              fontSize: 13,
              onPressed: () {
                final descricao = _descricaoController.text.trim();
                widget.onCreate(descricao.isEmpty ? 'Nova turma' : descricao);
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
