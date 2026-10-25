import 'dart:convert';

import 'package:app_mobile/components/inputs/csv_file_picker.dart';
import 'package:app_mobile/services/csv_import_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsvImportService.parseStudents', () {
    test('lê cabeçalho com ponto e vírgula e acento', () {
      final result = CsvImportService.parseStudents(
        'Nome;Matrícula\nAna Souza;2026050\nBruno Lima;2026051\n',
      );

      expect(result.erros, isEmpty);
      expect(result.alunos.map((a) => a.nome), ['Ana Souza', 'Bruno Lima']);
      expect(result.alunos.first.matricula, '2026050');
    });

    test('aceita arquivo sem cabeçalho, com vírgula e aspas', () {
      final result = CsvImportService.parseStudents(
        '"Silva, Ana";2026060\r\nCarlos,2026061',
      );

      expect(result.alunos.first.nome, 'Silva, Ana');
      expect(result.alunos.length, 1);
      expect(result.erros, ['Linha 2: nome ou matrícula ausente']);
    });

    test('respeita a ordem das colunas do cabeçalho', () {
      final result = CsvImportService.parseStudents(
        'matricula,nome\n2026070,Diana Reis',
      );

      expect(result.alunos.single.nome, 'Diana Reis');
      expect(result.alunos.single.matricula, '2026070');
    });

    test('ignora linhas vazias e aponta matrículas repetidas', () {
      final result = CsvImportService.parseStudents(
        'nome,matricula\nAna,1\n\nBia,1\n',
      );

      expect(result.alunos.length, 1);
      expect(result.erros, ['Linha 4: matrícula 1 repetida']);
    });

    test('rejeita cabeçalho sem matrícula', () {
      final result = CsvImportService.parseStudents('nome,email\nAna,a@x.com');

      expect(result.alunos, isEmpty);
      expect(result.erros.single, contains('matricula'));
    });
  });

  test('decodeBytes remove BOM e recorre a Latin-1', () {
    final utf8Bom = [0xEF, 0xBB, 0xBF, ...utf8.encode('João')];
    expect(CsvImportService.decodeBytes(utf8Bom), 'João');
    expect(CsvImportService.decodeBytes(latin1.encode('João')), 'João');
  });

  testWidgets('CsvFilePicker mostra o arquivo selecionado e permite remover', (
    tester,
  ) async {
    CsvFile? selecionado;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CsvFilePicker(
            picker: () async => const CsvFile(
              name: 'alunos.csv',
              sizeInBytes: 2048,
              content: 'nome,matricula',
            ),
            onChanged: (file) => selecionado = file,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Selecionar arquivo CSV'));
    await tester.pumpAndSettle();

    expect(find.text('alunos.csv'), findsOneWidget);
    expect(find.text('2.0 KB'), findsOneWidget);
    expect(selecionado?.name, 'alunos.csv');

    await tester.tap(find.byTooltip('Remover arquivo'));
    await tester.pumpAndSettle();

    expect(find.text('Selecionar arquivo CSV'), findsOneWidget);
    expect(selecionado, isNull);
  });

  testWidgets('CsvFilePicker exibe erro de arquivo inválido', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CsvFilePicker(
            picker: () async =>
                throw const CsvImportException('O arquivo está vazio'),
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Selecionar arquivo CSV'));
    await tester.pumpAndSettle();

    expect(find.text('O arquivo está vazio'), findsOneWidget);
  });
}
