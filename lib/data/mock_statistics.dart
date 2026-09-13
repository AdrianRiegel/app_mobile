import '../models/statistics.dart';

/// Dados simulados para as telas de Estatísticas e Relatórios.
///
/// Os percentuais foram escolhidos apenas para demonstrar a interface e a
/// navegação da primeira entrega — não há cálculo real de correções.
final List<ClassStatistics> mockClassStatistics = [
  ClassStatistics(
    className: '3º Ano A',
    subject: 'Matemática',
    exams: [
      ExamStatistics(
        assessmentTitle: 'Avaliação bimestral — Cap. 4',
        shortLabel: 'Cap. 4',
        className: '3º Ano A',
        subject: 'Matemática',
        averageScore: 76,
        hardestQuestion: 'Q7',
        questions: const [
          QuestionStat(number: 1, correctRate: 92),
          QuestionStat(number: 2, correctRate: 80),
          QuestionStat(number: 3, correctRate: 66),
          QuestionStat(number: 4, correctRate: 88),
          QuestionStat(number: 5, correctRate: 58),
          QuestionStat(number: 6, correctRate: 74),
          QuestionStat(number: 7, correctRate: 38),
          QuestionStat(number: 8, correctRate: 90),
          QuestionStat(number: 9, correctRate: 82),
          QuestionStat(number: 10, correctRate: 92),
        ],
      ),
      ExamStatistics(
        assessmentTitle: 'Prova mensal — Cap. 3',
        shortLabel: 'Cap. 3',
        className: '3º Ano A',
        subject: 'Matemática',
        averageScore: 82,
        hardestQuestion: 'Q5',
        questions: const [
          QuestionStat(number: 1, correctRate: 95),
          QuestionStat(number: 2, correctRate: 88),
          QuestionStat(number: 3, correctRate: 74),
          QuestionStat(number: 4, correctRate: 90),
          QuestionStat(number: 5, correctRate: 70),
          QuestionStat(number: 6, correctRate: 85),
          QuestionStat(number: 7, correctRate: 72),
          QuestionStat(number: 8, correctRate: 82),
        ],
      ),
    ],
  ),
  ClassStatistics(
    className: '2º Ano B',
    subject: 'Física',
    exams: [
      ExamStatistics(
        assessmentTitle: 'Prova mensal — Cinemática',
        shortLabel: 'Cinemática',
        className: '2º Ano B',
        subject: 'Física',
        averageScore: 68,
        hardestQuestion: 'Q7',
        questions: const [
          QuestionStat(number: 1, correctRate: 78),
          QuestionStat(number: 2, correctRate: 70),
          QuestionStat(number: 3, correctRate: 55),
          QuestionStat(number: 4, correctRate: 82),
          QuestionStat(number: 5, correctRate: 60),
          QuestionStat(number: 6, correctRate: 74),
          QuestionStat(number: 7, correctRate: 50),
          QuestionStat(number: 8, correctRate: 75),
        ],
      ),
    ],
  ),
];
