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
  final _questionsController = TextEditingController();
  DateTime? _dataAplicacao;

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

  void _selecionarTurma(Turma turma) {
    final disciplinaAtual = _subjectController.text.trim();
    if (disciplinaAtual.isEmpty ||
        disciplinaAtual == _selectedClass?.disciplina) {
      _subjectController.text = turma.disciplina;
    }
    _selectedClass = turma;
  }

  Future<void> _selecionarData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataAplicacao ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (escolhida != null && mounted) {
      setState(() => _dataAplicacao = escolhida);
    }
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
      backgroundColor: context.colors.background,
      appBar: const StandardAppBar(title: 'Nova avaliação'),
      body: SafeArea(
        top: false,
        child: _buildConteudo(),
      ),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.accent),
      );
    }
    if (_erro) {
      return LoadErrorView(onRetry: _carregarTurmas);
    }
    if (_turmas.isEmpty) {
      return EmptyStateView(
        icon: Icons.people_outline,
        iconBackground: context.colors.accentLight,
        iconColor: context.colors.accent,
        title: 'Nenhuma turma cadastrada',
        message: 'Cadastre ao menos uma turma para poder criar avaliações.',
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
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
            icon: Icon(Icons.keyboard_arrow_down, color: context.colors.muted),
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
          _label('Data de aplicação'),
          InkWell(
            onTap: _selecionarData,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              decoration: BoxDecoration(
                color: context.colors.input,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dataAplicacao == null
                        ? 'Selecionar data'
                        : AvaliacaoRepository.formatarData(_dataAplicacao!),
                    style: TextStyle(
                      fontSize: 14,
                      color: _dataAplicacao == null
                          ? context.colors.muted
                          : context.colors.text,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: context.colors.accent,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label('Quantidade de questões'),
          TextFormField(
            controller: _questionsController,
            keyboardType: TextInputType.number,
            decoration: _decoration('Ex: 10'),
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
              color: context.colors.accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 17, color: context.colors.accent),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'A avaliação será criada como rascunho com a data prevista e ficará disponível para configurar o gabarito.',
                    style: TextStyle(
                      color: context.colors.accent,
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
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: context.colors.accent,
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
        style: TextStyle(
          color: context.colors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _decoration(String? hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: context.colors.muted, fontSize: 13),
      filled: true,
      fillColor: context.colors.input,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.colors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.colors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.colors.danger, width: 1.5),
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
        dataAplicacao: _dataAplicacao,
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
