import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../theme/app_colors.dart';

/// Tela de visualização e compartilhamento de PDF gerado (Relatórios e Provas).
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
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: context.colors.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.text),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar PDF',
            onPressed: () async {
              await Printing.sharePdf(bytes: bytes, filename: fileName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir',
            onPressed: () async {
              await Printing.layoutPdf(
                name: fileName,
                onLayout: (_) async => bytes,
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => bytes,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: fileName,
        loadingWidget: Center(
          child: CircularProgressIndicator(color: context.colors.accent),
        ),
      ),
    );
  }
}
