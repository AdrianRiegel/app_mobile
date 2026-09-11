import 'package:flutter/material.dart';

import '../data/mock_assessments.dart'; // ADICIONADO: Para puxar as avaliações reais
import '../models/assessment.dart';
import '../theme/app_colors.dart';

class CorrectionStartScreen extends StatefulWidget {
  const CorrectionStartScreen({super.key, required this.assessment});

  final Assessment assessment;

  @override
  State<CorrectionStartScreen> createState() => _CorrectionStartScreenState();
}

class _CorrectionStartScreenState extends State<CorrectionStartScreen> {
  int _currentStage = 0; // 0 = Avaliação, 1 = Aluno, 2 = Folha, 3 = Resultado
  bool _reading = false;
  bool _readSuccess = false;
  bool _showGabarito = false;

  // ADICIONADO: Variáveis tipadas com seus Models
  late List<Assessment> _availableAssessments;
  Assessment? _selectedAssessment;
  String? _selectedStudent;

  // ADICIONADO: Dicionário simulando banco de dados (Turma -> Lista de Alunos)
  final Map<String, List<String>> _studentsByClass = {
    '3º Ano A': ['Ana Beatriz', 'Carlos Dias', 'Elisa Ferreira', 'João da Silva'],
    '2º Ano B': ['Lucas Mendes', 'Mariana Costa', 'Pedro Alves'],
    '1º Ano C': ['Julia Santos', 'Rafael Souza', 'Sofia Lima', 'Thiago Gomes'],
  };

  @override
  void initState() {
    super.initState();
    // Carrega a lista do mock
    _availableAssessments = List.from(mockAssessments);

    // Garante que a avaliação que veio da tela anterior esteja na lista (caso seja um rascunho novo)
    if (!_availableAssessments.any((a) => a.title == widget.assessment.title)) {
      _availableAssessments.insert(0, widget.assessment);
    }

    // Pré-seleciona a avaliação que foi clicada na tela anterior
    _selectedAssessment = _availableAssessments.firstWhere(
          (a) => a.title == widget.assessment.title,
      orElse: () => _availableAssessments.first,
    );
  }

  // ADICIONADO: Getter que retorna os alunos exatos da turma da avaliação selecionada
  List<String> get _currentClassStudents {
    if (_selectedAssessment == null) return [];

    // Pega o prefixo da turma (ex: "3º Ano A" tirando o " - Matemática" se houver)
    final className = _selectedAssessment!.className.split(' - ').first;

    // Retorna a lista da turma ou uma lista genérica de fallback
    return _studentsByClass[className] ?? ['Aluno Genérico 1', 'Aluno Genérico 2'];
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
          onPressed: () {
            if (_currentStage == 3 && _showGabarito) {
              setState(() => _showGabarito = false);
            } else if (_currentStage > 0) {
              setState(() {
                _currentStage--;
                _readSuccess = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back, size: 20),
          color: AppColors.text,
        ),
        title: const Text(
          'Iniciar correção',
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            _steps(),
            const SizedBox(height: 24),

            // Só exibe o card resumo se a avaliação já foi escolhida (Etapa 1 em diante)
            if (_currentStage > 0 && _selectedAssessment != null) ...[
              const Text(
                'Avaliação selecionada',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 19,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedAssessment!.title,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_selectedAssessment!.className} · ${_selectedAssessment!.totalQuestions} questões',
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
              ),
              const SizedBox(height: 28),
            ],

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildCurrentContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentContent() {
    if (_currentStage == 0) {
      return _selectAssessmentContent();
    } else if (_currentStage == 1) {
      return _selectStudentContent();
    } else if (_currentStage == 3) {
      return _showGabarito ? _gabaritoPage() : _resultSummaryPage();
    } else {
      return _readSuccess ? _successContent() : _scannerContent();
    }
  }

  Widget _steps() {
    const labels = ['Avaliação', 'Aluno', 'Folha', 'Resultado'];
    int currentStep = _currentStage;

    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= currentStep;
        final passed = index < currentStep;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0
                          ? Colors.transparent
                          : (active ? AppColors.accent : AppColors.border),
                    ),
                  ),
                  Container(
                    width: 25,
                    height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent : AppColors.surface,
                      border: Border.all(
                        color: active ? AppColors.accent : AppColors.border,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: active ? Colors.white : AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == labels.length - 1
                          ? Colors.transparent
                          : (passed ? AppColors.accent : AppColors.border),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                labels[index],
                style: TextStyle(
                  color: active ? AppColors.accent : AppColors.muted,
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ETAPA 0: Selecionar Avaliação (Vinculado ao model Assessment)
  Widget _selectAssessmentContent() {
    return Column(
      key: const ValueKey('selectAssessment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Identificação da Avaliação',
          style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'Selecione a avaliação que você irá corrigir agora.',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Assessment>(
              isExpanded: true,
              hint: const Text('Selecione uma avaliação...', style: TextStyle(fontSize: 13)),
              value: _selectedAssessment,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
              items: _availableAssessments.map((Assessment assessment) {
                return DropdownMenuItem<Assessment>(
                  value: assessment,
                  child: Text(
                    '${assessment.title} (${assessment.className})',
                    style: const TextStyle(fontSize: 13, color: AppColors.text),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (Assessment? newValue) {
                setState(() {
                  _selectedAssessment = newValue;
                  _selectedStudent = null; // Reseta o aluno pois a turma mudou
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedAssessment == null
                ? null
                : () => setState(() => _currentStage = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.accentLight,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Continuar para identificação do aluno'),
          ),
        ),
      ],
    );
  }

  // ETAPA 1: Selecionar Aluno (Vinculado a _currentClassStudents)
  Widget _selectStudentContent() {
    return Column(
      key: const ValueKey('selectStudent'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Identificação do Aluno',
          style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Selecione o aluno da turma ${_selectedAssessment!.className}.',
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Selecione um aluno...', style: TextStyle(fontSize: 13)),
              value: _selectedStudent,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
              items: _currentClassStudents.map((String aluno) {
                return DropdownMenuItem<String>(
                  value: aluno,
                  child: Text(aluno, style: const TextStyle(fontSize: 13, color: AppColors.text)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedStudent = newValue;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedStudent == null
                ? null
                : () => setState(() => _currentStage = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.accentLight,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Continuar para leitura da folha'),
          ),
        ),
      ],
    );
  }

  // ETAPA 2: Scanner
  Widget _scannerContent() {
    return Column(
      key: const ValueKey('scanner_folha'),
      children: [
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.accent, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: _reading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : const Icon(Icons.document_scanner_outlined, color: AppColors.accent, size: 74),
        ),
        const SizedBox(height: 18),
        Text(
          _reading ? 'Lendo...' : 'Folha de respostas',
          style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        const Text(
          'Enquadre a folha inteira na câmera\nEsta etapa é uma simulação visual.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _reading ? null : _simulateRead,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Simular leitura da Folha'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.accentLight,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _successContent() {
    return Container(
      key: const ValueKey('success_folha'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 30),
          ),
          const SizedBox(height: 12),
          const Text(
            'Folha lida com sucesso',
            style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'A correção foi processada. A próxima etapa será o resultado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStage = 3),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Continuar para resultado'),
            ),
          ),
        ],
      ),
    );
  }

  // ETAPA 3: Resultado (Cálculo usa as informações reais da Avaliação)
  Widget _resultSummaryPage() {
    // ADICIONADO: Utiliza a quantidade de questões real da avaliação selecionada
    final int totalQuestoes = _selectedAssessment?.totalQuestions ?? 10;

    // Simulação do resultado (Exemplo estático. Na vida real viria do backend)
    final int acertos = (totalQuestoes * 0.7).round(); // Ex: simula 70% de acerto
    final double valorPorQuestao = 10.0 / totalQuestoes;
    final double nota = acertos * valorPorQuestao;
    final bool aprovado = nota >= 6.0;

    return Column(
      key: const ValueKey('resultSummary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: aprovado ? Colors.green[300]! : Colors.red[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aluno avaliado', style: TextStyle(color: AppColors.muted, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                _selectedStudent ?? 'Aluno',
                style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.border),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Acertos', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      Text('$acertos/$totalQuestoes', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nota Final', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      Text(nota.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: aprovado ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      aprovado ? 'Na Média' : 'Abaixo da Média',
                      style: TextStyle(
                        color: aprovado ? Colors.green[700] : Colors.red[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => setState(() => _showGabarito = true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ver gabarito detalhado'),
          ),
        ),
      ],
    );
  }

  Widget _gabaritoPage() {
    return Column(
      key: const ValueKey('gabaritoPage'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Gabarito', style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
            TextButton(
              onPressed: () => setState(() => _showGabarito = false),
              child: const Text('Voltar ao resultado', style: TextStyle(fontSize: 12)),
            )
          ],
        ),
        const SizedBox(height: 8),
        _buildGabaritoGrid(),
        const SizedBox(height: 24),

        // Mantive os cards de questões apenas visualmente
        const Text('Questões', style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildQuestionCard(
          1,
          'Qual é o resultado de 7 × 8?',
          [
            {'letter': 'a', 'text': '54', 'status': 'wrong'},
            {'letter': 'b', 'text': '56', 'status': 'correct'},
            {'letter': 'c', 'text': '58', 'status': 'normal'},
          ],
        ),
      ],
    );
  }

  Widget _buildGabaritoGrid() {
    // ADICIONADO: Renderiza as bolinhas com base no número real de questões da Avaliação
    final int questions = _selectedAssessment?.totalQuestions ?? 10;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(questions, (index) {
          // Lógica de simulação de erro na correção
          final isCorrect = index % 3 != 0;
          final letter = String.fromCharCode(65 + (index % 5)); // A, B, C, D, E...

          return _answerBadge('${index + 1}', letter, isCorrect: isCorrect);
        }),
      ),
    );
  }

  Widget _answerBadge(String number, String letter, {required bool isCorrect}) {
    return Container(
      width: 36,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFF6ED875) : const Color(0xFFE96C6C),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(number, style: const TextStyle(color: Colors.white, fontSize: 9)),
          Text(letter, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int number, String question, List<Map<String, String>> options) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. $question', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(height: 12),
          ...options.map((opt) {
            Color iconColor = Colors.grey[300]!;
            Widget? extraText;

            if (opt['status'] == 'correct') {
              iconColor = const Color(0xFF28A745);
              extraText = const Text(' correta', style: TextStyle(color: Colors.black, fontSize: 13));
            } else if (opt['status'] == 'wrong') {
              iconColor = const Color(0xFFDC3545);
              extraText = const Text(' assinalado', style: TextStyle(color: Color(0xFFDC3545), fontSize: 13));
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    opt['status'] == 'normal' ? Icons.radio_button_unchecked : Icons.circle,
                    color: iconColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text('${opt['letter']}) ${opt['text']}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  if (extraText != null) extraText,
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _simulateRead() async {
    setState(() => _reading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _reading = false;
      _readSuccess = true;
    });
  }
}