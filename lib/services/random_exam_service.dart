import 'dart:math';

import '../models/assessment.dart';

/// Uma variante gerada de forma randômica a partir de uma avaliação base.
class RandomizedExamVariant {
  const RandomizedExamVariant({
    required this.variantLabel,
    required this.originalAssessment,
    required this.questoes,
    required this.mapaQuestoes,
  });

  /// Identificador da variante (ex.: "Tipo A", "Tipo B").
  final String variantLabel;

  /// Avaliação original que originou esta variante.
  final Assessment originalAssessment;

  /// Questões na nova ordem sorteada, com a numeração sequencial ajustada (1, 2, ... N)
  /// e o gabarito correspondente.
  final List<QuestaoGabarito> questoes;

  /// Mapeia o número da questão original para o número nesta variante.
  /// Exemplo: `{1: 3}` significa que a Questão 1 original virou a Questão 3 nesta prova.
  final Map<int, int> mapaQuestoes;

  /// Retorna o gabarito em formato legível de texto (ex.: "1-B, 2-A, 3-D").
  String get gabaritoResumido => questoes
      .map((q) => '${q.questao}-${q.alternativaCorreta ?? "?"}')
      .join(', ');

  /// Gera a prévia textual estruturada para montagem e exportação do PDF da prova.
  String gerarLayoutProvaPdf() {
    final buffer = StringBuffer();
    buffer.writeln('========================================================');
    buffer.writeln('                AVALIAÇÃO ESCOLAR - ${variantLabel.toUpperCase()}');
    buffer.writeln('========================================================');
    buffer.writeln('Turma: ${originalAssessment.className}');
    buffer.writeln('Disciplina: ${originalAssessment.subject}');
    buffer.writeln('Prova: ${originalAssessment.title}');
    buffer.writeln('Data de Aplicação: ${originalAssessment.dateLabel}');
    buffer.writeln('Aluno(a): _____________________________________________');
    buffer.writeln('Matrícula: __________________   Data: ____/____/________');
    buffer.writeln('--------------------------------------------------------');
    buffer.writeln('INSTRUÇÕES:');
    buffer.writeln('1. Esta prova é a $variantLabel.');
    buffer.writeln('2. Responda às questões com caneta azul ou preta.');
    buffer.writeln('3. Preencha o cartão de respostas ao final.');
    buffer.writeln('--------------------------------------------------------\n');

    for (final questao in questoes) {
      final originalNum = mapaQuestoes.entries
          .firstWhere((e) => e.value == questao.questao, orElse: () => MapEntry(questao.questao, questao.questao))
          .key;
      buffer.writeln('Questão ${questao.questao} (Peso: ${questao.peso.toStringAsFixed(1)}):');
      buffer.writeln('  [Enunciado da questão original #$originalNum]');
      buffer.writeln('  ( ) A    ( ) B    ( ) C    ( ) D    ( ) E\n');
    }

    buffer.writeln('--------------------------------------------------------');
    buffer.writeln('                  FOLHA DE RESPOSTAS');
    buffer.writeln('--------------------------------------------------------');
    for (var i = 0; i < questoes.length; i += 5) {
      final fim = min(i + 5, questoes.length);
      final sub = questoes.sublist(i, fim);
      buffer.writeln(
        sub.map((q) => '${q.questao}: [A][B][C][D][E]').join('   '),
      );
    }
    buffer.writeln('========================================================');
    return buffer.toString();
  }

  /// Gera a folha de gabarito para uso exclusivo do professor.
  String gerarGabaritoPdf() {
    final buffer = StringBuffer();
    buffer.writeln('GABARITO DO PROFESSOR - ${variantLabel.toUpperCase()}');
    buffer.writeln('Prova: ${originalAssessment.title} (${originalAssessment.className})');
    buffer.writeln('Data: ${originalAssessment.dateLabel}');
    buffer.writeln('--------------------------------------------------------');
    for (final q in questoes) {
      buffer.writeln(
        'Questão ${q.questao}: Alternativa ${q.alternativaCorreta ?? "-"} (Peso: ${q.peso})',
      );
    }
    return buffer.toString();
  }
}

abstract final class RandomExamService {
  /// Gera [quantidade] variantes da avaliação com as questões embaralhadas de forma randômica.
  /// Um [seed] opcional pode ser fornecido para garantir reprodutibilidade.
  static List<RandomizedExamVariant> gerarVariantes({
    required Assessment assessment,
    int quantidade = 2,
    int? seed,
  }) {
    if (quantidade <= 0) return [];

    final random = seed != null ? Random(seed) : Random();
    final letras = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final variantes = <RandomizedExamVariant>[];

    final questoesOriginais = [...assessment.gabarito];
    if (questoesOriginais.isEmpty) {
      // Se a avaliação ainda não tem questões no gabarito, cria lista sequencial
      for (var i = 1; i <= assessment.totalQuestions; i++) {
        questoesOriginais.add(QuestaoGabarito(questao: i));
      }
    }

    for (var i = 0; i < quantidade; i++) {
      final label = 'Tipo ${i < letras.length ? letras[i] : (i + 1).toString()}';
      final embaralhadas = [...questoesOriginais]..shuffle(random);

      final novasQuestoes = <QuestaoGabarito>[];
      final mapa = <int, int>{}; // original -> nova

      for (var novoIdx = 0; novoIdx < embaralhadas.length; novoIdx++) {
        final original = embaralhadas[novoIdx];
        final novaQuestaoNum = novoIdx + 1;
        mapa[original.questao] = novaQuestaoNum;

        novasQuestoes.add(
          QuestaoGabarito(
            questao: novaQuestaoNum,
            alternativaCorreta: original.alternativaCorreta,
            peso: original.peso,
          ),
        );
      }

      variantes.add(
        RandomizedExamVariant(
          variantLabel: label,
          originalAssessment: assessment,
          questoes: novasQuestoes,
          mapaQuestoes: mapa,
        ),
      );
    }

    return variantes;
  }
}
