import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/aluno.dart';
import '../models/assessment.dart';
import '../models/resultado.dart';
import '../services/omr/answer_sheet_layout.dart';
import '../services/omr/omr_image_reader.dart';
import '../services/omr/omr_models.dart';
import '../services/omr/omr_processor.dart';
import '../services/proof_qr_payload.dart';
import 'omr_review_screen.dart';
import '../services/camera_service.dart';
import 'camera_capture_screen.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';

/// Lê uma foto da folha: o QR Code e o preenchimento das bolhas. Devolve a
/// leitura ou a mensagem de erro para o professor.
typedef LeitorFolha =
    Future<(AnswerSheetScan?, String?)> Function(Uint8List foto);

class CorrectionStartScreen extends StatefulWidget {
  const CorrectionStartScreen({super.key, this.assessment, this.leitorFolha});

  /// Avaliação de onde a correção foi aberta. As folhas fotografadas
  /// precisam ser dela; sem ela, vale a avaliação indicada no QR Code.
  final Assessment? assessment;

  /// Leitura da foto; por padrão roda em outro isolate para não travar a
  /// tela. Os testes passam uma versão síncrona.
  final LeitorFolha? leitorFolha;

  static Future<(AnswerSheetScan?, String?)> lerEmIsolate(Uint8List foto) =>
      compute(lerFolhaAgora, foto);

  static (AnswerSheetScan?, String?) lerFolhaAgora(Uint8List foto) {
    try {
      return (OmrImageReader.scan(foto), null);
    } on AnswerSheetReadException catch (e) {
      return (null, e.message);
    } catch (_) {
      return (null, 'Não foi possível ler a foto da folha.');
    }
  }

  @override
  State<CorrectionStartScreen> createState() => _CorrectionStartScreenState();
}

class _CorrectionStartScreenState extends State<CorrectionStartScreen> {
  // 0 = Avaliação, 1 = Aluno, 2 = Folha, 3 = Resultado. Pelo QR Code (padrão)
  // começa direto na Folha: a avaliação e o aluno vêm do QR.
  int _currentStage = 2;

  /// Avaliação e aluno escolhidos na lista, para folhas sem QR legível.
  bool _modoManual = false;
  bool _reading = false;
  bool _readSuccess = false;
  bool _showGabarito = false;

  List<Assessment> _availableAssessments = [];
  bool _carregando = true;
  bool _erro = false;
  Assessment? _selectedAssessment;

  List<Aluno> _alunos = [];
  Map<String, Resultado> _resultadosAlunos = {};
  bool _carregandoAlunos = false;
  Aluno? _selectedStudent;

  List<String?> _respostasLidas = [];
  CapturedImage? _capturedImage;
  Resultado? _resultado;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _selectedAssessment = widget.assessment;
  }

  void _escolherManualmente() {
    setState(() {
      _modoManual = true;
      _currentStage = 0;
      _selectedStudent = null;
    });
    _carregarAvaliacoes();
  }

  /// Só avaliações com gabarito completo podem ser corrigidas.
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
      final resultados = await ResultadoRepository().listarPorAvaliacao(
        _selectedAssessment!.id,
      );
      if (!mounted) return;
      setState(() {
        _alunos = alunos;
        _resultadosAlunos = {for (final r in resultados) r.alunoId: r};
        _carregandoAlunos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentStage = 0;
        _carregandoAlunos = false;
      });
      _mostrarMensagem('Não foi possível carregar os alunos da turma');
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
        _resultadosAlunos[resultado.alunoId] = resultado;
        _currentStage = 3;
        _salvando = false;
      });
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _mostrarMensagem(e.message);
    } catch (e) {
      debugPrint('Erro ao salvar a correção: $e');
      if (!mounted) return;
      setState(() => _salvando = false);
      _mostrarMensagem(
        e is FirebaseException && e.code == 'permission-denied'
            ? 'Sem permissão para salvar a correção. Entre de novo na conta.'
            : 'Não foi possível salvar a correção. Verifique a conexão.',
      );
    }
  }

  void _corrigirProximoAluno() {
    setState(() {
      _currentStage = _modoManual ? 1 : 2;
      if (!_modoManual) _selectedAssessment = widget.assessment;
      _selectedStudent = null;
      _readSuccess = false;
      _showGabarito = false;
      _resultado = null;
      _capturedImage = null;
    });
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: StandardAppBar(
        title: 'Iniciar correção',
        onBack: () {
          if (_currentStage == 3 && _showGabarito) {
            setState(() => _showGabarito = false);
          } else if (!_modoManual && _currentStage == 3) {
            _corrigirProximoAluno();
          } else if (_modoManual && _currentStage > 0) {
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

            // Só exibe o card resumo se a avaliação já foi escolhida (Etapa 1 em diante)
            if (_currentStage > 0 && _selectedAssessment != null) ...[
              Text(
                'Avaliação selecionada',
                style: TextStyle(
                  color: context.colors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border.all(color: context.colors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: context.colors.accentLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        size: 19,
                        color: context.colors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedAssessment!.title,
                            style: TextStyle(
                              color: context.colors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_selectedAssessment!.className} · ${_selectedAssessment!.totalQuestions} questões',
                            style: TextStyle(
                              color: context.colors.muted,
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
    final labels = _modoManual
        ? const ['Avaliação', 'Aluno', 'Folha', 'Resultado']
        : const ['Folha', 'Resultado'];
    final currentStep = _modoManual
        ? _currentStage
        : (_currentStage == 3 ? 1 : 0);

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
                          : (active ? context.colors.accent : context.colors.border),
                    ),
                  ),
                  Container(
                    width: 25,
                    height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? context.colors.accent : context.colors.surface,
                      border: Border.all(
                        color: active ? context.colors.accent : context.colors.border,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: active ? Colors.white : context.colors.muted,
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
                          : (passed ? context.colors.accent : context.colors.border),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                labels[index],
                style: TextStyle(
                  color: active ? context.colors.accent : context.colors.muted,
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
    if (_carregando) {
      return Padding(
        key: ValueKey('loadingAssessments'),
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: CircularProgressIndicator(color: context.colors.accent),
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
      return EmptyStateView(
        key: ValueKey('emptyAssessments'),
        icon: Icons.assignment_outlined,
        iconBackground: context.colors.accentLight,
        iconColor: context.colors.accent,
        title: 'Nenhuma avaliação pronta',
        message: 'Configure o gabarito de uma avaliação para poder corrigi-la.',
      );
    }
    return Column(
      key: const ValueKey('selectAssessment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Identificação da Avaliação',
          style: TextStyle(
            color: context.colors.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Selecione a avaliação que você irá corrigir agora.',
          style: TextStyle(color: context.colors.muted, fontSize: 11),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border.all(color: context.colors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Assessment>(
              isExpanded: true,
              hint: const Text(
                'Selecione uma avaliação...',
                style: TextStyle(fontSize: 13),
              ),
              value: _selectedAssessment,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: context.colors.muted,
              ),
              items: _availableAssessments.map((Assessment assessment) {
                return DropdownMenuItem<Assessment>(
                  value: assessment,
                  child: Text(
                    '${assessment.title} (${assessment.className})',
                    style: TextStyle(fontSize: 13, color: context.colors.text),
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
          label: 'Continuar para identificação do aluno',
          verticalPadding: 14,
          onPressed: _selectedAssessment == null ? null : _irParaAlunos,
        ),
      ],
    );
  }

  // ETAPA 1: Selecionar Aluno (Vinculado a _currentClassStudents)
  Widget _selectStudentContent() {
    if (_carregandoAlunos) {
      return Padding(
        key: ValueKey('loadingStudents'),
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: CircularProgressIndicator(color: context.colors.accent),
        ),
      );
    }
    if (_alunos.isEmpty) {
      return EmptyStateView(
        key: const ValueKey('emptyStudents'),
        icon: Icons.person_outline,
        iconBackground: context.colors.accentLight,
        iconColor: context.colors.accent,
        title: 'Turma sem alunos',
        message:
            'Cadastre os alunos da turma ${_selectedAssessment!.className} para corrigir as provas.',
      );
    }

    final bool alunoJaCorrigido = _selectedStudent != null &&
        _resultadosAlunos.containsKey(_selectedStudent!.id);
    final Resultado? resultadoExistente = alunoJaCorrigido
        ? _resultadosAlunos[_selectedStudent!.id]
        : null;
    final bool todosCorrigidos =
        _alunos.isNotEmpty && _alunos.every((a) => _resultadosAlunos.containsKey(a.id));

    return Column(
      key: const ValueKey('selectStudent'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (todosCorrigidos) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.colors.neutralLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: context.colors.success,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Todas as provas desta turma já foram corrigidas.',
                    style: TextStyle(
                      color: context.colors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Text(
          'Identificação do Aluno',
          style: TextStyle(
            color: context.colors.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Selecione o aluno da turma ${_selectedAssessment!.className}.',
          style: TextStyle(color: context.colors.muted, fontSize: 11),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border.all(color: context.colors.border),
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
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: context.colors.muted,
              ),
              items: _alunos.map((Aluno aluno) {
                final corrigido = _resultadosAlunos.containsKey(aluno.id);
                final nota = _resultadosAlunos[aluno.id]?.notaCalculada;
                return DropdownMenuItem<Aluno>(
                  value: aluno,
                  child: Text(
                    corrigido
                        ? '${aluno.nome} (${aluno.matricula}) · Já corrigido (${nota?.toStringAsFixed(1)})'
                        : '${aluno.nome} (${aluno.matricula})',
                    style: TextStyle(
                      fontSize: 13,
                      color: corrigido ? context.colors.muted : context.colors.text,
                    ),
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
        if (alunoJaCorrigido) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.dangerLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: context.colors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: context.colors.danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A prova deste aluno já foi corrigida (Nota: ${resultadoExistente?.notaCalculada.toStringAsFixed(1)}). Não é permitido corrigir novamente.',
                    style: TextStyle(
                      color: context.colors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          label: alunoJaCorrigido
              ? 'Prova já corrigida'
              : 'Continuar para leitura da folha',
          verticalPadding: 14,
          onPressed: (_selectedStudent == null || alunoJaCorrigido)
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
            color: context.colors.surface,
            border: Border.all(color: context.colors.accent, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: _reading
              ? Center(
                  child: CircularProgressIndicator(color: context.colors.accent),
                )
              : Icon(
                  Icons.document_scanner_outlined,
                  color: context.colors.accent,
                  size: 74,
                ),
        ),
        const SizedBox(height: 18),
        Text(
          _reading
              ? 'Lendo...'
              : _modoManual
              ? 'Folha de ${_selectedStudent?.nome ?? 'aluno'}'
              : 'Fotografe a folha de respostas',
          style: TextStyle(
            color: context.colors.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _modoManual
              ? 'Enquadre a folha inteira, com os 4 quadrados pretos dos '
                    'cantos visíveis.'
              : 'O QR Code da folha identifica a prova e o aluno. Enquadre a '
                    'folha inteira, com os 4 quadrados pretos dos cantos e o QR '
                    'Code visíveis.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.muted, fontSize: 11),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Fotografar folha',
          icon: Icons.camera_alt_outlined,
          verticalPadding: 14,
          onPressed: _reading ? null : _abrirCamera,
        ),
        const SizedBox(height: 10),
        if (_modoManual)
          SecondaryButton(
            label: 'Digitar respostas',
            icon: Icons.edit_note,
            onPressed: _reading ? null : _digitarRespostas,
          )
        else
          TextButton(
            onPressed: _reading ? null : _escolherManualmente,
            child: Text(
              'QR Code ilegível? Escolher avaliação e aluno',
              style: TextStyle(color: context.colors.accent, fontSize: 12),
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
        color: context.colors.surface,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: context.colors.successLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: context.colors.success,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Folha lida com sucesso',
            style: TextStyle(
              color: context.colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_selectedStudent != null) ...[
            const SizedBox(height: 6),
            Text(
              'Aluno(a): ${_selectedStudent!.nome} · '
              'Matrícula ${_selectedStudent!.matricula}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.text,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (_capturedImage != null) ...[
            const SizedBox(height: 6),
            Text(
              'Foto capturada: ${_capturedImage!.name}',
              style: TextStyle(
                color: context.colors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Ao continuar, a correção será salva e o resultado exibido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.muted, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: _salvando ? 'Salvando...' : 'Continuar para resultado',
            loading: _salvando,
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
            color: context.colors.surface,
            border: Border.all(
              color: aprovado ? context.colors.success : context.colors.danger,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aluno avaliado',
                style: TextStyle(color: context.colors.muted, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                _selectedStudent?.nome ?? 'Aluno',
                style: TextStyle(
                  color: context.colors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: context.colors.border),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acertos',
                        style: TextStyle(color: context.colors.muted, fontSize: 11),
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
                      Text(
                        'Nota Final',
                        style: TextStyle(color: context.colors.muted, fontSize: 11),
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
                      color: aprovado
                          ? context.colors.successLight
                          : context.colors.dangerLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      aprovado ? 'Na Média' : 'Abaixo da Média',
                      style: TextStyle(
                        color: aprovado
                            ? context.colors.success
                            : context.colors.danger,
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
          borderColor: context.colors.accent,
          onPressed: () => setState(() => _showGabarito = true),
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          label: _modoManual ? 'Corrigir próximo aluno' : 'Corrigir próxima folha',
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
            Text(
              'Gabarito',
              style: TextStyle(
                color: context.colors.text,
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
        Text(
          'Alternativa marcada pelo aluno: verde = acerto, vermelho = erro.',
          style: TextStyle(color: context.colors.muted, fontSize: 11),
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
        color: context.colors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final resposta in respostas)
            _answerBadge(
              '${resposta.questao}',
              resposta.alternativaMarcada ?? '–',
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

  /// Alternativas impressas de cada questão (provas antigas, sem o conteúdo
  /// das questões, usam A a E).
  List<int> get _alternativasPorQuestao {
    final prova = _selectedAssessment!;
    if (prova.questions.length == prova.gabarito.length) {
      return [for (final q in prova.questions) q.options.length];
    }
    return List.filled(prova.gabarito.length, AnswerSheetLayout.letters.length);
  }

  Future<void> _abrirCamera() async {
    final leitor = widget.leitorFolha ?? CorrectionStartScreen.lerEmIsolate;
    final leituras = <AnswerSheetScan>[];
    int? folhas;

    for (var folha = 0; folhas == null || folha < folhas; folha++) {
      final image = await Navigator.push<CapturedImage>(
        context,
        MaterialPageRoute(
          builder: (_) => CameraCaptureScreen(
            instruction: folhas != null && folhas > 1
                ? 'Folha ${folha + 1} de $folhas de '
                      '${_selectedStudent?.nome ?? 'aluno'}: enquadre a folha '
                      'inteira, com os 4 quadrados pretos dos cantos'
                : null,
          ),
        ),
      );
      if (image == null || !mounted) {
        _cancelarLeitura();
        return;
      }
      setState(() {
        _capturedImage = image;
        _reading = true;
      });

      final (scan, erroLeitura) = await leitor(image.bytes ?? Uint8List(0));
      if (!mounted) return;
      final erro =
          erroLeitura ??
          (scan == null
              ? 'Não foi possível ler a foto da folha.'
              : await _identificar(scan.qrText));
      if (!mounted) return;
      if (erro != null) {
        _cancelarLeitura();
        _mostrarMensagem(erro);
        return;
      }
      leituras.add(scan!);
      folhas ??= AnswerSheetLayout.pageCount(_alternativasPorQuestao.length);
    }

    final alternativas = _alternativasPorQuestao;
    final densidades = <List<double>>[
      for (var folha = 0; folha < leituras.length; folha++)
        ...() {
          final (inicio, fim) = AnswerSheetLayout.questionRange(
            folha,
            alternativas.length,
          );
          return leituras[folha].densities(alternativas.sublist(inicio, fim));
        }(),
    ];

    final omrResult = OmrProcessor.processDensityMatrix(
      densidades,
      options: AnswerSheetLayout.letters,
    );
    await _concluirLeitura(omrResult);
  }

  /// Desfaz uma leitura interrompida. Pelo QR Code, a próxima foto volta a
  /// identificar a prova e o aluno.
  void _cancelarLeitura() {
    if (!mounted) return;
    setState(() {
      _reading = false;
      _capturedImage = null;
      if (!_modoManual) {
        _selectedStudent = null;
        _selectedAssessment = widget.assessment;
      }
    });
  }

  /// Identifica a prova e o aluno pelo QR Code da folha. Devolve a mensagem
  /// de erro, ou `null` se a folha pode ser corrigida.
  Future<String?> _identificar(String? qrText) async {
    final jaIdentificado =
        _selectedAssessment != null && _selectedStudent != null;
    if (qrText == null) {
      // Na escolha manual (ou nas folhas seguintes), a foto basta.
      if (jaIdentificado) return null;
      return 'Não consegui ler o QR Code da folha. Fotografe de novo com o '
          'QR Code nítido ou escolha a avaliação e o aluno.';
    }

    final ProofQrPayload qr;
    try {
      qr = ProofQrPayload.decode(qrText);
    } on FormatException {
      return 'Este QR Code não é de uma folha de respostas do EduTurmas.';
    }

    if (jaIdentificado) {
      if (qr.proofId != _selectedAssessment!.id) {
        return 'Esta folha é de outra prova, não de '
            '"${_selectedAssessment!.title}".';
      }
      if (qr.studentId != _selectedStudent!.id) {
        final dono = _alunos.where((a) => a.id == qr.studentId).firstOrNull;
        return 'Esta folha é de ${dono?.nome ?? 'outro aluno'}, não de '
            '${_selectedStudent!.nome}.';
      }
      return null;
    }

    final esperada = widget.assessment;
    if (esperada != null && qr.proofId != esperada.id) {
      return 'Esta folha é de outra prova, não de "${esperada.title}".';
    }

    final Assessment prova;
    final List<Aluno> alunos;
    final List<Resultado> resultados;
    try {
      prova = await AvaliacaoRepository().buscar(qr.proofId);
      if (prova.turmaId != qr.classId) {
        return 'O QR Code não corresponde à turma desta prova.';
      }
      alunos = await AlunoRepository().listarPorTurma(prova.turmaId);
      resultados = await ResultadoRepository().listarPorAvaliacao(prova.id);
    } on StateError {
      return 'A prova desta folha não foi encontrada. Ela pode ter sido '
          'excluída.';
    } on FirebaseException catch (e) {
      // Prova de outro professor: as regras negam a leitura.
      if (e.code == 'permission-denied') {
        return 'A prova desta folha não foi encontrada na sua conta.';
      }
      return 'Não foi possível carregar a prova desta folha. Verifique a '
          'conexão e tente de novo.';
    } catch (_) {
      return 'Não foi possível carregar a prova desta folha. Verifique a '
          'conexão e tente de novo.';
    }

    if (prova.isCompleted) {
      return 'A correção de "${prova.title}" já foi encerrada.';
    }
    if (!prova.gabaritoConfigurado) {
      return 'Configure o gabarito de "${prova.title}" antes de corrigir.';
    }
    final aluno = alunos.where((a) => a.id == qr.studentId).firstOrNull;
    if (aluno == null) {
      return 'O aluno desta folha não está mais cadastrado na turma.';
    }
    final anterior = resultados.where((r) => r.alunoId == aluno.id).firstOrNull;
    if (anterior != null) {
      return 'A prova de ${aluno.nome} já foi corrigida '
          '(nota ${anterior.notaCalculada.toStringAsFixed(1)}).';
    }

    if (!mounted) return null;
    setState(() {
      _selectedAssessment = prova;
      _alunos = alunos;
      _resultadosAlunos = {for (final r in resultados) r.alunoId: r};
      _selectedStudent = aluno;
    });
    return null;
  }

  /// Sem foto (folha antiga, câmera indisponível): o professor informa as
  /// alternativas na tela de revisão.
  Future<void> _digitarRespostas() async {
    final alternativas = _alternativasPorQuestao;
    final resultado = OmrProcessingResult(
      isSuccessful: true,
      overallConfidence: 1,
      needsManualReview: true,
      reviewReason:
          'Informe a alternativa marcada pelo aluno em cada questão.',
      questions: [
        for (var q = 0; q < alternativas.length; q++)
          QuestionReading(
            questao: q + 1,
            isBlank: true,
            bubbles: [
              for (var op = 0; op < alternativas[q]; op++)
                BubbleReading(
                  questao: q + 1,
                  alternativa: AnswerSheetLayout.letters[op],
                  fillRatio: 0,
                  isMarked: false,
                ),
            ],
          ),
      ],
    );
    setState(() => _capturedImage = null);
    await _concluirLeitura(resultado);
  }

  Future<void> _concluirLeitura(OmrProcessingResult omrResult) async {
    var respostas = omrResult.formattedAnswers;
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
      if (!mounted) return;
      if (revisadas == null) {
        setState(() => _reading = false);
        return;
      }
      respostas = revisadas;
    }

    setState(() {
      _respostasLidas = respostas;
      _reading = false;
      _readSuccess = true;
    });
  }
}
