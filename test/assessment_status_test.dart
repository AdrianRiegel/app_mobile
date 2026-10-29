import 'package:app_mobile/components/badges/status_badge.dart';
import 'package:app_mobile/models/assessment.dart';
import 'package:app_mobile/theme/app_colors.dart';
import 'package:app_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
