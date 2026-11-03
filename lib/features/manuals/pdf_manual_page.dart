import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../models/local_manual.dart';

int? validManualPage(String input, int pageCount) {
  final page = int.tryParse(input.trim());
  return page != null && page >= 1 && page <= pageCount ? page : null;
}

class PdfManualPage extends StatefulWidget {
  const PdfManualPage({super.key, required this.manual, this.initialPage = 1});
  final LocalManual manual;
  final int initialPage;
  @override
  State<PdfManualPage> createState() => _PdfManualPageState();
}

class _PdfManualPageState extends State<PdfManualPage> {
  final controller = PdfViewerController();
  late final searcher = PdfTextSearcher(controller)..addListener(_changed);
  final query = TextEditingController();
  final pageInput = TextEditingController();
  int page = 1, count = 0;
  bool searched = false;
  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    searcher.dispose();
    query.dispose();
    pageInput.dispose();
    super.dispose();
  }

  void _jump() {
    final target = validManualPage(pageInput.text, count);
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите страницу от 1 до $count.')),
      );
      return;
    }
    controller.goToPage(pageNumber: target);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.manual.title)),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              SizedBox(
                width: 130,
                child: TextField(
                  controller: query,
                  decoration: const InputDecoration(labelText: 'Поиск в PDF'),
                  onSubmitted: (_) {
                    setState(() => searched = true);
                    searcher.startTextSearch(
                      query.text,
                      searchImmediately: true,
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: 'Найти',
                onPressed: count == 0
                    ? null
                    : () {
                        setState(() => searched = true);
                        searcher.startTextSearch(
                          query.text,
                          searchImmediately: true,
                        );
                      },
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: 'Предыдущее совпадение',
                onPressed: searcher.hasMatches ? searcher.goToPrevMatch : null,
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: 'Следующее совпадение',
                onPressed: searcher.hasMatches ? searcher.goToNextMatch : null,
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              SizedBox(
                width: 85,
                child: TextField(
                  controller: pageInput,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Стр. / $count'),
                  onSubmitted: (_) => _jump(),
                ),
              ),
              IconButton(
                tooltip: 'Перейти к странице',
                onPressed: count == 0 ? null : _jump,
                icon: const Icon(Icons.arrow_forward),
              ),
              Text('$page / $count'),
            ],
          ),
        ),
        if (searched && query.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              searcher.isSearching
                  ? 'Поиск…'
                  : searcher.matches.isEmpty
                  ? 'Совпадений нет. В сканах без текстового слоя поиск недоступен.'
                  : 'Найдено: ${searcher.matches.length}',
            ),
          ),
        Expanded(
          child: PdfViewer.file(
            widget.manual.path,
            controller: controller,
            initialPageNumber: 1,
            params: PdfViewerParams(
              pagePaintCallbacks: [searcher.pageTextMatchPaintCallback],
              onViewerReady: (document, pdfController) {
                final total = document.pages.length;
                if (total == 0 || !mounted) return;
                setState(() {
                  count = total;
                  page = widget.initialPage.clamp(1, total);
                });
                pdfController.goToPage(pageNumber: page);
              },
              onPageChanged: (value) {
                if (value != null && mounted) setState(() => page = value);
              },
            ),
          ),
        ),
      ],
    ),
  );
}
