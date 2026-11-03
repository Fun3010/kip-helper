import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../models/local_manual.dart';

class ManualLibraryException implements Exception {
  const ManualLibraryException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ManualLibrary {
  ManualLibrary({Directory? directory}) : _directory = directory;
  Directory? _directory;
  static const maxBytes = 100 * 1024 * 1024;
  static final Map<String, Future<void>> _queues = {};
  Future<Directory> get directory async => _directory ??= Directory(
    '${(await getApplicationSupportDirectory()).path}/manuals',
  );
  Future<T> _locked<T>(Future<T> Function() action) async {
    final dir = await directory;
    await dir.create(recursive: true);
    final resolved = await dir.resolveSymbolicLinks();
    final key = Platform.isWindows ? resolved.toLowerCase() : resolved;
    final previous = _queues[key] ?? Future<void>.value();
    final done = Completer<void>();
    _queues[key] = done.future;
    await previous;
    try {
      return await action();
    } finally {
      if (identical(_queues[key], done.future)) _queues.remove(key);
      done.complete();
    }
  }

  Future<List<LocalManual>> list() => _locked(_list);

  Future<List<LocalManual>> _list() async {
    final dir = await directory;
    await dir.create(recursive: true);
    final index = File('${dir.path}/index.json');
    final backup = File('${dir.path}/index.json.bak');
    if (!await index.exists() && await backup.exists()) {
      await backup.rename(index.path);
    }
    if (!await index.exists()) return [];
    try {
      final data = jsonDecode(await index.readAsString()) as List<dynamic>;
      return data
          .map((e) => LocalManual.fromJson(e as Map<String, dynamic>, dir))
          .toList();
    } catch (_) {
      throw const ManualLibraryException(
        'Не удалось прочитать сведения библиотеки. PDF-файлы сохранены в хранилище приложения.',
      );
    }
  }

  Future<void> _save(List<LocalManual> items) async {
    final dir = await directory;
    final index = File('${dir.path}/index.json');
    final backup = File('${dir.path}/index.json.bak');
    final tmp = File('${dir.path}/index.json.tmp');
    await tmp.writeAsString(
      jsonEncode(items.map((e) => e.toJson()).toList()),
      flush: true,
    );
    if (await backup.exists()) await backup.delete();
    if (await index.exists()) await index.rename(backup.path);
    try {
      await tmp.rename(index.path);
    } catch (_) {
      if (await backup.exists()) await backup.rename(index.path);
      rethrow;
    }
    if (await backup.exists()) {
      try {
        await backup.delete();
      } on FileSystemException {
        /* committed */
      }
    }
  }

  Future<LocalManual> importFile(
    File source, {
    required String title,
    String? guideId,
    String? guideTitle,
  }) => _locked(() async {
    final dir = await directory;
    final items = await _list();
    if (title.trim().isEmpty) {
      throw const ManualLibraryException('Укажите название документа.');
    }
    final temp = File(
      '${dir.path}/import-${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    final sink = temp.openWrite();
    var size = 0;
    final header = <int>[];
    try {
      await for (final chunk in source.openRead()) {
        size += chunk.length;
        if (size > maxBytes) {
          throw const ManualLibraryException('Размер файла превышает 100 МиБ.');
        }
        if (header.length < 5) header.addAll(chunk.take(5 - header.length));
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      if (header.length != 5 ||
          ascii.decode(header, allowInvalid: true) != '%PDF-') {
        throw const ManualLibraryException('Файл не является PDF.');
      }
      final id = (await sha256.bind(temp.openRead()).first).toString();
      if (items.any((e) => e.id == id)) {
        throw const ManualLibraryException(
          'Этот файл уже добавлен в библиотеку.',
        );
      }
      final target = File('${dir.path}/$id.pdf');
      final existed = await target.exists();
      if (!existed) await temp.rename(target.path);
      final item = LocalManual(
        id: id,
        title: title.trim(),
        size: size,
        path: target.path,
        guideId: guideId,
        guideTitle: guideTitle,
      );
      try {
        await _save([...items, item]);
      } catch (_) {
        // Keep the copy if commit status is uncertain; it can be recovered.
        rethrow;
      }
      return item;
    } finally {
      await sink.close();
      if (await temp.exists()) await temp.delete();
    }
  });

  Future<void> remove(LocalManual item) => _locked(() async {
    final items = await _list();
    await _save(items.where((e) => e.id != item.id).toList());
    final dir = await directory;
    final file = File('${dir.path}/${item.id}.pdf');
    if (await file.exists()) await file.delete();
  });

  Future<void> associate(LocalManual item, String guideId, String guideTitle) =>
      _locked(() async {
        final items = await _list();
        final index = items.indexWhere((e) => e.id == item.id);
        if (index < 0) {
          throw const ManualLibraryException('Документ больше не найден.');
        }
        final old = items[index];
        items[index] = LocalManual(
          id: old.id,
          title: old.title,
          size: old.size,
          path: old.path,
          guideId: guideId,
          guideTitle: guideTitle,
        );
        await _save(items);
      });
}
