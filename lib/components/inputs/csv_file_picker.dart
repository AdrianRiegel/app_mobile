import 'package:flutter/material.dart';

import '../../services/csv_import_service.dart';
import '../../theme/app_colors.dart';

/// Área de seleção de um documento CSV.
///
/// Abre o seletor nativo restrito a `.csv`, mostra o arquivo escolhido (com
/// opção de trocar ou remover) e informa erros de leitura.
class CsvFilePicker extends StatefulWidget {
  const CsvFilePicker({
    super.key,
    required this.onChanged,
    this.picker = CsvImportService.pickCsvFile,
    this.hint = 'Formato: nome;matricula',
  });

  /// Chamado com o arquivo selecionado, ou `null` quando ele é removido.
  final ValueChanged<CsvFile?> onChanged;

  /// Permite substituir o seletor nativo (ex.: em testes).
  final Future<CsvFile?> Function() picker;

  final String hint;

  @override
  State<CsvFilePicker> createState() => _CsvFilePickerState();
}

class _CsvFilePickerState extends State<CsvFilePicker> {
  CsvFile? _file;
  String? _error;
  bool _loading = false;

  Future<void> _pick() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final file = await widget.picker();
      if (!mounted || file == null) {
        return;
      }
      setState(() => _file = file);
      widget.onChanged(file);
    } on CsvImportException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível abrir o seletor de arquivos');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _clear() {
    setState(() {
      _file = null;
      _error = null;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _file == null ? _buildEmpty() : _buildSelected(_file!),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 14,
                color: context.colors.danger,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _error!,
                  style: TextStyle(fontSize: 11, color: context.colors.danger),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEmpty() {
    return Material(
      color: context.colors.input,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _loading ? null : _pick,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          decoration: BoxDecoration(
            border: Border.all(
              color: _error != null ? context.colors.danger : context.colors.border,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: _loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.accent,
                        ),
                      )
                    : Icon(
                        Icons.upload_file_outlined,
                        size: 20,
                        color: context.colors.accent,
                      ),
              ),
              const SizedBox(height: 10),
              Text(
                'Selecionar arquivo CSV',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.hint,
                style: TextStyle(fontSize: 11, color: context.colors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelected(CsvFile file) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.colors.successLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.description_outlined,
              size: 18,
              color: context.colors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  file.sizeLabel,
                  style: TextStyle(fontSize: 11, color: context.colors.muted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _loading ? null : _pick,
            style: TextButton.styleFrom(
              foregroundColor: context.colors.accent,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Trocar'),
          ),
          IconButton(
            tooltip: 'Remover arquivo',
            onPressed: _loading ? null : _clear,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 18, color: context.colors.muted),
          ),
        ],
      ),
    );
  }
}
