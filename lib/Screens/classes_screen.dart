import 'package:flutter/material.dart';

import 'assessments_screen.dart';

import 'class_detail_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final Color bgColor = const Color(0xFFF0F1F4);
  final Color cardColor = const Color(0xFFFFFFFF);
  final Color borderColor = const Color(0xFFE2E4E9);
  final Color textColor = const Color(0xFF1B1D22);
  final Color mutedColor = const Color(0xFF6B7078);
  final Color accentColor = const Color(0xFF4F5BD5);
  final Color accentLightColor = const Color(0xFFECEEFB);
  final Color inputBgColor = const Color(0xFFFAFAFB);

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
      backgroundColor: bgColor,
      floatingActionButtonLocation: const CustomMiniEndFloatLocation(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Text(
                    'Turmas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
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
                          style: TextStyle(fontSize: 11, color: mutedColor),
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
        backgroundColor: accentColor,
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
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
            selectedItemColor: accentColor,
            unselectedItemColor: mutedColor,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            iconSize: 22,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Início',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                label: 'Turmas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                label: 'Avaliações',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Perfil',
              ),
            ],
          ),
        ),
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
              builder: (context) => ClassDetailScreen(titulo: turma.titulo),
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
              Icon(Icons.chevron_right, size: 18, color: mutedColor),
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
          color: enabled ? accentColor : mutedColor.withValues(alpha: 0.4),
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
        accentColor: accentColor,
        borderColor: borderColor,
        textColor: textColor,
        mutedColor: mutedColor,
        inputBgColor: inputBgColor,
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
  const _NovaTurmaSheet({
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
                  color: widget.borderColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Text(
              'Nova turma',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: widget.textColor,
              ),
            ),
            const SizedBox(height: 14),
            _label('Descrição'),
            _field(_descricaoController, hint: 'Ex: 3º Ano A - Matemática'),
            const SizedBox(height: 12),
            _label('Semestre'),
            _field(_semestreController),
            const SizedBox(height: 12),
            _label('Ano'),
            _field(_anoController, keyboardType: TextInputType.number),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                final descricao = _descricaoController.text.trim();
                widget.onCreate(descricao.isEmpty ? 'Nova turma' : descricao);
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
                'Criar turma',
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
