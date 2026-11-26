import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../theme/app_colors.dart';
import '../navigation/standard_app_bar.dart';

/// Tela em tela cheia para visualizar, ampliar, imprimir ou compartilhar um PDF.
class PdfPreviewPage extends StatelessWidget {
  const PdfPreviewPage({
    super.key,
    required this.title,
    required this.fileName,
    required this.bytes,
  });

  final String title;
  final String fileName;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: StandardAppBar(title: title),
      body: SafeArea(
        top: false,
        child: PdfPreview(
          build: (_) async => bytes,
          pdfFileName: fileName,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          allowPrinting: true,
          allowSharing: true,
          loadingWidget: Center(
            child: CircularProgressIndicator(color: colors.accent),
          ),
          scrollViewDecoration: BoxDecoration(color: colors.background),
          actionBarTheme: PdfActionBarTheme(
            backgroundColor: colors.surface,
            iconColor: colors.accent,
          ),
          onError: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Não foi possível renderizar a prévia do PDF neste dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.muted, fontSize: 13),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
