import 'package:flutter/material.dart';

import '../data/mock_statistics.dart';
import '../models/statistics.dart';
import '../theme/app_colors.dart';

/// Tela 7 — Gerar relatório (PDF).
///
/// Permite escolher a turma e, opcionalmente, uma prova, e visualizar uma
/// prévia do relatório. Nesta entrega a geração do PDF é simulada: não há
/// download real nem biblioteca de PDF envolvida.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final List<ClassStatistics> _classes = mockClassStatistics;

  late ClassStatistics _selectedClass = _classes.first;
  ExamStatistics? _selectedExam; // null = todas as provas
  bool _generated = false;

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
          'Relatório',
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                children: [
                  const _FieldLabel('Turma'),
                  _dropdown<ClassStatistics>(
                    value: _selectedClass,
                    items: _classes,
                    labelBuilder: (c) => c.displayName,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedClass = value;
                        _selectedExam = null;
                        _generated = false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Prova (opcional)'),
                  _dropdown<ExamStatistics?>(
                    value: _selectedExam,
                    items: <ExamStatistics?>[null, ..._selectedClass.exams],
                    labelBuilder: (e) =>
                        e?.assessmentTitle ?? 'Todas as provas',
                    onChanged: (value) {
                      setState(() {
                        _selectedExam = value;
                        _generated = false;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _previewBox(),
                ],
              ),
            ),
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Gerar e baixar PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.input,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppColors.muted, size: 20),
          style: const TextStyle(color: AppColors.text, fontSize: 13),
          borderRadius: BorderRadius.circular(10),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                child: Text(
                  labelBuilder(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _previewBox() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.input,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _generated
          ? _previewContent()
          : const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 34,
                      color: AppColors.muted,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Prévia do relatório em PDF',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _previewContent() {
    final exams = _selectedExam != null
        ? [_selectedExam!]
        : _selectedClass.exams;
    final average = exams.isEmpty
        ? 0
        : (exams.fold<int>(0, (sum, e) => sum + e.averageScore) / exams.length)
              .round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Relatório de desempenho',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'EduTurmas · gerado em ${_todayLabel()}',
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _previewLine('Turma', _selectedClass.displayName),
          _previewLine(
            'Prova',
            _selectedExam?.assessmentTitle ?? 'Todas as provas',
          ),
          _previewLine('Acerto médio', '$average%'),
          const SizedBox(height: 14),
          const Text(
            'Provas incluídas',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (exams.isEmpty)
            const Text(
              'Nenhuma prova corrigida para esta turma.',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            )
          else
            for (final exam in exams)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${exam.assessmentTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      '${exam.averageScore}% · mais errada ${exam.hardestQuestion}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _previewLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generate() {
    setState(() => _generated = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Relatório gerado (pré-visualização simulada nesta entrega)',
        ),
      ),
    );
  }

  String _todayLabel() {
    const months = [
      'jan.',
      'fev.',
      'mar.',
      'abr.',
      'mai.',
      'jun.',
      'jul.',
      'ago.',
      'set.',
      'out.',
      'nov.',
      'dez.',
    ];
    final now = DateTime.now();
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
