import 'package:app_mobile/main.dart';
import 'package:app_mobile/models/turma.dart';
import 'package:app_mobile/Screens/class_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

void main() {
  const turma = Turma(
    id: 'turma-1',
    descricao: '3º Ano A - Matemática',
    semestre: 1,
    ano: 2026,
    totalAlunos: 2,
  );

  testWidgets('entra com e-mail e senha e abre o painel', (tester) async {
    await configurarBancoFalso(logado: false);
    await tester.pumpWidget(const EduTurmasApp());

    expect(find.text('EduTurmas'), findsOneWidget);
    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'maria@escola.com');
    await tester.enterText(campos.at(1), senhaValida);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Maria'), findsOneWidget);
    expect(find.text('1 ativas'), findsOneWidget);
  });

  testWidgets('mostra erro com senha incorreta', (tester) async {
    await configurarBancoFalso(logado: false);
    await tester.pumpWidget(const EduTurmasApp());

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'maria@escola.com');
    await tester.enterText(campos.at(1), 'errada');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou senha incorretos'), findsOneWidget);
    expect(find.text('Olá, Maria'), findsNothing);
  });

  testWidgets('navega do painel até o gabarito e salva', (tester) async {
    final firestore = await configurarBancoFalso();
    await tester.pumpWidget(const EduTurmasApp(logado: true));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Maria'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.assignment_turned_in_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Avaliações recentes'), findsOneWidget);
    await tester.tap(find.text('Avaliação bimestral — Cap. 4'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da avaliação'), findsOneWidget);
    expect(find.text('22 ago. 2026'), findsOneWidget);
    await tester.tap(find.text('Configurar gabarito'));
    await tester.pumpAndSettle();

    // Troca a resposta da questão 1 de A para E.
    await tester.tap(find.text('E').first);
    await tester.tap(find.text('Salvar gabarito'));
    await tester.pumpAndSettle();

    expect(find.text('Gabarito salvo com sucesso'), findsOneWidget);
    final avaliacao = await firestore
        .collection('avaliacoes')
        .doc('aval-1')
        .get();
    expect(avaliacao.data()!['gabarito'][0]['alternativaCorreta'], 'E');
  });

  testWidgets('cadastra aluno na turma e atualiza o total', (tester) async {
    final firestore = await configurarBancoFalso();
    await tester.pumpWidget(
      const MaterialApp(home: ClassDetailScreen(turma: turma)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Beatriz'), findsOneWidget);
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Novo aluno(a)'), findsOneWidget);
    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'João da Silva');
    await tester.enterText(campos.at(1), '2026044');
    await tester.tap(find.text('Adicionar aluno'));
    await tester.pumpAndSettle();

    expect(find.text('João da Silva'), findsOneWidget);
    expect(find.text('Matrícula 2026044'), findsOneWidget);
    final turmaSalva = await firestore
        .collection('turmas')
        .doc('turma-1')
        .get();
    expect(turmaSalva.data()!['totalAlunos'], 3);
  });

  testWidgets('recusa matrícula repetida na turma', (tester) async {
    await configurarBancoFalso();
    await tester.pumpWidget(
      const MaterialApp(home: ClassDetailScreen(turma: turma)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'Outra Ana');
    await tester.enterText(campos.at(1), '2026041');
    await tester.tap(find.text('Adicionar aluno'));
    await tester.pumpAndSettle();

    expect(
      find.text('Já existe um aluno com a matrícula 2026041'),
      findsOneWidget,
    );
    expect(find.text('Outra Ana'), findsNothing);
  });
}
