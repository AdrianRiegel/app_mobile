import 'dart:convert';

import 'package:app_mobile/Screens/class_detail_screen.dart';
import 'package:app_mobile/Screens/classes_screen.dart';
import 'package:app_mobile/models/turma.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:app_mobile/services/proof_qr_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'helpers/fake_database.dart';

const turma = Turma(
  id: 'turma-1',
  descricao: '3º Ano A - Matemática',
  semestre: 1,
  ano: 2026,
);

void main() {
  testWidgets('voltar em Turmas retorna à tela de origem', (tester) async {
    await configurarBancoFalso();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClassesScreen()),
              ),
              child: const Text('Abrir turmas'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir turmas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Abrir turmas'), findsOneWidget);
    expect(find.byType(ClassesScreen), findsNothing);
  });

  testWidgets('voltar em Turmas sem rota anterior abre o painel', (
    tester,
  ) async {
    await configurarBancoFalso();
    await tester.pumpWidget(const MaterialApp(home: ClassesScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Olá, Maria'), findsOneWidget);
    expect(find.byType(ClassesScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('edição de turma persiste e preserva contagem de alunos', () async {
    await configurarBancoFalso();
    final repo = TurmaRepository();
    await repo.editar(
      id: turma.id,
      descricao: 'Turma editada',
      semestre: 2,
      ano: 2027,
    );
    final salva = await repo.buscar(turma.id);
    expect(salva.descricao, 'Turma editada');
    expect(salva.semestre, 2);
    expect(salva.ano, 2027);
    expect(salva.totalAlunos, 2);
  });

  test('exclusão remove turma, alunos e provas ainda não aplicadas', () async {
    final db = await configurarBancoFalso();
    await TurmaRepository().excluir(turma.id);
    expect((await db.collection('turmas').doc(turma.id).get()).exists, false);
    expect((await db.collection('alunos').get()).docs, isEmpty);
    expect((await db.collection('avaliacoes').get()).docs, isEmpty);
  });

  for (final concluida in [true, false]) {
    test(
      'exclusão bloqueada com ${concluida ? "prova concluída" : "resultado parcial"}',
      () async {
        final db = await configurarBancoFalso();
        if (concluida) {
          await db.collection('avaliacoes').doc('aval-1').update({
            'status': 'concluida',
          });
        } else {
          await adicionarResultado(
            db,
            alunoId: 'aluno-1',
            acertos: [true, true, true, true],
          );
        }
        await expectLater(
          TurmaRepository().excluir(turma.id),
          throwsA(isA<TurmaComProvaAplicadaException>()),
        );
        expect(
          (await db.collection('turmas').doc(turma.id).get()).exists,
          true,
        );
        expect((await db.collection('alunos').get()).docs.length, 2);
      },
    );
  }

  testWidgets('turmas do banco paginam e busca volta à primeira página', (
    tester,
  ) async {
    final db = await configurarBancoFalso();
    for (var i = 0; i < 9; i++) {
      await db.collection('turmas').doc('extra-$i').set({
        'professorId': professorId,
        'descricao': 'Turma $i',
        'semestre': 1,
        'ano': 2026,
      });
    }
    await tester.pumpWidget(const MaterialApp(home: ClassesScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Página 1 de 2'), findsOneWidget);
    await tester.tap(find.text('Próxima ›'));
    await tester.pumpAndSettle();
    expect(find.text('Página 2 de 2'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Matemática');
    await tester.pumpAndSettle();
    expect(find.text('Página 1 de 1'), findsOneWidget);
    expect(find.text(turma.descricao), findsOneWidget);
  });

  testWidgets('alunos do banco paginam e gesto abre provas', (tester) async {
    final db = await configurarBancoFalso();
    for (var i = 0; i < 9; i++) {
      await db.collection('alunos').doc('extra-$i').set({
        'professorId': professorId,
        'turmaId': turma.id,
        'nome': 'Estudante $i',
        'matricula': 'extra-$i',
      });
    }
    await tester.pumpWidget(
      const MaterialApp(home: ClassDetailScreen(turma: turma)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Página 1 de 2'), findsOneWidget);
    await tester.tap(find.text('Próxima ›'));
    await tester.pumpAndSettle();
    expect(find.text('Página 2 de 2'), findsOneWidget);
    expect(find.text('Ana Beatriz'), findsNothing);
    await tester.fling(find.text('Estudante 6'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Provas · 3º Ano A'), findsOneWidget);
  });

  testWidgets('QR usa IDs reais e muda conforme aluno selecionado', (
    tester,
  ) async {
    await configurarBancoFalso();
    await tester.pumpWidget(
      const MaterialApp(home: ClassDetailScreen(turma: turma)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Provas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Gerar QR Code por aluno'));
    await tester.pumpAndSettle();
    expect(find.text('QR Code individual'), findsOneWidget);
    // O dado codificado também aparece na legenda, sem depender da leitura óptica.
    expect(
      find.text('Turma turma-1 · Prova aval-1 · Aluno aluno-1'),
      findsOneWidget,
    );
    expect(find.byType(QrImageView), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carlos Dias').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Turma turma-1 · Prova aval-1 · Aluno aluno-2'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('payload preserva IDs e rejeita identificadores vazios', () {
    final payload = const ProofQrPayload(
      classId: 'turma-1',
      proofId: 'aval-1',
      studentId: 'aluno-1',
    );
    expect(jsonDecode(payload.encode()), {
      'version': 1,
      'class_id': 'turma-1',
      'proof_id': 'aval-1',
      'student_id': 'aluno-1',
    });
    expect(
      () => const ProofQrPayload(
        classId: '',
        proofId: 'a',
        studentId: 'b',
      ).encode(),
      throwsArgumentError,
    );
  });
}
