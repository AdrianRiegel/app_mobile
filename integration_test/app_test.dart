// Teste ponta a ponta do app rodando com o Firebase real.
//
// Usa uma conta de professor de teste (com as turmas de exemplo) passada por
// --dart-define. Cria dados com sufixo único e os apaga ao terminar.
//
//   chromedriver --port=4444 &
//   flutter drive -d web-server --browser-name=chrome --no-headless \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_test.dart \
//     --dart-define=TEST_EMAIL=... --dart-define=TEST_SENHA=...
import 'package:app_mobile/main.dart' as app;
import 'package:app_mobile/services/database/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _email = String.fromEnvironment('TEST_EMAIL');
const _senha = String.fromEnvironment('TEST_SENHA');

late final IntegrationTestWidgetsFlutterBinding _binding;

void main() {
  _binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fluxo completo do professor com o Firebase', (tester) async {
    expect(_email, isNotEmpty, reason: 'Informe --dart-define=TEST_EMAIL');
    final sufixo = DateTime.now().millisecondsSinceEpoch % 1000000;

    await app.main();
    // Abre no login ou, se a sessão foi restaurada, direto no painel.
    await _aguardar(
      tester,
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Entrar' || (w.data ?? '').startsWith('Olá')),
      ),
    );

    await _passo('Login', () async {
      if (find.text('Entrar').evaluate().isNotEmpty) {
        final campos = find.byType(TextField);
        await tester.enterText(campos.at(0), _email);
        await tester.enterText(campos.at(1), _senha);
        await tester.tap(find.text('Entrar'));
      }
      await _aguardar(tester, find.text('Olá, Maria'));
    });

    // Apaga o que sobrou de execuções anteriores e, no fim, o desta.
    await _LimpezaE2E().executar();
    addTearDown(() => _LimpezaE2E().executar());

    await _passo('Turmas: lista e busca', () async {
      await tester.tap(find.text('Turmas').first);
      await _aguardar(tester, find.text('3º Ano A - Matemática'));
      expect(find.text('2º Ano B - Física'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Física');
      await tester.pump();
      expect(find.text('2º Ano B - Física'), findsOneWidget);
      expect(find.text('3º Ano A - Matemática'), findsNothing);
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();
    });

    await _passo('Turma: cadastra aluno', () async {
      await tester.tap(find.text('3º Ano A - Matemática'));
      await _aguardarNaLista(tester, find.text('Ana Beatriz'));

      await tester.tap(find.text('Adicionar'));
      await _aguardar(tester, find.text('Matrícula').last);
      final campos = find.byType(TextField);
      await tester.enterText(
        campos.at(campos.evaluate().length - 2),
        'Aluno E2E $sufixo',
      );
      await tester.enterText(campos.last, 'E2E$sufixo');
      await tester.tap(find.text('Adicionar aluno'));
      await _aguardarNaLista(tester, find.text('Aluno E2E $sufixo'));
    });

    await _passo('Turma: importa alunos colando CSV', () async {
      await tester.tap(find.text('Importar CSV'));
      await _aguardar(tester, find.text('Processar e Importar'));
      await tester.enterText(
        find.byType(TextField).last,
        'nome;matricula\nCSV Um $sufixo;E2EC1$sufixo\nCSV Dois $sufixo;E2EC2$sufixo',
      );
      await tester.tap(find.text('Processar e Importar'));
      await _aguardarNaLista(tester, find.text('CSV Um $sufixo'));
      await _aguardarNaLista(tester, find.text('CSV Dois $sufixo'));
    });

    final tituloProva = 'Prova E2E $sufixo';
    await _passo('Nova prova pela turma', () async {
      await tester.tap(find.text('Provas'));
      await _aguardar(tester, find.text('Avaliação bimestral — Cap. 4'));
      await tester.tap(find.byType(FloatingActionButton).last);
      await _aguardar(tester, find.text('2 questões'));

      await tester.enterText(find.byType(TextField).first, tituloProva);
      await tester.scrollUntilVisible(
        find.text('Salvar prova'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Salvar prova'));
      // O título também está no campo da própria tela: espera ela fechar.
      await _aguardar(tester, find.text('Salvar prova'), sumir: true);
      await _aguardar(tester, find.text(tituloProva));
    });

    await _passo('Gabarito importado de CSV colado', () async {
      await tester.tap(find.text(tituloProva));
      await _aguardar(tester, find.text('Configurar gabarito'));
      await tester.tap(find.text('Configurar gabarito'));
      await _aguardar(tester, find.byTooltip('Importar gabarito via CSV'));

      await tester.tap(find.byTooltip('Importar gabarito via CSV'));
      await _aguardar(tester, find.text('Aplicar ao Gabarito'));
      await tester.enterText(
        find.byType(TextField).last,
        'questao;resposta\n1;B\n2;A',
      );
      await tester.tap(find.text('Aplicar ao Gabarito'));
      await _aguardar(tester, find.textContaining('alternativas preenchidas'));

      await tester.tap(find.text('Salvar gabarito'));
      await _aguardar(tester, find.text('Gabarito salvo com sucesso'));
    });

    await _passo('Correção de um aluno', () async {
      await tester.tap(find.text('Iniciar correção'));
      await _aguardar(
        tester,
        find.text('Continuar para identificação do aluno'),
      );
      await tester.tap(find.text('Continuar para identificação do aluno'));
      await _aguardar(tester, find.text('Selecione um aluno...'));

      await tester.tap(find.text('Selecione um aluno...'));
      await _aguardar(tester, find.text('Ana Beatriz (2026041)').last);
      await tester.tap(find.text('Ana Beatriz (2026041)').last);
      await _aguardar(tester, find.text('Continuar para leitura da folha'));
      await tester.tap(find.text('Continuar para leitura da folha'));

      await _aguardar(tester, find.text('Simular leitura da Folha'));
      await tester.tap(find.text('Simular leitura da Folha'));
      await _aguardar(tester, find.text('Continuar para resultado'));
      await tester.tap(find.text('Continuar para resultado'));
      await _aguardar(tester, find.text('Nota Final'));
    });

    await _passo('Estatísticas', () async {
      await _voltarAoPainel(tester);
      await tester.tap(find.text('Estatísticas').first);
      // A prova corrigida no passo anterior já deve entrar nas estatísticas.
      await _aguardar(tester, find.text('3º Ano A - Matemática'));
      await tester.tap(find.text('3º Ano A - Matemática'));
      await _aguardar(tester, find.text(tituloProva));
      await tester.tap(find.text(tituloProva));
      await _aguardar(tester, find.text('Acerto médio'));
      expect(find.text('Questão mais errada'), findsOneWidget);
    });

    await _passo('Relatório em PDF', () async {
      await _voltarAoPainel(tester);
      await tester.tap(find.text('Relatórios').first);
      await _aguardar(tester, find.text('Gerar e baixar PDF'));
      await tester.tap(find.text('Gerar e baixar PDF'));
      // Na web o PDF é baixado; a tela mostra a prévia ao terminar.
      await _aguardar(tester, find.text('Relatório de desempenho'));
    });
  });
}

/// Remove do Firestore os alunos (matrícula `E2E...`) e as provas
/// (`Prova E2E ...`) criados pelo teste, com seus resultados. Vai direto às
/// coleções porque o app não deixa excluir aluno de turma com prova aplicada.
class _LimpezaE2E extends FirestoreRepository {
  Future<void> executar() async {
    final batch = firestore.batch();

    final alunosE2E =
        (await alunos.where('professorId', isEqualTo: professorId).get()).docs
            .where((doc) => '${doc.data()['matricula']}'.startsWith('E2E'))
            .toList();
    for (final doc in alunosE2E) {
      batch
        ..delete(doc.reference)
        ..update(turmas.doc(doc.data()['turmaId'] as String), {
          'totalAlunos': FieldValue.increment(-1),
        });
    }

    final provasE2E =
        (await avaliacoes.where('professorId', isEqualTo: professorId).get())
            .docs
            .where((doc) => '${doc.data()['titulo']}'.startsWith('Prova E2E '))
            .toList();
    for (final prova in provasE2E) {
      batch.delete(prova.reference);
      final resultadosDaProva = await resultados
          .where('professorId', isEqualTo: professorId)
          .where('avaliacaoId', isEqualTo: prova.id)
          .get();
      for (final doc in resultadosDaProva.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
    debugPrint(
      'Limpeza E2E: ${alunosE2E.length} alunos, ${provasE2E.length} provas',
    );
  }
}

/// Executa um passo e identifica qual falhou na saída do teste.
Future<void> _passo(String nome, Future<void> Function() acao) async {
  debugPrint('▶ $nome');
  try {
    await acao();
    debugPrint('✔ $nome');
  } catch (e) {
    debugPrint('✘ $nome: $e');
    await _binding.takeScreenshot(
      'falha_${nome.replaceAll(RegExp(r'\W+'), '_')}',
    );
    rethrow;
  }
}

/// Bombeia frames até [finder] aparecer (ou sumir, com [sumir]). Não usa pumpAndSettle porque as
/// telas mostram indicadores de carregamento enquanto o Firebase responde.
Future<void> _aguardar(
  WidgetTester tester,
  Finder finder, {
  Duration limite = const Duration(seconds: 20),
  bool sumir = false,
}) async {
  final fim = DateTime.now().add(limite);
  while (DateTime.now().isBefore(fim)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty != sumir) {
      await tester.pump(const Duration(milliseconds: 400));
      return;
    }
  }
  final naTela = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .where((t) => t.trim().isNotEmpty)
      .toSet()
      .join(' | ');
  throw TestFailure(
    '${sumir ? 'Não sumiu' : 'Não apareceu'} em ${limite.inSeconds}s: $finder\nNa tela: $naTela',
  );
}

/// Como [_aguardar], mas rola a lista da tela: a turma real acumula alunos
/// de execuções anteriores e o item novo pode ficar fora da área visível.
Future<void> _aguardarNaLista(WidgetTester tester, Finder finder) async {
  await _aguardar(tester, find.byType(Scrollable));
  final fim = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(fim)) {
    try {
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await _voltarAoTopo(tester);
      return;
    } on StateError {
      // Ainda não carregou: volta ao topo e tenta de novo.
      await _voltarAoTopo(tester);
    }
  }
  await _aguardar(tester, finder, limite: Duration.zero);
}

/// Deixa visíveis de novo os botões que ficam no início da lista.
Future<void> _voltarAoTopo(WidgetTester tester) async {
  // Enquanto a tela carrega pode ainda não haver lista.
  if (find.byType(Scrollable).evaluate().isNotEmpty) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
  }
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _voltarAoPainel(WidgetTester tester) async {
  for (var i = 0; i < 6 && find.textContaining('Olá').evaluate().isEmpty; i++) {
    final voltar = find.byIcon(Icons.arrow_back);
    if (voltar.evaluate().isEmpty) break;
    await tester.tap(voltar.first);
    await tester.pump(const Duration(milliseconds: 600));
  }
  // Turmas, Estatísticas etc. são abas: o painel fica na aba Início.
  if (find.textContaining('Olá').evaluate().isEmpty) {
    await tester.tap(find.text('Início').last);
  }
  await _aguardar(tester, find.textContaining('Olá'));
}
