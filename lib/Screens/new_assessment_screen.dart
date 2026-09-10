import 'package:flutter/material.dart';

import '../models/assessment.dart';
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

  String _selectedClass = '3º Ano A';

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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 20),
          color: AppColors.text,
        ),
        title: const Text(
          'Nova avaliação',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
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
              DropdownButtonFormField<String>(
                initialValue: _selectedClass,
                decoration: _decoration(null),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.muted,
                ),
                items: const [
                  DropdownMenuItem(value: '3º Ano A', child: Text('3º Ano A')),
                  DropdownMenuItem(value: '2º Ano B', child: Text('2º Ano B')),
                  DropdownMenuItem(value: '1º Ano C', child: Text('1º Ano C')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedClass = value);
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
                    Icon(
                      Icons.info_outline,
                      size: 17,
                      color: AppColors.accent,
                    ),
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
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Criar avaliação',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
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
        ),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    const classSizes = {
      '3º Ano A': 28,
      '2º Ano B': 24,
      '1º Ano C': 31,
    };

    Navigator.pop(
      context,
      Assessment(
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        className: _selectedClass,
        dateLabel: 'Sem data',
        status: AssessmentStatus.draft,
        totalQuestions: int.parse(_questionsController.text),
        correctedStudents: 0,
        totalStudents: classSizes[_selectedClass]!,
      ),
    );
  }
}
