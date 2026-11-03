import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../models/local_manual.dart';

int? validManualPage(String input, int pageCount) {
  final page = int.tryParse(input.trim());
  return page != null && page >= 1 && page <= pageCount ? page : null;
}

enum PdfTextLayer { present, absent, error }

Future<PdfTextLayer> inspectPdfTextLayer(
  int pageCount,
  Future<String?> Function(int) load,
) async {
  try {
    for (var i = 1; i <= pageCount; i++) {
      final text = await load(i);
      if (text == null) return PdfTextLayer.error;
      if (text.trim().isNotEmpty) return PdfTextLayer.present;
    }
    return PdfTextLayer.absent;
  } catch (_) {
    return PdfTextLayer.error;
  }
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
  PdfTextSearcher? searcher;
  final query = TextEditingController();
  final pageInput = TextEditingController();
  int page = 1, count = 0;
  bool searched = false;
  String textStatus = 'Проверка текстового слоя…';
  int viewerVersion = 0;
  Future<void> _checkText(int total, PdfTextSearcher activeSearcher) async {
    final version = viewerVersion;
    final status = await inspectPdfTextLayer(
      total,
      (i) async => (await activeSearcher.loadText(pageNumber: i))?.fullText,
    );
    if (!mounted || version != viewerVersion) return;
    setState(
      () => textStatus = switch (status) {
        PdfTextLayer.present => '',
        PdfTextLayer.absent =>
          'Текстовый слой не найден: возможно, это скан. Поиск недоступен.',
        PdfTextLayer.error => 'Не удалось проверить текстовый слой.',
      },
    );
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    searcher?.dispose();
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
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.4,
          ),
          child: SingleChildScrollView(
            child: Column(
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
                          key: const ValueKey('manual-search'),
                          controller: query,
                          decoration: const InputDecoration(labelText: 'Поиск'),
                          onSubmitted: (_) {
                            if (searcher == null) return;
                            setState(() => searched = true);
                            searcher!.startTextSearch(
                              query.text,
                              searchImmediately: true,
                            );
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: 'Найти',
                        onPressed: searcher == null
                            ? null
                            : () {
                                setState(() => searched = true);
                                searcher!.startTextSearch(
                                  query.text,
                                  searchImmediately: true,
                                );
                              },
                        icon: const Icon(Icons.search),
                      ),
                      IconButton(
                        tooltip: 'Предыдущее совпадение',
                        onPressed: searcher?.hasMatches == true
                            ? searcher!.goToPrevMatch
                            : null,
                        icon: const Icon(Icons.keyboard_arrow_up),
                      ),
                      IconButton(
                        tooltip: 'Следующее совпадение',
                        onPressed: searcher?.hasMatches == true
                            ? searcher!.goToNextMatch
                            : null,
                        icon: const Icon(Icons.keyboard_arrow_down),
                      ),
                      SizedBox(
                        width: 85,
                        child: TextField(
                          key: const ValueKey('manual-page'),
                          controller: pageInput,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Стр.'),
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
                if (textStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(textStatus),
                  ),
                if (searched && query.text.isNotEmpty && searcher != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      searcher!.isSearching
                          ? 'Поиск…'
                          : searcher!.matches.isEmpty
                          ? 'Совпадений нет.'
                          : 'Найдено: ${searcher!.matches.length}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: PdfViewer.file(
            widget.manual.path,
            key: ValueKey(viewerVersion),
            controller: controller,
            initialPageNumber: 1,
            params: PdfViewerParams(
              errorBannerBuilder: (context, error, stack, ref) => Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Не удалось открыть PDF. Файл может быть повреждён или защищён паролем.',
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          searcher?.dispose();
                          searcher = null;
                          viewerVersion++;
                          count = 0;
                          searched = false;
                          textStatus = 'Проверка текстового слоя…';
                        }),
                        child: const Text('Повторить'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Назад'),
                      ),
                    ],
                  ),
                ),
              ),
              pagePaintCallbacks: [
                if (searcher != null) searcher!.pageTextMatchPaintCallback,
              ],
              onViewerReady: (document, pdfController) {
                final total = document.pages.length;
                if (total == 0 || !mounted) return;
                searcher?.dispose();
                final activeSearcher = PdfTextSearcher(pdfController)
                  ..addListener(_changed);
                setState(() {
                  searcher = activeSearcher;
                  count = total;
                  page = widget.initialPage.clamp(1, total);
                });
                pdfController.goToPage(pageNumber: page);
                _checkText(total, activeSearcher);
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
