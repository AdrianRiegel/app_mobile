import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Salva os prints tirados pelo teste em build/integration_screenshots/.
Future<void> main() => integrationDriver(
  onScreenshot: (nome, bytes, [args]) async {
    final arquivo = File('build/integration_screenshots/$nome.png');
    await arquivo.create(recursive: true);
    await arquivo.writeAsBytes(bytes);
    return true;
  },
);
