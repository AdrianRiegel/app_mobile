import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Lista com rolagem infinita: exibe os itens em lotes de [pageSize] e
/// revela o próximo lote quando o usuário se aproxima do fim da lista.
///
/// Os itens já estão em memória; o lote só limita quantos são montados por
/// vez. Para recomeçar do primeiro lote (ex.: ao mudar a busca), troque a
/// `key` do widget.
class InfiniteScrollList extends StatefulWidget {
  const InfiniteScrollList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.pageSize = 15,
    this.header = const [],
    this.padding = EdgeInsets.zero,
    this.spacing = 8,
    this.loadThreshold = 200,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int pageSize;

  /// Widgets exibidos antes dos itens, rolando junto com a lista.
  final List<Widget> header;
  final EdgeInsetsGeometry padding;

  /// Espaço vertical entre os itens.
  final double spacing;

  /// Distância do fim da lista (em pixels) que dispara o próximo lote.
  final double loadThreshold;

  @override
  State<InfiniteScrollList> createState() => _InfiniteScrollListState();
}

class _InfiniteScrollListState extends State<InfiniteScrollList> {
  final _controller = ScrollController();
  late int _limite = widget.pageSize;

  int get _visiveis =>
      _limite < widget.itemCount ? _limite : widget.itemCount;

  bool get _temMais => _limite < widget.itemCount;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_verificarFim);
    _agendarVerificacao();
  }

  @override
  void didUpdateWidget(covariant InfiniteScrollList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) _agendarVerificacao();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Depois do layout, carrega mais se o lote atual não encheu a tela.
  void _agendarVerificacao() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificarFim());
  }

  void _verificarFim() {
    if (!mounted || !_temMais || !_controller.hasClients) return;
    if (_controller.position.extentAfter < widget.loadThreshold) {
      setState(() => _limite += widget.pageSize);
      _agendarVerificacao();
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = widget.header;
    final visiveis = _visiveis;
    return ListView.builder(
      controller: _controller,
      padding: widget.padding,
      itemCount: header.length + visiveis + (_temMais ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < header.length) return header[index];
        final item = index - header.length;
        if (item == visiveis) return const _CarregandoMais();
        return Padding(
          padding: EdgeInsets.only(
            bottom: item == visiveis - 1 ? 0 : widget.spacing,
          ),
          child: widget.itemBuilder(context, item),
        );
      },
    );
  }
}

class _CarregandoMais extends StatelessWidget {
  const _CarregandoMais();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: context.colors.accent,
          ),
        ),
      ),
    );
  }
}
