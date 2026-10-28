import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

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

class CsvImportResult {
  const CsvImportResult({required this.alunos, required this.erros});

  final List<CsvStudentRow> alunos;
  final List<String> erros;
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

  /// Decodifica como UTF-8 e recorre a Latin-1, formato comum em CSVs
  /// exportados pelo Excel em pt-BR.
  static String decodeBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes).replaceFirst('﻿', '');
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  /// Converte o CSV em alunos. Aceita `,` ou `;` como separador e um
  /// cabeçalho opcional com as colunas `nome` e `matricula`.
  static CsvImportResult parseStudents(String content) {
    final lines = const LineSplitter().convert(content);
    final alunos = <CsvStudentRow>[];
    final erros = <String>[];
    final matriculas = <String>{};

    final firstIndex = lines.indexWhere((line) => line.trim().isNotEmpty);
    if (firstIndex == -1) {
      return CsvImportResult(alunos: alunos, erros: ['O arquivo está vazio']);
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
        return CsvImportResult(
          alunos: alunos,
          erros: ['Cabeçalho sem a coluna "matricula"'],
        );
      }
      startIndex = firstIndex + 1;
    }

    for (var i = startIndex; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) {
        continue;
      }
      final lineNumber = i + 1;
      final fields = _splitLine(lines[i], delimiter);
      final nome = _fieldAt(fields, nomeIndex);
      final matricula = _fieldAt(fields, matriculaIndex);

      if (nome.isEmpty || matricula.isEmpty) {
        erros.add('Linha $lineNumber: nome ou matrícula ausente');
        continue;
      }
      if (!matriculas.add(matricula)) {
        erros.add('Linha $lineNumber: matrícula $matricula repetida');
        continue;
      }
      alunos.add(CsvStudentRow(nome: nome, matricula: matricula));
    }

    return CsvImportResult(alunos: alunos, erros: erros);
  }

  static String _detectDelimiter(String line) {
    return _splitLine(line, ';').length > _splitLine(line, ',').length
        ? ';'
        : ',';
  }

  static String _fieldAt(List<String> fields, int index) =>
      index < fields.length ? fields[index].trim() : '';

  static String _normalizeHeader(String value) =>
      value.trim().toLowerCase().replaceAll('í', 'i').replaceAll('á', 'a');

  /// Divide uma linha respeitando campos entre aspas (`"Silva, Ana"`) e
  /// aspas escapadas (`""`).
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
