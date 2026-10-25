import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/turma.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';

class NewAssessmentScreen extends StatefulWidget {
  const NewAssessmentScreen({super.key});

  @override
  State<NewAssessmentScreen> createState() => _NewAssessmentScreenState();
}

class _NewAssessmentScreenState extends State<NewAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _questionsController = TextEditingController(text: '10');

  List<Turma> _turmas = [];
  Turma? _selectedClass;
  bool _carregando = true;
  bool _erro = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarTurmas();
  }

  Future<void> _carregarTurmas() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      final turmas = await TurmaRepository().listar();
      if (!mounted) return;
      setState(() {
        _turmas = turmas;
        _carregando = false;
        if (turmas.isNotEmpty) _selecionarTurma(turmas.first);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = true;
        _carregando = false;
      });
    }
  }

  /// Sugere a disciplina da turma enquanto o professor não digitou outra.
  void _selecionarTurma(Turma turma) {
    final disciplinaAtual = _subjectController.text.trim();
    if (disciplinaAtual.isEmpty ||
        disciplinaAtual == _selectedClass?.disciplina) {
      _subjectController.text = turma.disciplina;
    }
    _selectedClass = turma;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _questionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const StandardAppBar(title: 'Nova avaliação'),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (_erro) {
      return LoadErrorView(onRetry: _carregarTurmas);
    }
    if (_turmas.isEmpty) {
      return const EmptyStateView(
        icon: Icons.people_outline,
        iconBackground: AppColors.accentLight,
        iconColor: AppColors.accent,
        title: 'Nenhuma turma cadastrada',
        message: 'Crie uma turma antes de cadastrar avaliações.',
      );
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          const Text(
            'Informações básicas',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Você poderá configurar o gabarito na próxima etapa.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          _label('Título da avaliação'),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration('Ex: Avaliação bimestral — Cap. 5'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Informe um título para continuar'
                : null,
          ),
          const SizedBox(height: 16),
          _label('Disciplina'),
          TextFormField(
            controller: _subjectController,
            textCapitalization: TextCapitalization.words,
            decoration: _decoration('Ex: Matemática'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Informe a disciplina'
                : null,
          ),
          const SizedBox(height: 16),
          _label('Turma'),
          DropdownButtonFormField<Turma>(
            initialValue: _selectedClass,
            isExpanded: true,
            decoration: _decoration(null),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
            items: [
              for (final turma in _turmas)
                DropdownMenuItem(
                  value: turma,
                  child: Text(turma.descricao, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selecionarTurma(value));
              }
            },
          ),
          const SizedBox(height: 16),
          _label('Quantidade de questões'),
          TextFormField(
            controller: _questionsController,
            keyboardType: TextInputType.number,
            decoration: _decoration('10'),
            validator: (value) {
              final count = int.tryParse(value ?? '');
              if (count == null || count < 1 || count > 50) {
                return 'Use um número entre 1 e 50';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 17, color: AppColors.accent),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'A avaliação será criada como rascunho e ficará disponível para configurar o gabarito.',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: _salvando ? 'Salvando...' : 'Criar avaliação',
            verticalPadding: 15,
            fontSize: 13,
            onPressed: _salvando ? null : _submit,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _decoration(String? hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      filled: true,
      fillColor: AppColors.input,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedClass == null) {
      return;
    }

    setState(() => _salvando = true);
    try {
      final assessment = await AvaliacaoRepository().criar(
        turma: _selectedClass!,
        titulo: _titleController.text.trim(),
        disciplina: _subjectController.text.trim(),
        totalQuestoes: int.parse(_questionsController.text),
      );
      if (!mounted) return;
      Navigator.pop(context, assessment);
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível criar a avaliação')),
      );
    }
  }
}
