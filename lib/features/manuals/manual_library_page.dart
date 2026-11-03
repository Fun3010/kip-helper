import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../../models/local_manual.dart';
import '../../services/manual_library.dart';
import 'pdf_manual_page.dart';

class ManualLibraryPage extends StatefulWidget {
  const ManualLibraryPage({
    super.key,
    this.guideId,
    this.guideTitle,
    this.library,
    this.pickFile,
  });
  final String? guideId, guideTitle;
  final ManualLibrary? library;
  final Future<XFile?> Function()? pickFile;
  @override
  State<ManualLibraryPage> createState() => _ManualLibraryPageState();
}

class _ManualLibraryPageState extends State<ManualLibraryPage> {
  late final ManualLibrary library = widget.library ?? ManualLibrary();
  List<LocalManual> items = [];
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await library.list();
      if (mounted) {
        setState(() {
          items = all;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Не удалось загрузить библиотеку. Повторите попытку.',
        );
      }
    }
  }

  Future<void> _add() async {
    setState(() => busy = true);
    try {
      const type = XTypeGroup(
        label: 'PDF',
        extensions: ['pdf'],
        mimeTypes: ['application/pdf'],
        uniformTypeIdentifiers: ['com.adobe.pdf'],
      );
      final picked =
          await (widget.pickFile?.call() ??
              openFile(acceptedTypeGroups: [type]));
      if (picked == null || !mounted) return;
      final input = TextEditingController(
        text: picked.name.replaceFirst(
          RegExp(r'\.pdf$', caseSensitive: false),
          '',
        ),
      );
      final title = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Название документа'),
          content: TextField(
            controller: input,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Название'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, input.text),
              child: const Text('Добавить'),
            ),
          ],
        ),
      );
      input.dispose();
      if (title == null) return;
      await library.importFile(
        File(picked.path),
        title: title,
        guideId: widget.guideId,
        guideTitle: widget.guideTitle,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ManualLibraryException
                  ? e.message
                  : 'Не удалось добавить PDF. Повторите попытку.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _remove(LocalManual item) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удалить документ?'),
          content: Text('Копия «${item.title}» будет удалена из библиотеки.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Удалить'),
            ),
          ],
        ),
      );
      if (yes != true) return;
      try {
        await library.remove(item);
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось удалить документ. Повторите попытку.'),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _associate(LocalManual item) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Связать документ с прибором?'),
          content: Text(
            '«${item.title}» будет связан с «${widget.guideTitle}»${item.guideTitle == null ? '' : ' вместо «${item.guideTitle}»'}. PDF-файл останется в библиотеке.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Связать'),
            ),
          ],
        ),
      );
      if (yes == true) {
        await library.associate(
          item,
          widget.guideId!,
          widget.guideTitle ?? widget.guideId!,
        );
        await _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось связать документ. Повторите попытку.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Мои PDF')),
    body: error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!),
                  TextButton(onPressed: _load, child: const Text('Повторить')),
                ],
              ),
            ),
          )
        : items.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Добавьте PDF с устройства. Документы хранятся в приложении и доступны офлайн.',
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: Text(item.title),
                subtitle: Text(
                  '${(item.size / 1048576).toStringAsFixed(2)} МиБ${item.guideTitle == null ? '' : ' · Связан с: ${item.guideTitle}'}${item.missing ? ' · Файл отсутствует' : ''}',
                ),
                onTap: item.missing
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfManualPage(manual: item),
                        ),
                      ),
                trailing: Wrap(
                  children: [
                    if (widget.guideId != null &&
                        item.guideId != widget.guideId)
                      IconButton(
                        tooltip: 'Связать с этим прибором',
                        onPressed: busy ? null : () => _associate(item),
                        icon: const Icon(Icons.link),
                      ),
                    IconButton(
                      tooltip: 'Удалить',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: busy ? null : () => _remove(item),
                    ),
                  ],
                ),
              );
            },
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: busy || error != null ? null : _add,
      icon: const Icon(Icons.add),
      label: const Text('Добавить PDF'),
    ),
  );
}
