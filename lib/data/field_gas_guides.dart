import '../models/guide.dart';

const ankat7664micro04 = InstrumentGuide(
  id: 'ankat7664micro04',
  title: 'АНКАТ-7664Микро-04',
  subtitle: 'Переносной газоанализатор · каналы Ex и O₂',
  category: 'Газоанализ',
  searchTerms: ['анкат', '7664', 'микро-04'],
  scope:
      'АНКАТ-7664Микро-04, ИБЯЛ.413411.053-04, РЭ ИБЯЛ.413411.053: исполнения до -18. Не путать с АНКАТ-7664М-04; сверить паспорт и редакцию РЭ.',
  sections: [
    GuideSection(
      title: 'Каналы и назначение',
      paragraphs: [
        'Для исполнения -04 таблица РЭ указывает два измерительных канала: Ex и O₂. Это не подтверждение наличия каналов CO или H₂S на данном экземпляре.',
        'Прибор относится к носимым газоанализаторам непрерывного действия. РЭ описывает сигнализацию достижения установленных порогов.',
      ],
      evidenceByParagraph: {
        0: [
          GuideEvidence(
            sourceKey: 'ankat-micro-re',
            locator: 'табл. 1.1 · РЭ и PDF с. 7',
          ),
        ],
        1: [
          GuideEvidence(
            sourceKey: 'ankat-micro-re',
            locator: 'пп. 1.1.1–1.1.3 · РЭ и PDF с. 6',
          ),
        ],
      },
    ),
    GuideSection(
      title: 'Перед применением',
      paragraphs: [
        'Сверьте полную маркировку, паспорт, каналы, настройки сигнализации, срок поверки и состояние прибора. Подготовку и проверку выполняйте по РЭ вашего экземпляра и правилам объекта.',
      ],
      evidenceByParagraph: {
        0: [
          GuideEvidence(
            sourceKey: 'ankat-micro-re',
            locator: 'рабочий чек-лист идентификации · РЭ §§ 1.6, 2.1–2.2',
            state: GuideEvidenceState.workingChecklist,
          ),
        ],
      },
    ),
  ],
  sources: [
    GuideSource(
      key: 'ankat-micro-re',
      title: 'АНКАТ-7664Микро · ИБЯЛ.413411.053 РЭ · -01…-18, копия поставщика',
      url: 'https://www.gazanalizator.ru/files/ankat-7664mikro-rpe-01-18.pdf',
    ),
  ],
);

const sgg20n = InstrumentGuide(
  id: 'sgg20n',
  title: 'СГГ-20Н',
  subtitle: 'Переносной сигнализатор горючих газов',
  category: 'Газоанализ',
  searchTerms: ['сгг20н', 'sgg20n'],
  scope:
      'СГГ-20Н, ИБЯЛ.413531.009-04, по РЭ ИБЯЛ.413531.009. Это не СГГ-20Микро; сверить паспорт и редакцию РЭ.',
  sections: [
    GuideSection(
      title: 'Назначение',
      paragraphs: [
        'СГГ-20Н предназначен для измерения концентрации многокомпонентных смесей горючих газов и паров в воздухе и сигнализации о превышении установленных довзрывоопасных концентраций.',
        'РЭ описывает носимый прибор непрерывного действия с термохимическим принципом и конвекционным отбором пробы.',
      ],
      evidenceByParagraph: {
        0: [GuideEvidence(sourceKey: 'sgg20-re', locator: 'п. 1.1 · PDF с. 3')],
        1: [GuideEvidence(sourceKey: 'sgg20-re', locator: 'п. 1.3 · PDF с. 3')],
      },
    ),
    GuideSection(
      title: 'Перед применением',
      paragraphs: [
        'Сверьте исполнение, паспорт, контролируемые компоненты, поверку, настройки и состояние прибора. Подготовку и проверку выполняйте по РЭ конкретного экземпляра и правилам объекта.',
      ],
      evidenceByParagraph: {
        0: [
          GuideEvidence(
            sourceKey: 'sgg20-re',
            locator: 'рабочий чек-лист идентификации · РЭ ИБЯЛ.413531.009',
            state: GuideEvidenceState.workingChecklist,
          ),
        ],
      },
    ),
  ],
  sources: [
    GuideSource(
      key: 'sgg20-re',
      title: 'СГГ-20 · ИБЯЛ.413531.009 РЭ, включая СГГ-20Н · копия поставщика',
      url: 'https://www.gazanalizator.ru/files/sgg-20-rpe.pdf',
    ),
  ],
);
