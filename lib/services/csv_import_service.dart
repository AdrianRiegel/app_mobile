import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/assessment.dart';
import '../models/question.dart';

/// Arquivo CSV selecionado pelo usuário, já decodificado como texto.
class CsvFile {
  const CsvFile({
    required this.name,
    required this.sizeInBytes,
    required this.content,
  });

  final String name;
  final int sizeInBytes;
  final String content;

  String get sizeLabel {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    }
    return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
  }
}

/// Erro de seleção/leitura com mensagem pronta para exibir ao usuário.
class CsvImportException implements Exception {
  const CsvImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

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

/// Questões completas (enunciado e alternativas) lidas de um CSV.
class CsvProofQuestionsResult {
  const CsvProofQuestionsResult({required this.questoes, required this.erros});

  final List<Question> questoes;
  final List<String> erros;

  bool get temQuestoes => questoes.isNotEmpty;
}

abstract final class CsvImportService {
  static const int maxSizeInBytes = 1024 * 1024;

  /// Abre o seletor nativo de arquivos restrito a `.csv`.
  ///
  /// Retorna `null` se o usuário cancelar e lança [CsvImportException] se o
  /// arquivo for inválido.
  static Future<CsvFile?> pickCsvFile() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Selecione o arquivo CSV',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (file == null) {
      return null;
    }

    if (file.extension?.toLowerCase() != 'csv') {
      throw const CsvImportException('Selecione um arquivo com extensão .csv');
    }

    final knownSize = file.lengthSync();
    if (knownSize != null && knownSize > maxSizeInBytes) {
      throw const CsvImportException('O arquivo excede o limite de 1 MB');
    }

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      throw const CsvImportException('Não foi possível ler o arquivo');
    }

    if (bytes.length > maxSizeInBytes) {
      throw const CsvImportException('O arquivo excede o limite de 1 MB');
    }

    final content = decodeBytes(bytes);
    if (content.trim().isEmpty) {
      throw const CsvImportException('O arquivo selecionado está vazio');
    }

    return CsvFile(
      name: file.name,
      sizeInBytes: bytes.length,
      content: content,
    );
  }

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
      return const CsvStudentsResult(
        alunos: [],
        erros: ['O arquivo está vazio'],
      );
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
        erros.add(
          'Linha $lineNumber: matrícula "$matricula" repetida no arquivo',
        );
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
      (h) =>
          h.contains('questao') ||
          h.contains('numero') ||
          h.contains('resposta') ||
          h.contains('gabarito'),
    );

    if (temCabecalho) {
      questaoIndex = header.indexWhere(
        (h) => h.contains('questao') || h.contains('numero'),
      );
      if (questaoIndex == -1) questaoIndex = 0;

      respostaIndex = header.indexWhere(
        (h) =>
            h.contains('resposta') ||
            h.contains('alternativa') ||
            h.contains('gabarito') ||
            h.contains('correta'),
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
        erros.add(
          'Linha $lineNumber: número de questão inválido ("$questaoStr")',
        );
        continue;
      }

      if (!numerosQuestoes.add(numQuestao)) {
        erros.add(
          'Linha $lineNumber: questão $numQuestao duplicada no arquivo',
        );
        continue;
      }

      if (respostaStr.isNotEmpty && !RegExp(r'^[A-E]$').hasMatch(respostaStr)) {
        erros.add(
          'Linha $lineNumber: alternativa "$respostaStr" inválida (use de A a E)',
        );
        continue;
      }

      var peso = 1.0;
      if (pesoStr.isNotEmpty) {
        final parsedPeso = double.tryParse(pesoStr.replaceAll(',', '.'));
        if (parsedPeso == null || parsedPeso <= 0) {
          erros.add(
            'Linha $lineNumber: peso "$pesoStr" inválido (deve ser um número positivo)',
          );
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

  /// Colunas esperadas em [parseProofQuestions], na ordem sem cabeçalho.
  static const proofQuestionsColumns = 'enunciado;a;b;c;d;correta';

  /// Converte um CSV em questões completas de prova, com 4 ou 5 alternativas.
  ///
  /// Com cabeçalho, as colunas podem vir em qualquer ordem: `enunciado` (ou
  /// `pergunta`), `a`, `b`, `c`, `d` (ou `alternativa a`, `opção a`...) e
  /// `correta` (ou `resposta`, `gabarito`); a coluna `e` é opcional e, quando
  /// preenchida, vira a 5ª alternativa. Sem cabeçalho, vale a ordem de
  /// [proofQuestionsColumns], ou `enunciado;a;b;c;d;e;correta` em linhas com
  /// 7 colunas. A correta é a letra de uma das alternativas da linha.
  static CsvProofQuestionsResult parseProofQuestions(String content) {
    final lines = const LineSplitter().convert(content);
    final questoes = <Question>[];
    final erros = <String>[];

    final firstIndex = lines.indexWhere((line) => line.trim().isNotEmpty);
    if (firstIndex == -1) {
      return const CsvProofQuestionsResult(
        questoes: [],
        erros: ['O arquivo está vazio'],
      );
    }

    final delimiter = _detectDelimiter(lines[firstIndex]);
    final header = _splitLine(
      lines[firstIndex],
      delimiter,
    ).map(_normalizeHeader).toList();

    var enunciadoIndex = 0;
    var alternativasIndex = [1, 2, 3, 4];
    var corretaIndex = 5;
    var quintaIndex = -1; // coluna `e` opcional
    var comCabecalho = false;
    var startIndex = firstIndex;

    final cabecalhoEnunciado = header.indexWhere(
      (h) => h.contains('enunciado') || h.contains('pergunta'),
    );
    if (cabecalhoEnunciado != -1) {
      enunciadoIndex = cabecalhoEnunciado;
      alternativasIndex = [
        for (final letra in ['a', 'b', 'c', 'd'])
          header.indexWhere((h) => _letraDaColuna(h) == letra),
      ];
      quintaIndex = header.indexWhere((h) => _letraDaColuna(h) == 'e');
      comCabecalho = true;
      corretaIndex = header.indexWhere(
        (h) =>
            h.contains('correta') ||
            h.contains('resposta') ||
            h.contains('gabarito'),
      );
      if (alternativasIndex.contains(-1) || corretaIndex == -1) {
        return const CsvProofQuestionsResult(
          questoes: [],
          erros: [
            'Cabeçalho deve ter as colunas enunciado, a, b, c, d e correta',
          ],
        );
      }
      startIndex = firstIndex + 1;
    }

    for (var i = startIndex; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;

      final lineNumber = i + 1;
      final fields = _splitLine(lines[i], delimiter);
      final enunciado = _fieldAt(fields, enunciadoIndex);
      final alternativas = [
        for (final index in alternativasIndex) _fieldAt(fields, index),
      ];
      // 5ª alternativa: coluna `e` do cabeçalho ou 7 colunas sem cabeçalho.
      final linhaCom5 = !comCabecalho && fields.length >= 7;
      final quinta = comCabecalho
          ? (quintaIndex == -1 ? '' : _fieldAt(fields, quintaIndex))
          : (linhaCom5 ? _fieldAt(fields, 5) : '');
      if (quinta.isNotEmpty) alternativas.add(quinta);
      final correta = _fieldAt(
        fields,
        linhaCom5 ? 6 : corretaIndex,
      ).toUpperCase();
      final ultimaLetra = String.fromCharCode(64 + alternativas.length);

      if (enunciado.isEmpty) {
        erros.add('Linha $lineNumber: enunciado vazio');
        continue;
      }
      if (alternativas.any((alternativa) => alternativa.isEmpty)) {
        erros.add('Linha $lineNumber: preencha as 4 alternativas');
        continue;
      }
      if (!RegExp('^[A-$ultimaLetra]\$').hasMatch(correta)) {
        erros.add(
          'Linha $lineNumber: alternativa correta "$correta" inválida '
          '(use ${alternativas.length == 5 ? 'A, B, C, D ou E' : 'A, B, C ou D'})',
        );
        continue;
      }

      questoes.add(
        Question(
          statement: enunciado,
          options: alternativas,
          correctIndex: correta.codeUnitAt(0) - 65,
        ),
      );
    }

    return CsvProofQuestionsResult(questoes: questoes, erros: erros);
  }

  /// `a`, `alternativa a`, `alternativa_a`, `opcao a` → `a`; senão `null`.
  static String? _letraDaColuna(String header) {
    final letra = header
        .replaceAll('alternativa', '')
        .replaceAll('opcao', '')
        .replaceAll(RegExp(r'[\s_\-]'), '');
    return RegExp(r'^[a-e]$').hasMatch(letra) ? letra : null;
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
