import '../models/assessment.dart';

const List<Assessment> mockAssessments = [
  Assessment(
    title: 'Avaliação bimestral — Cap. 4',
    subject: 'Matemática',
    className: '3º Ano A',
    dateLabel: '22 ago. 2026',
    status: AssessmentStatus.scheduled,
    totalQuestions: 10,
    correctedStudents: 0,
    totalStudents: 28,
  ),
  Assessment(
    title: 'Prova mensal — Cinemática',
    subject: 'Física',
    className: '2º Ano B',
    dateLabel: '15 jul. 2026',
    status: AssessmentStatus.completed,
    totalQuestions: 8,
    correctedStudents: 24,
    totalStudents: 24,
  ),
  Assessment(
    title: 'Recuperação — Ligações químicas',
    subject: 'Química',
    className: '1º Ano C',
    dateLabel: 'Sem data',
    status: AssessmentStatus.draft,
    totalQuestions: 5,
    correctedStudents: 0,
    totalStudents: 31,
  ),
];
