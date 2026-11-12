import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Executa [task] exibindo um loader modal que bloqueia a tela até a
/// operação terminar (com sucesso ou erro). Erros são repassados a quem
/// chamou, que continua responsável por tratá-los.
///
/// Use para ações disparadas a partir de diálogos, menus ou bottom sheets,
/// onde não há um botão na tela para exibir o estado de carregamento.
Future<T> runWithLoader<T>(
  BuildContext context,
  Future<T> Function() task, {
  String? message,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var aberto = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: LoadingDialog(message: message),
    ),
  ).whenComplete(() => aberto = false);

  try {
    return await task();
  } finally {
    if (aberto) navigator.pop();
  }
}

/// Caixa com spinner e mensagem opcional, exibida por [runWithLoader].
class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: context.colors.accent,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 14),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
