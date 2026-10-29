import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/assessment.dart';
import '../services/csv_import_service.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';

class AnswerKeyScreen extends StatefulWidget {
  const AnswerKeyScreen({super.key, required this.assessment});

  final Assessment assessment;

  @override
  State<AnswerKeyScreen> createState() => _AnswerKeyScreenState();
}

class _AnswerKeyScreenState extends State<AnswerKeyScreen> {
  final List<String> _options = const ['A', 'B', 'C', 'D', 'E'];
  late final List<String?> _answers = [
    for (final questao in widget.assessment.gabarito)
      questao.alternativaCorreta,
  ];
  bool _salvando = false;

  Future<void> _salvar() async {
    if (_answers.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marque a alternativa correta de todas as questões'),
        ),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final atualizada = await AvaliacaoRepository().salvarGabarito(
        widget.assessment,
        _answers.cast<String>(),
      );
      if (!mounted) return;
      Navigator.pop(context, atualizada);
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o gabarito')),
      );
    }
  }

  void _openImportarGabaritoCsv() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                'Importar Gabarito via Planilha (CSV)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cole as linhas do CSV com "questao" e "resposta" (ex.: 1;A ou questao,resposta):',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 5,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: "questao,resposta\n1,A\n2,B\n3,C\n4,D",
                  hintStyle: const TextStyle(color: AppColors.muted, fontSize: 11),
                  filled: true,
                  fillColor: AppColors.input,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Aplicar ao Gabarito',
                verticalPadding: 13,
                fontSize: 13,
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;

                  final resultado = CsvImportService.parseQuestions(text);
                  Navigator.pop(sheetContext);

                  if (!resultado.temQuestoes) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          resultado.erros.isNotEmpty
                              ? resultado.erros.first
                              : 'Nenhuma questão identificada no CSV',
                        ),
                      ),
                    );
                    return;
                  }

                  var aplicadas = 0;
                  setState(() {
                    for (final q in resultado.questoes) {
                      final idx = q.questao - 1;
                      if (idx >= 0 && idx < _answers.length && q.alternativaCorreta != null) {
                        _answers[idx] = q.alternativaCorreta;
                        aplicadas++;
                      }
                    }
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$aplicadas alternativas preenchidas via CSV!'
                        '${resultado.erros.isNotEmpty ? ' (${resultado.erros.length} erros ignorados)' : ''}',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(sheetContext),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: 'Configurar gabarito',
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, size: 20, color: AppColors.accent),
            tooltip: 'Importar gabarito via CSV',
            onPressed: _openImportarGabaritoCsv,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.assessment.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.assessment.className} · ${widget.assessment.totalQuestions} questões',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                itemCount: _answers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _questionRow(index),
              ),
            ),
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: PrimaryButton(
                label: _salvando ? 'Salvando...' : 'Salvar gabarito',
                icon: Icons.check,
                verticalPadding: 14,
                fontSize: 13,
                onPressed: _salvando ? null : _salvar,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionRow(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${index + 1}.',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _options.map((option) {
                final selected = _answers[index] == option;
                return GestureDetector(
                  onTap: () => setState(() => _answers[index] = option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accent
                          : AppColors.accentLight,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
