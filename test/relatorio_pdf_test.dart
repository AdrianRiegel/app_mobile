import 'dart:convert';
import 'dart:typed_data';

import 'package:app_mobile/Screens/report_screen.dart';
import 'package:app_mobile/models/statistics.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:app_mobile/services/pdf/relatorio_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

bool _ehPdf(Uint8List bytes) =>
    bytes.length > 1000 && latin1.decode(bytes.sublist(0, 5)) == '%PDF-';

void main() {
  group('RelatorioRepository.desempenhoDaTurma (#14)', () {
    test('junta cada aluno com a nota da prova', () async {
      final firestore = await configurarBancoFalso();
      await adicionarResultado(
        firestore,
        alunoId: 'aluno-1',
        acertos: [true, true, true, false],
      );
      await adicionarResultado(
        firestore,
        alunoId: 'aluno-2',
        acertos: [true, false, false, false],
      );

      final desempenho = await RelatorioRepository().desempenhoDaTurma(
        'turma-1',
      );

      expect(desempenho.turmaNome, '3º Ano A - Matemática');
      expect(desempenho.totalAlunos, 2);
      final prova = desempenho.provas.single;
      expect(prova.corrigidos, 2);
      expect(prova.aprovados, 1);
      expect(prova.percentualAprovacao, 50);
      expect(prova.mediaNotas, 5.0); // (7,5 + 2,5) / 2
      expect(prova.alunos.map((a) => a.situacao), ['Aprovado', 'Reprovado']);
    });

    test('aluno sem correção aparece como "Sem correção"', () async {
      final firestore = await configurarBancoFalso();
      await adicionarResultado(
        firestore,
        alunoId: 'aluno-1',
        acertos: [true, true, true, true],
      );

      final desempenho = await RelatorioRepository().desempenhoDaTurma(
        'turma-1',
      );
      final prova = desempenho.provas.single;

      expect(prova.corrigidos, 1);
      expect(prova.alunos.last.aluno.nome, 'Carlos Dias');
      expect(prova.alunos.last.situacao, 'Sem correção');
      expect(prova.mediaNotas, 10.0); // só conta quem foi corrigido
    });

    test('sem prova selecionada, ignora provas ainda não corrigidas', () async {
      await configurarBancoFalso();

      final desempenho = await RelatorioRepository().desempenhoDaTurma(
        'turma-1',
      );

      expect(desempenho.provas, isEmpty);
      expect(desempenho.mediaGeral, 0);
    });
  });

  group('RelatorioPdf', () {
    test('gera o PDF de estatísticas (#27)', () async {
      final prova = ExamStatistics.demo(
        assessmentTitle: 'Avaliação bimestral — Cap. 4',
        shortLabel: 'Cap. 4',
        className: '3º Ano A',
        subject: 'Matemática',
        totalQuestions: 10,
      );
      final bytes = await RelatorioPdf.estatisticas(
        turma: ClassStatistics(
          className: '3º Ano A',
          subject: 'Matemática',
          exams: [prova],
        ),
      );

      expect(_ehPdf(bytes), isTrue);
    });

    test('gera o PDF de desempenho da turma (#14)', () async {
      final firestore = await configurarBancoFalso();
      await adicionarResultado(
        firestore,
        alunoId: 'aluno-1',
        acertos: [true, true, false, false],
      );
      final desempenho = await RelatorioRepository().desempenhoDaTurma(
        'turma-1',
      );

      final bytes = await RelatorioPdf.desempenhoTurma(desempenho);

      expect(_ehPdf(bytes), isTrue);
    });

    test('gera PDF mesmo sem provas corrigidas', () async {
      final bytes = await RelatorioPdf.estatisticas(
        turma: const ClassStatistics(
          className: '2º Ano B',
          subject: 'Física',
          exams: [],
        ),
      );

      expect(_ehPdf(bytes), isTrue);
    });

    test('formata nota e nome do arquivo', () {
      expect(RelatorioPdf.formatarNota(7.5), '7,5');
      expect(RelatorioPdf.formatarNota(10), '10,0');
      expect(
        RelatorioPdf.nomeArquivo('desempenho', '3º Ano A - Matemática'),
        'relatorio_desempenho_3_ano_a_matematica.pdf',
      );
    });
  });

  group('Tela de relatório', () {
    Future<List<(Uint8List, String)>> abrirEGerar(
      WidgetTester tester, {
      String? tipo,
    }) async {
      final firestore = await configurarBancoFalso();
      await adicionarResultado(
        firestore,
        alunoId: 'aluno-1',
        acertos: [true, true, true, false],
      );
      final gerados = <(Uint8List, String)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: ReportScreen(
            compartilharPdf: (bytes, nome) async => gerados.add((bytes, nome)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      if (tipo != null) {
        await tester.tap(find.text(TipoRelatorio.desempenho.label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(tipo).last);
        await tester.pumpAndSettle();
      }

      // A geração do PDF roda fora do relógio falso do teste.
      await tester.runAsync(() async {
        await tester.tap(find.text('Gerar e baixar PDF'));
        for (var i = 0; i < 50 && gerados.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();
      return gerados;
    }

    testWidgets('gera e entrega o PDF de desempenho da turma', (tester) async {
      final gerados = await abrirEGerar(tester);

      expect(gerados, hasLength(1));
      expect(_ehPdf(gerados.single.$1), isTrue);
      expect(gerados.single.$2, 'relatorio_desempenho_3_ano_a_matematica.pdf');
      expect(find.text('Relatório de desempenho'), findsOneWidget);
    });

    testWidgets('gera e entrega o PDF de estatísticas', (tester) async {
      final gerados = await abrirEGerar(
        tester,
        tipo: TipoRelatorio.estatisticas.label,
      );

      expect(gerados, hasLength(1));
      expect(_ehPdf(gerados.single.$1), isTrue);
      expect(
        gerados.single.$2,
        'relatorio_estatisticas_3_ano_a_matematica.pdf',
      );
      expect(find.text('75% · mais errada Q4'), findsOneWidget);
    });
  });
}
