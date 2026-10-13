import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/guide_notes.dart';

enum _ExitChoice { stay, discard, save }

class GuideNotesPage extends StatefulWidget {
  const GuideNotesPage({
    super.key,
    required this.guideId,
    required this.guideTitle,
    this.controller,
  });

  final String guideId;
  final String guideTitle;
  final GuideNotesController? controller;

  @override
  State<GuideNotesPage> createState() => _GuideNotesPageState();
}

class _GuideNotesPageState extends State<GuideNotesPage> {
  late final GuideNotesController _notes;
  final _editor = TextEditingController();
  bool _confirmingExit = false;
  bool _allowExit = false;

  @override
  void initState() {
    super.initState();
    _notes = widget.controller ?? GuideNotesController(widget.guideId);
    _notes.addListener(_changed);
    _editor.text = _notes.text;
    if (!_notes.ready) _notes.load();
  }

  void _changed() {
    if (!mounted) return;
    if (_editor.text != _notes.text) _editor.text = _notes.text;
    setState(() {});
  }

  @override
  void dispose() {
    _notes.removeListener(_changed);
    if (widget.controller == null) _notes.dispose();
    _editor.dispose();
    super.dispose();
  }

  Future<void> _requestExit() async {
    if (_confirmingExit || _notes.saving) return;
    if (!_notes.dirty) {
      Navigator.of(context).pop();
      return;
    }
    _confirmingExit = true;
    FocusScope.of(context).unfocus();
    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Несохранённые изменения'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Сохранить личную заметку перед выходом?'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, _ExitChoice.save),
              child: const Text('Сохранить и выйти'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, _ExitChoice.stay),
              child: const Text('Продолжить редактирование'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, _ExitChoice.discard),
              child: const Text('Выйти без сохранения'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    _confirmingExit = false;
    if (choice == _ExitChoice.save) {
      final saved = await _notes.save();
      if (!mounted || !saved || _notes.dirty) return;
    } else if (choice != _ExitChoice.discard) {
      return;
    }
    setState(() => _allowExit = true);
    // Rebuild PopScope before requesting the guarded navigation operation.
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _clear() async {
    FocusScope.of(context).unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Очистить личную заметку?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Текст будет удалён из редактора. Для записи изменения нажмите «Сохранить».',
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Очистить текст'),
            ),
          ],
        ),
      ),
    );
    if (mounted && confirmed == true) _notes.edit('');
  }

  String get _status => !_notes.ready
      ? 'Загрузка…'
      : _notes.loadFailed
      ? 'Не удалось загрузить личную заметку. Повторите загрузку, чтобы не перезаписать сохранённый текст.'
      : _notes.saving
      ? 'Сохранение…'
      : _notes.saveFailed
      ? 'Не удалось сохранить личную заметку. Текст остаётся в редакторе. Повторите сохранение.'
      : _notes.dirty
      ? 'Есть несохранённые изменения'
      : 'Сохранено';

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: _allowExit || (!_notes.dirty && !_notes.saving),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _requestExit();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _requestExit),
        title: const Text(
          'Личные заметки',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.guideTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ваши личные записи по прибору. Сохраняются на этом устройстве.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _editor,
                    enabled: _notes.canEdit,
                    minLines: 6,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) =>
                            GuideNotesController.characterCount(
                                  newValue.text,
                                ) <=
                                GuideNotesController.maxLength
                            ? newValue
                            : oldValue,
                      ),
                    ],
                    onChanged: _notes.edit,
                    decoration: InputDecoration(
                      labelText: 'Текст заметки',
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                      counterText:
                          '${GuideNotesController.characterCount(_notes.text)} / ${GuideNotesController.maxLength}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(liveRegion: true, child: Text(_status)),
                  const SizedBox(height: 12),
                  if (_notes.loadFailed)
                    FilledButton(
                      onPressed: _notes.ready ? _notes.load : null,
                      child: const Text('Повторить загрузку'),
                    )
                  else
                    FilledButton(
                      onPressed:
                          _notes.canEdit &&
                              !_notes.saving &&
                              (_notes.dirty || _notes.saveFailed)
                          ? _notes.save
                          : null,
                      child: Text(
                        _notes.saveFailed
                            ? 'Повторить сохранение'
                            : 'Сохранить',
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed:
                        _notes.canEdit &&
                            !_notes.saving &&
                            _notes.text.isNotEmpty
                        ? _clear
                        : null,
                    child: const Text('Очистить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
