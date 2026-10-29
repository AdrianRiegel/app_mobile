import 'dart:math';

import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/aluno.dart';
import '../models/assessment.dart';
import '../models/resultado.dart';
import '../services/omr/omr_processor.dart';
import 'omr_review_screen.dart';
import '../services/camera_service.dart';
import 'camera_capture_screen.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';

class CorrectionStartScreen extends StatefulWidget {
  const CorrectionStartScreen({super.key, this.assessment});

  /// AvaliaÃƒÂ§ÃƒÂ£o prÃƒÂ©-selecionada; sem ela, o professor escolhe na lista.
  final Assessment? assessment;

  @override
  State<CorrectionStartScreen> createState() => _CorrectionStartScreenState();
}

class _CorrectionStartScreenState extends State<CorrectionStartScreen> {
  int _currentStage = 0; // 0 = AvaliaÃƒÂ§ÃƒÂ£o, 1 = Aluno, 2 = Folha, 3 = Resultado
  bool _reading = false;
  bool _readSuccess = false;
  bool _showGabarito = false;

  final _random = Random();

  List<Assessment> _availableAssessments = [];
  bool _carregando = true;
  bool _erro = false;
  Assessment? _selectedAssessment;

  List<Aluno> _alunos = [];
  bool _carregandoAlunos = false;
  Aluno? _selectedStudent;

  List<String?> _respostasLidas = [];
  Resultado? _resultado;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarAvaliacoes();
  }

  /// SÃƒÂ³ avaliaÃƒÂ§ÃƒÂµes com gabarito completo podem ser corrigidas.
  Future<void> _carregarAvaliacoes() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      final avaliacoes = await AvaliacaoRepository().listar();
      if (!mounted) return;
      setState(() {
        _availableAssessments = avaliacoes
            .where((avaliacao) => avaliacao.gabaritoConfigurado)
            .toList();
        _selectedAssessment = _availableAssessments
            .where((avaliacao) => avaliacao.id == widget.assessment?.id)
            .firstOrNull;
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

  Future<void> _irParaAlunos() async {
    setState(() {
      _currentStage = 1;
      _carregandoAlunos = true;
    });
    try {
      final alunos = await AlunoRepository().listarPorTurma(
        _selectedAssessment!.turmaId,
      );
      if (!mounted) return;
      setState(() {
        _alunos = alunos;
        _carregandoAlunos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentStage = 0;
        _carregandoAlunos = false;
      });
      _mostrarMensagem('NÃƒÂ£o foi possÃƒÂ­vel carregar os alunos da turma');
    }
  }

  Future<void> _salvarResultado() async {
    setState(() => _salvando = true);
    try {
      final resultado = await ResultadoRepository().salvar(
        avaliacao: _selectedAssessment!,
        aluno: _selectedStudent!,
        respostas: _respostasLidas,
      );
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _currentStage = 3;
        _salvando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _mostrarMensagem('NÃƒÂ£o foi possÃƒÂ­vel salvar a correÃƒÂ§ÃƒÂ£o');
    }
  }

  void _corrigirProximoAluno() {
    setState(() {
      _currentStage = 1;
      _selectedStudent = null;
      _readSuccess = false;
      _showGabarito = false;
      _resultado = null;
    });
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: 'Iniciar correÃƒÂ§ÃƒÂ£o',
        onBack: () {
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
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            _steps(),
            const SizedBox(height: 24),

            // SÃƒÂ³ exibe o card resumo se a avaliaÃƒÂ§ÃƒÂ£o jÃƒÂ¡ foi escolhida (Etapa 1 em diante)
            if (_currentStage > 0 && _selectedAssessment != null) ...[
              const Text(
                'AvaliaÃƒÂ§ÃƒÂ£o selecionada',
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
                            '${_selectedAssessment!.className} Ã‚Â· ${_selectedAssessment!.totalQuestions} questÃƒÂµes',
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
    const labels = ['AvaliaÃƒÂ§ÃƒÂ£o', 'Aluno', 'Folha', 'Resultado'];
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

  // ETAPA 0: Selecionar AvaliaÃƒÂ§ÃƒÂ£o (Vinculado ao model Assessment)
  Widget _selectAssessmentContent() {
    if (_carregando) {
      return const Padding(
        key: ValueKey('loadingAssessments'),
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }
    if (_erro) {
      return LoadErrorView(
        key: const ValueKey('errorAssessments'),
        onRetry: _carregarAvaliacoes,
      );
    }
    if (_availableAssessments.isEmpty) {
      return const EmptyStateView(
        key: ValueKey('emptyAssessments'),
        icon: Icons.assignment_outlined,
        iconBackground: AppColors.accentLight,
        iconColor: AppColors.accent,
        title: 'Nenhuma avaliaÃƒÂ§ÃƒÂ£o pronta',
        message: 'Configure o gabarito de uma avaliaÃƒÂ§ÃƒÂ£o para poder corrigi-la.',
      );
    }
    return Column(
      key: const ValueKey('selectAssessment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'IdentificaÃƒÂ§ÃƒÂ£o da AvaliaÃƒÂ§ÃƒÂ£o',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Selecione a avaliaÃƒÂ§ÃƒÂ£o que vocÃƒÂª irÃƒÂ¡ corrigir agora.',
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
              hint: const Text(
                'Selecione uma avaliaÃƒÂ§ÃƒÂ£o...',
                style: TextStyle(fontSize: 13),
              ),
              value: _selectedAssessment,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.muted,
              ),
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
        PrimaryButton(
          label: 'Continuar para identificaÃƒÂ§ÃƒÂ£o do aluno',
          verticalPadding: 14,
          onPressed: _selectedAssessment == null ? null : _irParaAlunos,
        ),
      ],
    );
  }

  // ETAPA 1: Selecionar Aluno (Vinculado a _currentClassStudents)
  Widget _selectStudentContent() {
    if (_carregandoAlunos) {
      return const Padding(
        key: ValueKey('loadingStudents'),
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }
    if (_alunos.isEmpty) {
      return EmptyStateView(
        key: const ValueKey('emptyStudents'),
        icon: Icons.person_outline,
        iconBackground: AppColors.accentLight,
        iconColor: AppColors.accent,
        title: 'Turma sem alunos',
        message:
            'Cadastre os alunos da turma ${_selectedAssessment!.className} para corrigir as provas.',
      );
    }
    return Column(
      key: const ValueKey('selectStudent'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'IdentificaÃƒÂ§ÃƒÂ£o do Aluno',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
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
            child: DropdownButton<Aluno>(
              isExpanded: true,
              hint: const Text(
                'Selecione um aluno...',
                style: TextStyle(fontSize: 13),
              ),
              value: _selectedStudent,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.muted,
              ),
              items: _alunos.map((Aluno aluno) {
                return DropdownMenuItem<Aluno>(
                  value: aluno,
                  child: Text(
                    '${aluno.nome} (${aluno.matricula})',
                    style: const TextStyle(fontSize: 13, color: AppColors.text),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (Aluno? newValue) {
                setState(() {
                  _selectedStudent = newValue;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Continuar para leitura da folha',
          verticalPadding: 14,
          onPressed: _selectedStudent == null
              ? null
              : () => setState(() => _currentStage = 2),
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
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : const Icon(
                  Icons.document_scanner_outlined,
                  color: AppColors.accent,
                  size: 74,
                ),
        ),
        const SizedBox(height: 18),
        Text(
          _reading ? 'Lendo...' : 'Folha de respostas',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Enquadre a folha inteira na cÃƒÂ¢mera\nEsta etapa ÃƒÂ© uma simulaÃƒÂ§ÃƒÂ£o visual.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Abrir câmera e fotografar',
          icon: Icons.camera_alt_outlined,
          verticalPadding: 14,
          onPressed: _reading ? null : _abrirCamera,
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: 'Simular leitura da Folha',
          icon: Icons.refresh,
          verticalPadding: 14,
          onPressed: _reading ? null : _simulateRead,
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
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Folha lida com sucesso',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ao continuar, a correÃƒÂ§ÃƒÂ£o serÃƒÂ¡ salva e o resultado exibido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: _salvando ? 'Salvando...' : 'Continuar para resultado',
            verticalPadding: 14,
            onPressed: _salvando ? null : _salvarResultado,
          ),
        ],
      ),
    );
  }

  // ETAPA 3: Resultado salvo no banco
  Widget _resultSummaryPage() {
    final resultado = _resultado!;
    final int totalQuestoes = resultado.respostas.length;
    final int acertos = resultado.totalAcertos;
    final double nota = resultado.notaCalculada;
    final bool aprovado = resultado.aprovado;

    return Column(
      key: const ValueKey('resultSummary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(
              color: aprovado ? Colors.green[300]! : Colors.red[300]!,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aluno avaliado',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                _selectedStudent?.nome ?? 'Aluno',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
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
                      const Text(
                        'Acertos',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                      Text(
                        '$acertos/$totalQuestoes',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nota Final',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                      Text(
                        nota.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: aprovado ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      aprovado ? 'Na MÃƒÂ©dia' : 'Abaixo da MÃƒÂ©dia',
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
        SecondaryButton(
          label: 'Ver gabarito detalhado',
          verticalPadding: 14,
          borderColor: AppColors.accent,
          onPressed: () => setState(() => _showGabarito = true),
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          label: 'Corrigir prÃƒÂ³ximo aluno',
          verticalPadding: 14,
          onPressed: _corrigirProximoAluno,
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
            const Text(
              'Gabarito',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _showGabarito = false),
              child: const Text(
                'Voltar ao resultado',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Alternativa marcada pelo aluno: verde = acerto, vermelho = erro.',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 8),
        _buildGabaritoGrid(),
      ],
    );
  }

  Widget _buildGabaritoGrid() {
    final respostas = _resultado!.respostas;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final resposta in respostas)
            _answerBadge(
              '${resposta.questao}',
              resposta.alternativaMarcada ?? 'Ã¢â‚¬â€œ',
              isCorrect: resposta.correta,
            ),
        ],
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
          Text(
            number,
            style: const TextStyle(color: Colors.white, fontSize: 9),
          ),
          Text(
            letter,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirCamera() async {
    final image = await Navigator.push<CapturedImage>(
      context,
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );
    if (image == null || !mounted) return;
    await _simulateRead();
  }

  /// Simula a leitura óptica da folha: cada questão tem 70% de chance de vir
  /// com a alternativa correta do gabarito.
  Future<void> _simulateRead({bool simularAmbiguidade = false}) async {
    setState(() => _reading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    const alternativas = ['A', 'B', 'C', 'D', 'E'];
    final rawRespostas = [
      for (final questao in _selectedAssessment!.gabarito)
        _random.nextDouble() < 0.7
            ? questao.alternativaCorreta
            : alternativas[_random.nextInt(alternativas.length)],
    ];

    final matrix = OmrProcessor.createDensityMatrix(
      answers: rawRespostas,
      ambiguousQuestions: simularAmbiguidade && rawRespostas.isNotEmpty
          ? {1}
          : null,
    );

    final omrResult = OmrProcessor.processDensityMatrix(matrix);
    List<String?> respostasFinais = omrResult.formattedAnswers;

    if (omrResult.needsManualReview) {
      final revisadas = await Navigator.push<List<String?>>(
        context,
        MaterialPageRoute(
          builder: (_) => OmrReviewScreen(
            result: omrResult,
            studentName: _selectedStudent?.nome ?? 'Aluno',
          ),
        ),
      );
      if (revisadas == null || !mounted) {
        setState(() => _reading = false);
        return;
      }
      respostasFinais = revisadas;
    }

    setState(() {
      _respostasLidas = respostasFinais;
      _reading = false;
      _readSuccess = true;
    });
  }
}
