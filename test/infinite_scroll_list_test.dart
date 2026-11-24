import 'package:app_mobile/components/components.dart';
import 'package:app_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _lista({
  required int total,
  double alturaItem = 60,
  double loadThreshold = 200,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: InfiniteScrollList(
        pageSize: 10,
        loadThreshold: loadThreshold,
        itemCount: total,
        itemBuilder: (context, index) =>
            SizedBox(height: alturaItem, child: Text('Item $index')),
      ),
    ),
  );
}

/// Inclui a área pré-montada logo abaixo da tela, onde fica o rodapé.
Finder get _carregando =>
    find.byType(CircularProgressIndicator, skipOffstage: false);

void main() {
  testWidgets('monta só o primeiro lote e carrega mais ao rolar', (
    tester,
  ) async {
    await tester.pumpWidget(_lista(total: 35));
    await tester.pump();

    // Lote de 10 itens de 60px (+ espaçamento) já passa da tela de 600px.
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 10'), findsNothing);

    await tester.scrollUntilVisible(find.text('Item 34'), 300);
    await tester.pumpAndSettle();
    expect(find.text('Item 34'), findsOneWidget);
    expect(_carregando, findsNothing);
  });

  testWidgets('mostra indicador no rodapé enquanto há mais itens', (
    tester,
  ) async {
    // Limite mínimo: só carrega ao encostar no fim, então o indicador fica
    // montado logo abaixo do primeiro lote.
    // O spinner gira sem parar: usa pump com tempo fixo, não pumpAndSettle.
    await tester.pumpWidget(_lista(total: 35, loadThreshold: 1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Item 10'), findsNothing);
    expect(_carregando, findsOneWidget);

    await tester.drag(find.byType(Scrollable), const Offset(0, -1000));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Item 10'), findsOneWidget);
  });

  testWidgets('carrega mais sozinho quando o lote não enche a tela', (
    tester,
  ) async {
    // 10 itens de 10px não enchem 600px: os próximos lotes vêm sem rolagem.
    await tester.pumpWidget(_lista(total: 25, alturaItem: 10));
    await tester.pumpAndSettle();
    expect(find.text('Item 24'), findsOneWidget);
    expect(_carregando, findsNothing);
  });

  testWidgets('lista menor que um lote não mostra indicador', (tester) async {
    await tester.pumpWidget(_lista(total: 3));
    await tester.pumpAndSettle();
    expect(find.text('Item 2'), findsOneWidget);
    expect(_carregando, findsNothing);
  });
}
