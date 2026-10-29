import 'dart:convert';
import '../models/assessment.dart';

class CsvStudentRow {
  const CsvStudentRow({required this.nome, required this.matricula});

  final String nome;
  final String matricula;
}

class CsvStudentsResult {
  const CsvStudentsResult({required this.alunos, required this.erros});

  final List<CsvStudentRow> alunos;
  final List<String> erros;

  bool get temAlunos => alunos.isNotEmpty;
}

class CsvQuestionsResult {
  const CsvQuestionsResult({required this.questoes, required this.erros});

  final List<QuestaoGabarito> questoes;
  final List<String> erros;

  bool get temQuestoes => questoes.isNotEmpty;
}

abstract final class CsvImportService {
  /// Decodifica bytes como UTF-8 com fallback para Latin-1.
  static String decodeBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes).replaceFirst('\uFEFF', '');
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  /// Converte o conteúdo de um CSV em alunos.
  /// Aceita delimitador `,` ou `;` e cabeçalhos com `nome` e `matricula`.
  static CsvStudentsResult parseStudents(String content) {
    final lines = const LineSplitter().convert(content);
    final alunos = <CsvStudentRow>[];
    final erros = <String>[];
    final matriculas = <String>{};

    final firstIndex = lines.indexWhere((line) => line.trim().isNotEmpty);
    if (firstIndex == -1) {
      return const CsvStudentsResult(alunos: [], erros: ['O arquivo está vazio']);
    }

    final delimiter = _detectDelimiter(lines[firstIndex]);
    var nomeIndex = 0;
    var matriculaIndex = 1;
    var startIndex = firstIndex;

    final header = _splitLine(
      lines[firstIndex],
      delimiter,
    ).map(_normalizeHeader).toList();

    if (header.contains('nome')) {
      nomeIndex = header.indexOf('nome');
      matriculaIndex = header.indexOf('matricula');
      if (matriculaIndex == -1) {
        return const CsvStudentsResult(
          alunos: [],
          erros: ['Cabeçalho sem a coluna "matricula"'],
        );
      }
      startIndex = firstIndex + 1;
    }

    for (var i = startIndex; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;

      final lineNumber = i + 1;
      final fields = _splitLine(lines[i], delimiter);
      final nome = _fieldAt(fields, nomeIndex);
      final matricula = _fieldAt(fields, matriculaIndex);

      if (nome.isEmpty || matricula.isEmpty) {
        erros.add('Linha $lineNumber: nome ou matrícula ausente');
        continue;
      }
      if (!matriculas.add(matricula)) {
        erros.add('Linha $lineNumber: matrícula "$matricula" repetida no arquivo');
        continue;
      }
      alunos.add(CsvStudentRow(nome: nome, matricula: matricula));
    }

    return CsvStudentsResult(alunos: alunos, erros: erros);
  }

  /// Converte o conteúdo de um CSV em questões/gabarito de prova.
  /// Colunas suportadas:
  /// - `questao` (ou `numero`)
  /// - `resposta` (ou `alternativa`, `gabarito`, `correta`)
  /// - `peso` (opcional, padrão 1.0)
  static CsvQuestionsResult parseQuestions(String content) {
    final lines = const LineSplitter().convert(content);
    final questoes = <QuestaoGabarito>[];
    final erros = <String>[];
    final numerosQuestoes = <int>{};

    final firstIndex = lines.indexWhere((line) => line.trim().isNotEmpty);
    if (firstIndex == -1) {
      return const CsvQuestionsResult(
        questoes: [],
        erros: ['O arquivo está vazio'],
      );
    }

    final delimiter = _detectDelimiter(lines[firstIndex]);
    var questaoIndex = 0;
    var respostaIndex = 1;
    var pesoIndex = -1;
    var startIndex = firstIndex;

    final header = _splitLine(
      lines[firstIndex],
      delimiter,
    ).map(_normalizeHeader).toList();

    final temCabecalho = header.any(
      (h) => h.contains('questao') || h.contains('numero') || h.contains('resposta') || h.contains('gabarito'),
    );

    if (temCabecalho) {
      questaoIndex = header.indexWhere((h) => h.contains('questao') || h.contains('numero'));
      if (questaoIndex == -1) questaoIndex = 0;

      respostaIndex = header.indexWhere(
        (h) => h.contains('resposta') || h.contains('alternativa') || h.contains('gabarito') || h.contains('correta'),
      );
      if (respostaIndex == -1) {
        return const CsvQuestionsResult(
          questoes: [],
          erros: ['Cabeçalho sem coluna de resposta ou gabarito'],
        );
      }

      pesoIndex = header.indexWhere((h) => h.contains('peso'));
      startIndex = firstIndex + 1;
    }

    for (var i = startIndex; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;

      final lineNumber = i + 1;
      final fields = _splitLine(lines[i], delimiter);

      final questaoStr = _fieldAt(fields, questaoIndex);
      final respostaStr = _fieldAt(fields, respostaIndex).toUpperCase();
      final pesoStr = pesoIndex != -1 ? _fieldAt(fields, pesoIndex) : '';

      final numQuestao = int.tryParse(questaoStr);
      if (numQuestao == null || numQuestao <= 0) {
        erros.add('Linha $lineNumber: número de questão inválido ("$questaoStr")');
        continue;
      }

      if (!numerosQuestoes.add(numQuestao)) {
        erros.add('Linha $lineNumber: questão $numQuestao duplicada no arquivo');
        continue;
      }

      if (respostaStr.isNotEmpty && !RegExp(r'^[A-E]$').hasMatch(respostaStr)) {
        erros.add('Linha $lineNumber: alternativa "$respostaStr" inválida (use de A a E)');
        continue;
      }

      var peso = 1.0;
      if (pesoStr.isNotEmpty) {
        final parsedPeso = double.tryParse(pesoStr.replaceAll(',', '.'));
        if (parsedPeso == null || parsedPeso <= 0) {
          erros.add('Linha $lineNumber: peso "$pesoStr" inválido (deve ser um número positivo)');
          continue;
        }
        peso = parsedPeso;
      }

      questoes.add(
        QuestaoGabarito(
          questao: numQuestao,
          alternativaCorreta: respostaStr.isEmpty ? null : respostaStr,
          peso: peso,
        ),
      );
    }

    // Ordena as questões por número
    questoes.sort((a, b) => a.questao.compareTo(b.questao));

    return CsvQuestionsResult(questoes: questoes, erros: erros);
  }

  static String _detectDelimiter(String line) {
    final pontoEVirgula = _splitLine(line, ';').length;
    final virgula = _splitLine(line, ',').length;
    return pontoEVirgula > virgula ? ';' : ',';
  }

  static String _fieldAt(List<String> fields, int index) =>
      index >= 0 && index < fields.length ? fields[index].trim() : '';

  static String _normalizeHeader(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('í', 'i')
      .replaceAll('á', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('ç', 'c');

  static List<String> _splitLine(String line, String delimiter) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == delimiter && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    fields.add(buffer.toString());
    return fields;
  }
}
