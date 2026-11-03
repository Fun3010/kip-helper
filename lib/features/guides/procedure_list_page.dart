import 'package:flutter/material.dart';
import '../../data/guide_procedures.dart';
import '../../models/guide.dart';
import 'procedure_page.dart';

class ProcedureListPage extends StatelessWidget {
  const ProcedureListPage({super.key, required this.guide});
  final InstrumentGuide guide;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Настройка по шагам')),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(guide.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text(
                'Выберите задачу. Перед началом каждого сценария указаны исполнение, условия и источники.',
              ),
              const SizedBox(height: 20),
              for (final procedure in proceduresForGuide(guide.id))
                Card(
                  child: ListTile(
                    title: Text(procedure.title),
                    subtitle: Text(procedure.scope),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProcedurePage(procedure: procedure),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
