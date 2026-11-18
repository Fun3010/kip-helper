import '../models/guide.dart';

const hyperflow3pmGuide = InstrumentGuide(
  id: 'hyperflow_3pm',
  title: 'ГиперФлоу-3Пм',
  subtitle: 'Комплексный датчик с вычислителем расхода',
  category: 'Расход',
  searchTerms: ['гиперфлоу', '3пм', '3pm', 'hyperflow'],
  scope:
      'КРАУ1.456.001-06 РЭ, копия 2017 г., исполнение КРАУ1.456.001-06. Сверьте модель, состав и редакцию РЭ с паспортом установленного прибора; это не ультразвуковой ГиперФлоу-УС.',
  sections: [
    GuideSection(
      title: 'Назначение и состав',
      paragraphs: [
        'ГиперФлоу-3Пм предназначен для учёта расхода и количества жидких и газообразных сред; может работать автономно или в составе системы учёта и контроля.',
        'РЭ описывает электронный блок БЭ-020 и подключаемые датчики давления, перепада давления и температуры. Фактический состав определяется опросным листом конкретного прибора.',
      ],
      evidenceByParagraph: {
        0: [
          GuideEvidence(
            sourceKey: 'hyperflow-3pm-re',
            locator: '§ 1.1.1 · РЭ и PDF с. 5',
          ),
        ],
        1: [
          GuideEvidence(
            sourceKey: 'hyperflow-3pm-re',
            locator: '§ 1.1.1 · РЭ и PDF с. 5; рис. 1 · с. 6',
          ),
        ],
      },
    ),
    GuideSection(
      title: 'Перед работой',
      paragraphs: [
        'Запишите модель, заводской номер, исполнение и состав измерительного узла. Сверьте подключённые датчики, паспорт, схему и параметры с документацией объекта.',
        'Настройка расхода, подключение импульсных линий и поверка в этой обзорной карточке не описаны. Для работы используйте РЭ и документацию именно установленного исполнения.',
      ],
      evidenceByParagraph: {
        0: [
          GuideEvidence(
            sourceKey: 'hyperflow-3pm-re',
            locator: 'чек-лист идентификации · РЭ § 1.1.1 и паспорт',
            state: GuideEvidenceState.workingChecklist,
          ),
        ],
        1: [
          GuideEvidence(
            sourceKey: 'hyperflow-3pm-re',
            locator: 'границы обзорной карточки · РЭ с. 5',
            state: GuideEvidenceState.workingChecklist,
          ),
        ],
      },
    ),
  ],
  sources: [
    GuideSource(
      key: 'hyperflow-3pm-re',
      title: 'Вымпел · ГиперФлоу-3Пм · КРАУ1.456.001-06 РЭ, копия 2017 г.',
      url:
          'https://en.vympel.group/upload/iblock/714/Operating%20manual%20for%20HyperFlow-3Pm.pdf',
    ),
  ],
);
