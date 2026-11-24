import 'package:app_mobile/Screens/assessment_detail_screen.dart';
import 'package:app_mobile/components/badges/status_badge.dart';
import 'package:app_mobile/models/assessment.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:app_mobile/theme/app_colors.dart';
import 'package:app_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

void main() {
  group('AssessmentStatus - Padronização da Situação da Prova', () {
    test(
      'retorna rótulos no singular e plural corretos para cada situação',
      () {
        expect(AssessmentStatus.draft.label, 'Rascunho');
        expect(AssessmentStatus.draft.pluralLabel, 'Rascunhos');
        expect(AssessmentStatus.draft.isDraft, isTrue);
        expect(AssessmentStatus.draft.isScheduled, isFalse);
        expect(AssessmentStatus.draft.isCompleted, isFalse);

        expect(AssessmentStatus.scheduled.label, 'Agendada');
        expect(AssessmentStatus.scheduled.pluralLabel, 'Agendadas');
        expect(AssessmentStatus.scheduled.isScheduled, isTrue);

        expect(AssessmentStatus.completed.label, 'Concluída');
        expect(AssessmentStatus.completed.pluralLabel, 'Concluídas');
        expect(AssessmentStatus.completed.isCompleted, isTrue);
      },
    );

    test('retorna cores padronizadas no tema para cada situação', () {
      for (final c in [AppColors.light, AppColors.dark]) {
        expect(AssessmentStatus.draft.badgeBackground(c), c.neutralLight);
        expect(AssessmentStatus.draft.badgeForeground(c), c.muted);

        expect(AssessmentStatus.scheduled.badgeBackground(c), c.accentLight);
        expect(AssessmentStatus.scheduled.badgeForeground(c), c.accent);

        expect(AssessmentStatus.completed.badgeBackground(c), c.successLight);
        expect(AssessmentStatus.completed.badgeForeground(c), c.success);
      }
    });

    test('Assessment delega rótulo e situação para o status', () {
      const assessment = Assessment(
        title: 'Prova de Matemática',
        subject: 'Matemática',
        className: 'Turma A',
        dateLabel: '28 out. 2026',
        status: AssessmentStatus.scheduled,
        totalQuestions: 10,
        correctedStudents: 0,
        totalStudents: 25,
      );

      expect(assessment.statusLabel, 'Agendada');
      expect(assessment.situacao, 'Agendada');
      expect(assessment.isScheduled, isTrue);
      expect(assessment.isCompleted, isFalse);
    });

    testWidgets(
      'StatusBadge.assessment renderiza rótulo e cores padronizados',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusBadge.assessment(AssessmentStatus.completed),
            ),
          ),
        );

        expect(find.text('Concluída'), findsOneWidget);

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, AppColors.light.successLight);

        final text = tester.widget<Text>(find.text('Concluída'));
        expect(text.style?.color, AppColors.light.success);
      },
    );

    testWidgets('StatusBadge usa as cores do tema escuro', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: StatusBadge.assessment(AssessmentStatus.completed),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.dark.successLight);
      final text = tester.widget<Text>(find.text('Concluída'));
      expect(text.style?.color, AppColors.dark.success);
    });
  });

  group('Bloqueio de correção em prova encerrada (#71)', () {
    test('ResultadoRepository.salvar recusa correção de avaliação concluída com StateError', () async {
      await configurarBancoFalso();
      await AvaliacaoRepository().atualizarStatus('aval-1', AssessmentStatus.completed);
      final avaliacaoConcluida = await AvaliacaoRepository().buscar('aval-1');

      final aluno = (await AlunoRepository().listarPorTurma('turma-1')).first;

      expect(
        () => ResultadoRepository().salvar(
          avaliacao: avaliacaoConcluida,
          aluno: aluno,
          respostas: ['A', 'B', 'C', 'D'],
        ),
        throwsA(isA<StateError>()),
      );
    });

    testWidgets('AssessmentDetailScreen oculta botão de iniciar correção quando avaliação está concluída', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await configurarBancoFalso();
      await AvaliacaoRepository().atualizarStatus('aval-1', AssessmentStatus.completed);
      final avaliacaoConcluida = await AvaliacaoRepository().buscar('aval-1');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AssessmentDetailScreen(assessment: avaliacaoConcluida),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Iniciar correção'), findsNothing);
      expect(
        find.text('Avaliação encerrada. Não são permitidas novas correções.'),
        findsOneWidget,
      );
    });
  });
}
