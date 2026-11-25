import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_mobile/Screens/assessment_detail_screen.dart';
import 'package:app_mobile/Screens/new_proof_screen.dart';
import 'package:app_mobile/models/aluno.dart';
import 'package:app_mobile/models/assessment.dart';
import 'package:app_mobile/models/question.dart';
import 'package:app_mobile/models/turma.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:app_mobile/services/csv_import_service.dart';
import 'package:app_mobile/services/pdf/prova_pdf.dart';
import 'package:app_mobile/services/random_exam_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

const perguntas = [
  Question(
    statement: 'Qual é o resultado de 7 × 8?',
    options: ['54', '56', '58', '60'],
    correctIndex: 1,
  ),
  Question(
    statement: 'Qual fração equivale a 0,5?',
    options: ['1/2', '1/4', '3/4', '2/3'],
    correctIndex: 0,
  ),
  Question(
    statement: 'Quanto é 9 + 6?',
    options: ['12', '14', '15', '16'],
    correctIndex: 2,
  ),
];
const turma = Turma(
  id: 'turma-1',
  descricao: '3º Ano A - Matemática',
  semestre: 1,
  ano: 2026,
);
const aluno = Aluno(
  id: 'aluno-1',
  turmaId: 'turma-1',
  nome: 'Ana Beatriz',
  matricula: '2026041',
);
const aluno2 = Aluno(
  id: 'aluno-2',
  turmaId: 'turma-1',
  nome: 'Carlos Dias',
  matricula: '2026042',
);

Assessment provaCom(List<Question> questions) => Assessment(
  id: 'prova-n3',
  turmaId: turma.id,
  questions: questions,
  gabarito: [
    for (final (index, question) in questions.indexed)
      QuestaoGabarito(
        questao: index + 1,
        alternativaCorreta: question.correctLetter,
      ),
  ],
  title: 'Avaliação de Matemática — Cap. 4',
  subject: 'Matemática',
  className: '3º Ano A',
  dateLabel: '23 nov. 2026',
  status: AssessmentStatus.draft,
  totalQuestions: questions.length,
  correctedStudents: 0,
  totalStudents: 2,
);

Future<void> evidencia(String nome, List<int> bytes) async {
  final dir = Platform.environment['N3_EVIDENCE_DIR'];
  if (dir != null) {
    await Directory(dir).create(recursive: true);
    await File('$dir/$nome').writeAsBytes(bytes);
  }
}

Future<void> screenshot(WidgetTester tester, GlobalKey key, String nome) async {
  if (Platform.environment['N3_EVIDENCE_DIR'] == null) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await evidencia(nome, data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonte = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await fonte.load();
    final sdk = Platform.environment['FLUTTER_ROOT'];
    if (sdk != null) {
      final file = File(
        '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (await file.exists()) {
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          );
        await icons.load();
      }
    }
  });

  group('N3: sorteio preserva a correta (#69)', () {
    test('determinístico, independente e não altera a lista original', () {
      final a = RandomExamService.prepararQuestoes(
        perguntas,
        embaralharQuestoes: true,
        embaralharAlternativas: true,
        seed: 12,
      );
      final b = RandomExamService.prepararQuestoes(
        perguntas,
        embaralharQuestoes: true,
        embaralharAlternativas: true,
        seed: 12,
      );
      expect(a.map((q) => q.toMap()), b.map((q) => q.toMap()));
      for (final q in a) {
        final original = perguntas.firstWhere(
          (p) => p.statement == q.statement,
        );
        expect(
          q.options[q.correctIndex],
          original.options[original.correctIndex],
        );
        expect(q.options.toSet(), original.options.toSet());
      }
      expect(perguntas.first.options, ['54', '56', '58', '60']);
      expect(perguntas.first.correctIndex, 1);
      final soQuestoes = RandomExamService.prepararQuestoes(
        perguntas,
        embaralharQuestoes: true,
        seed: 12,
      );
      for (final q in soQuestoes) {
        expect(
          q.options,
          perguntas.firstWhere((p) => p.statement == q.statement).options,
        );
      }
      final soAlternativas = RandomExamService.prepararQuestoes(
        perguntas,
        embaralharAlternativas: true,
        seed: 12,
      );
      expect(
        soAlternativas.map((q) => q.statement),
        perguntas.map((q) => q.statement),
      );
    });

    test(
      'alternativas repetidas preservam o índice correto, não o primeiro texto',
      () {
        const duplicada = Question(
          statement: 'Duplicatas',
          options: ['igual', 'outra', 'igual', 'última'],
          correctIndex: 2,
        );
        const identificada = Question(
          statement: 'Identidades',
          options: ['id0', 'id1', 'id2', 'id3'],
          correctIndex: 2,
        );
        for (var seed = 0; seed < 20; seed++) {
          final shuffled = RandomExamService.prepararQuestoes(
            [duplicada],
            embaralharAlternativas: true,
            seed: seed,
          ).single;
          final indices = RandomExamService.prepararQuestoes(
            [identificada],
            embaralharAlternativas: true,
            seed: seed,
          ).single;
          expect(shuffled.correctIndex, indices.options.indexOf('id2'));
        }
      },
    );

    test('rejeita questão incompleta ou índice de resposta inválido', () {
      expect(
        () => RandomExamService.prepararQuestoes([
          const Question(statement: 'Q', options: ['A', 'B'], correctIndex: 4),
        ]),
        throwsArgumentError,
      );
    });
  });

  group('N3: persistência e correção usam a mesma versão', () {
    test('roundtrip mantém enunciado/opções/gabarito e editar não sorteia novamente', () async {
      final firestore = await configurarBancoFalso();
      final criada = await AvaliacaoRepository().criar(
        turma: turma,
        titulo: 'Prova N3',
        disciplina: 'Matemática',
        totalQuestoes: perguntas.length,
        questoes: perguntas,
        embaralharQuestoes: true,
        embaralharAlternativas: true,
      );
      final lida = await AvaliacaoRepository().buscar(criada.id);
      expect(
        lida.questions.map((q) => q.toMap()),
        criada.questions.map((q) => q.toMap()),
      );
      expect(lida.shuffleOptions, isTrue);
      expect(lida.shuffleQuestions, isTrue);
      final editada = await AvaliacaoRepository().editar(
        id: criada.id,
        titulo: 'Título editado',
        disciplina: 'Matemática',
      );
      expect(
        editada.questions.map((q) => q.toMap()),
        lida.questions.map((q) => q.toMap()),
      );
      final certa = lida.questions.map((q) => q.correctLetter).toList();
      final corrigida = ResultadoRepository.corrigir(
        id: 'r',
        avaliacao: lida,
        alunoId: aluno.id,
        respostas: certa,
      );
      expect(corrigida.notaCalculada, 10);
      expect(corrigida.totalAcertos, perguntas.length);
      final dados =
          (await firestore.collection('avaliacoes').doc(criada.id).get())
              .data()!;
      expect((dados['questoes'] as List).length, perguntas.length);
      final revisada = await AvaliacaoRepository().salvarGabarito(
        lida,
        List.filled(perguntas.length, 'A'),
      );
      expect(revisada.questions.every((q) => q.correctIndex == 0), isTrue);
      ProvaPdf.validar(revisada, [aluno]);
      expect(
        () => AvaliacaoRepository().salvarGabarito(
          lida,
          List.filled(perguntas.length, ''),
        ),
        throwsArgumentError,
      );
    });

    test(
      'avaliação antiga continua carregando sem conteúdo inventado',
      () async {
        await configurarBancoFalso();
        final antiga = await AvaliacaoRepository().buscar('aval-1');
        expect(antiga.questions, isEmpty);
        expect(antiga.gabarito.length, 4);
        expect(() => ProvaPdf.validar(antiga, [aluno]), throwsStateError);
      },
    );
  });

  group('N3: PDF real (#63)', () {
    test(
      'gera cadernos e respostas separados com dados reais para dois alunos',
      () async {
        final bytes = await ProvaPdf.gerar(
          prova: provaCom(perguntas),
          alunos: [aluno, aluno2],
        );
        expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
        expect(bytes.length, greaterThan(5000));
        await evidencia('01_prova_dois_alunos.pdf', bytes);
      },
    );

    test('muitas questões e texto longo não cortam nem impedem exportação', () async {
      final longas = List.generate(
        40,
        (i) => Question(
          statement:
              'Questão ${i + 1}: ${List.filled(i == 0 ? 1500 : 8, 'Interpretação e resolução matemática.').join(' ')}',
          options: [
            i == 0
                ? List.filled(
                    300,
                    'Alternativa extensa com acentuação.',
                  ).join(' ')
                : 'Opção A',
            'Opção B',
            'Opção C',
            'Opção D',
          ],
          correctIndex: 1,
        ),
      );
      final bytes = await ProvaPdf.gerar(
        prova: provaCom(longas),
        alunos: [aluno],
      );
      expect(bytes.length, greaterThan(5000));
      await evidencia('02_prova_texto_longo.pdf', bytes);
    });

    test('bloqueia aluno de outra turma ou gabarito inconsistente', () {
      const fora = Aluno(
        id: 'x',
        turmaId: 'outra',
        nome: 'Outro',
        matricula: '0',
      );
      expect(
        () => ProvaPdf.validar(provaCom(perguntas), [fora]),
        throwsStateError,
      );
      expect(() => ProvaPdf.validar(provaCom(perguntas), []), throwsStateError);
    });
  });

  testWidgets('configuração de embaralhamento visível e independente', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await configurarBancoFalso();
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          home: const NewProofScreen(turma: turma),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'Avaliação de Matemática — Cap. 4',
    );
    await tester.tap(find.text('Embaralhar alternativas'));
    await tester.pumpAndSettle();
    final switches = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .toList();
    expect(switches[0].value, isFalse);
    expect(switches[1].value, isTrue);
    await screenshot(tester, key, '03_configuracao_embaralhamento.png');
  });

  testWidgets('exportação da tela entrega PDF e mantém a mesma ordem salva', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await configurarBancoFalso();
    final criada = await AvaliacaoRepository().criar(
      turma: turma,
      titulo: 'Avaliação de Matemática — Cap. 4',
      disciplina: 'Matemática',
      totalQuestoes: perguntas.length,
      questoes: perguntas,
      embaralharAlternativas: true,
    );
    final gerados = <Uint8List>[];
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          home: AssessmentDetailScreen(
            assessment: criada,
            compartilharProva: (bytes, nome) async {
              gerados.add(bytes);
              await evidencia('04_pdf_exportado_pela_tela.pdf', bytes);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Exportar prova em PDF'));
    await tester.pumpAndSettle();
    expect(find.text('Gerar e compartilhar PDF'), findsOneWidget);
    await screenshot(tester, key, '05_exportacao_pdf.png');
    await tester.runAsync(() async {
      await tester.tap(find.text('Gerar e compartilhar PDF'));
      await Future<void>.delayed(const Duration(milliseconds: 900));
    });
    await tester.pumpAndSettle();
    expect(gerados.length, 1);
    final lida = await AvaliacaoRepository().buscar(criada.id);
    expect(
      lida.questions.map((q) => q.toMap()),
      criada.questions.map((q) => q.toMap()),
    );
  });

  testWidgets(
    'questões da nova página CSV mantêm conteúdo e correta ao salvar embaralhadas',
    (tester) async {
      tester.view.physicalSize = const Size(430, 940);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await configurarBancoFalso();
      await tester.pumpWidget(MaterialApp(home: NewProofScreen(turma: turma)));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'Prova importada N3',
      );
      await tester.tap(find.text('Embaralhar alternativas'));
      await tester.tap(find.text('Embaralhar questões'));
      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Adicionar questão'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar questão'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Importar CSV'));
      await tester.pumpAndSettle();
      const csv =
          'enunciado;a;b;c;d;correta\n'
          'Quanto é 7 × 8?;54;56;58;60;B\n'
          'Qual fração equivale a 0,5?;1/2;1/4;2/3;3/4;A';
      await tester.enterText(find.byType(TextField).last, csv);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Importar 2 questões'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar prova'));
      await tester.pumpAndSettle();
      final salva = (await AvaliacaoRepository().listar(turmaId: turma.id))
          .singleWhere((p) => p.title == 'Prova importada N3');
      final originais = CsvImportService.parseProofQuestions(csv).questoes;
      expect(salva.questions.length, 2);
      expect(salva.shuffleQuestions, isTrue);
      expect(salva.shuffleOptions, isTrue);
      for (final question in salva.questions) {
        final original = originais.singleWhere(
          (q) => q.statement == question.statement,
        );
        expect(
          question.options[question.correctIndex],
          original.options[original.correctIndex],
        );
        expect(question.options.toSet(), original.options.toSet());
      }
      ProvaPdf.validar(salva, [aluno]);
    },
  );

  testWidgets('exportação antiga explica ausência de enunciados', (
    tester,
  ) async {
    await configurarBancoFalso();
    final antiga = await AvaliacaoRepository().buscar('aval-1');
    await tester.pumpWidget(
      MaterialApp(home: AssessmentDetailScreen(assessment: antiga)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Exportar prova em PDF'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Esta prova antiga tem apenas gabarito'),
      findsOneWidget,
    );
  });
}
