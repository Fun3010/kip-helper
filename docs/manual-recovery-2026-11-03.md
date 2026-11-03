# Восстановление технических документов, 03.11.2026

Восстановлены **4 из 21 исторических PDF** с точным совпадением SHA-256. Дополнительно сохранены **3 PDF**, совпавшие с отдельными проверенными источниками карточек (Siemens ×2, Rosemount РЭ). Они не засчитываются вместо исторических PDF. Остались отсутствующими **17 исторических PDF и все 13 JPG**. Полный перенос материалов пока не выполнен.

Частная [папка Drive](https://drive.google.com/drive/folders/1UNiRDvaxCRqbpYsO2KepdryBBewAoPvy) создана внутри папки проекта. Общий доступ не включался. На каждый из семи PDF прочитаны обратно имя, размер, родитель и shared=false; разрешения содержат только владельца. SHA-256 проверен для локально скачанных байтов до загрузки. Коннектор не возвращает удалённую контрольную сумму; повторного скачивания из Drive не выполнялось.

[Манифест в Drive](https://drive.google.com/file/d/1gWHyTE1r0Pd8nBww3DWYd9segyMn-mbn/view?usp=drivesdk), 16 798 байт, SHA-256 `85aaa9039a55860a363b6a7280e2a21a646a28c280880cbf1b901034d79bb588`. Имя, размер, родитель и частный доступ манифеста также проверены readback.

## Точные исторические копии

| Документ | SHA-256 | Байты | Копия Drive |
| --- | --- | ---: | --- |
| Sokrat-RZ-N3_E32-SM.090.00.00.000-RE.pdf | `dc33ec57e01bd06a9628a7b2a0ba247e3c34aca00a3e391f33b2034c831d578a` | 7671405 | [PDF](https://drive.google.com/file/d/19C1sTkOQVl-0KpSUp4BpqRYarOrYK2Zs/view?usp=drivesdk) |
| re_su-1s_201411_a.pdf | `4c8db5f3c569dbab554c256b4905197c503fa0b8202bd9eca5b0d3537d3402db` | 5977563 | [PDF](https://drive.google.com/file/d/13PL7XSkiZPN8JurePNhplC0xbilBn5WH/view?usp=drivesdk) |
| stm-10_api2_840_069_re.pdf | `a4b5f9e0cd898dc59fa7ae40980ce6352df0924cf0585fdc40f4a97fc655bf85` | 4488738 | [PDF](https://drive.google.com/file/d/1S5COWDhH6X-cDXpYxCXuZ6H_sh7R9FVs/view?usp=drivesdk) |
| Metran-100-RE-Rukovodstvo-po-ekspluatatsii.pdf | `6e95bc02be72e6fd45bf192039a1223dcc1d872970889c7a2919a0bee28bcfc5` | 1222152 | [PDF](https://drive.google.com/file/d/1jr1m5jqH_aHpihkduQxCQ_dYr_i73SCo/view?usp=drivesdk) |

Исходные пути для восстановления дерева (в Drive файлы лежат плоско; манифест сохраняет соответствие):

- `docs/Оборудование/Метран-100/ТД/Metran-100-RE-Rukovodstvo-po-ekspluatatsii.pdf`
- `docs/Оборудование/СОКРАТ/ТД/Sokrat-RZ-N3_E32-SM.090.00.00.000-RE.pdf`
- `docs/Оборудование/СТМ-10/ТД/stm-10_api2_840_069_re.pdf`
- `docs/Оборудование/СУ-1С/ТД/re_su-1s_201411_a.pdf`

## Дополнительные проверенные источники

| Снимок | SHA-256 | Байты | Копия Drive |
| --- | --- | ---: | --- |
| A5E03436620en_PS2_COI_en-US.pdf | `6c44ebfbdb021d1d12e87cd1dfbb70638a61e40adf9b7868cd93ac1efe4b712b` | 4760938 | [PDF](https://drive.google.com/file/d/1ONg9kB9r-av_50LuldK4ZgLgB1xI2Ykx/view?usp=drivesdk) |
| A5E00074631-AFen_PS2HART_OI_en-US.pdf | `8b864ad7f10416a93aa38d6f88ec3fc66838376b33b37af0ac07cc547b66c18f` | 13415015 | [PDF](https://drive.google.com/file/d/11GnKoyCrjrM4z3EXpJ8lm5ZPfDFL-9wh/view?usp=drivesdk) |
| rukovodstvo-po-ekspluataczii-rashodomer-vihrevoj-8600d-ru-ru-5220322.pdf | `1ec893f8b586b4ec4a25a5f14b0b44e1f13ad36e11d46f80609e666fc5b80fd7` | 3225674 | [PDF](https://drive.google.com/file/d/11b36wF_uLONoc6_GM38DAQDYQs14VrC9/view?usp=drivesdk) |

Эти три файла сохранены в Drive с префиксом SOURCE-SNAPSHOT. Siemens не заменяет старые `dr6.pdf` / `Siemens sipart ps2.pdf` (оба имеют SHA-256 `4bb94dacbe999dd3462b153d17527203a005c48c394a7f9d9e62335801f4562f`). Rosemount РЭ не заменяет исторический `Catalog_8600D_2019.pdf` (SHA-256 `bac104cc58771ae37eae5384f04cdfd81c0eead8afe1f8c1a6411b615038dea4`).

## Проверенные записанные URLs

Проверены ровно восемь ранее записанных адресов; произвольный поиск всех 21 PDF не проводился. Ссылки изготовителей Siemens, Сибмаш, Аналитприбор и Метран дополнительно открыты через браузерный поиск источников. СУ-1С, Метран-100 и Rosemount скачаны с документированных публичных зеркал; это не делает сайт зеркала официальным сайтом изготовителя.

- **sipart-compact**: [исходный PDF](https://cache.industry.siemens.com/dl/files/665/109972665/att_1291485/v1/A5E03436620en_PS2_COI_en-US.pdf); точное совпадение с хешем скрипта, отдельный источник. Ожидаемый SHA-256: `6c44ebfbdb021d1d12e87cd1dfbb70638a61e40adf9b7868cd93ac1efe4b712b`; полученный: `6c44ebfbdb021d1d12e87cd1dfbb70638a61e40adf9b7868cd93ac1efe4b712b`. Основание ожидаемого хеша: `scripts/extract-sipart-illustrations.py`.
- **sipart-full**: [исходный PDF](https://cache.industry.siemens.com/dl/files/419/109782419/att_1034214/v1/A5E00074631-AFen_PS2HART_OI_en-US.pdf); точное совпадение с хешем скрипта, отдельный источник. Ожидаемый SHA-256: `8b864ad7f10416a93aa38d6f88ec3fc66838376b33b37af0ac07cc547b66c18f`; полученный: `8b864ad7f10416a93aa38d6f88ec3fc66838376b33b37af0ac07cc547b66c18f`. Основание ожидаемого хеша: `scripts/extract-sipart-illustrations.py`.
- **sokrat**: [исходный PDF](https://www.sibmash.com/docs/Sokrat-RZ-N3_E32-SM.090.00.00.000-RE.pdf); точное совпадение с историческим реестром. Ожидаемый SHA-256: `dc33ec57e01bd06a9628a7b2a0ba247e3c34aca00a3e391f33b2034c831d578a`; полученный: `dc33ec57e01bd06a9628a7b2a0ba247e3c34aca00a3e391f33b2034c831d578a`. Основание ожидаемого хеша: `docs/technical-documents.json`.
- **su1s**: [исходный PDF](https://kip-device.ru/f/re_su-1s_201411_a.pdf); точное совпадение с историческим реестром. Ожидаемый SHA-256: `4c8db5f3c569dbab554c256b4905197c503fa0b8202bd9eca5b0d3537d3402db`; полученный: `4c8db5f3c569dbab554c256b4905197c503fa0b8202bd9eca5b0d3537d3402db`. Основание ожидаемого хеша: `scripts/extract-level-gas-illustrations.py`.
- **stm10**: [исходный PDF](https://www.analitpribor-smolensk.ru/files/rukovodstva/2015/ctm-10/stm-10_api2_840_069_re.pdf); точное совпадение с историческим реестром. Ожидаемый SHA-256: `a4b5f9e0cd898dc59fa7ae40980ce6352df0924cf0585fdc40f4a97fc655bf85`; полученный: `a4b5f9e0cd898dc59fa7ae40980ce6352df0924cf0585fdc40f4a97fc655bf85`. Основание ожидаемого хеша: `scripts/extract-level-gas-illustrations.py`.
- **metran100**: [исходный PDF](https://xn--90ahjlpcccjdm.xn--p1ai/wp-content/uploads/2021/05/Metran-100-RE-Rukovodstvo-po-ekspluatatsii.pdf); точное совпадение с историческим реестром. Ожидаемый SHA-256: `6e95bc02be72e6fd45bf192039a1223dcc1d872970889c7a2919a0bee28bcfc5`; полученный: `6e95bc02be72e6fd45bf192039a1223dcc1d872970889c7a2919a0bee28bcfc5`. Основание ожидаемого хеша: `scripts/extract-metran100-illustrations.py`.
- **metran150**: [исходный PDF](https://metran.ru/upload/iblock/794/0iy0f9l4wu0yx9eykbyaxat1j9ddpqh0.pdf); НЕ совпал с ожидаемым хешем. Ожидаемый SHA-256: `8fdaa068e0441171c30ea1fe8671e0c9c06c0589ddc1d36fd4e3dee6c949e721`; полученный: `db154bbcd97df770afe3299cbb2aad09421c59987da0f205db538a2992f58c08`. Основание ожидаемого хеша: `scripts/extract-metran150-illustrations.py`.
- **rosemount8600d**: [исходный PDF](https://mirkip.ru/wp-content/uploads/rukovodstvo-po-ekspluataczii-rashodomer-vihrevoj-8600d-ru-ru-5220322.pdf); точное совпадение с хешем скрипта, отдельный источник. Ожидаемый SHA-256: `1ec893f8b586b4ec4a25a5f14b0b44e1f13ad36e11d46f80609e666fc5b80fd7`; полученный: `1ec893f8b586b4ec4a25a5f14b0b44e1f13ad36e11d46f80609e666fc5b80fd7`. Основание ожидаемого хеша: `scripts/extract-rosemount8600d-illustrations.py`.

У Метран-150 получен PDF 6 202 261 байт, SHA-256 `db154bbcd97df770afe3299cbb2aad09421c59987da0f205db538a2992f58c08`, вместо ожидаемого `8fdaa068e0441171c30ea1fe8671e0c9c06c0589ddc1d36fd4e3dee6c949e721`. Он оставлен только локально в `.private/recovered-manuals/unverified-snapshots/metran150-v4.23.pdf`, не загружен как проверенная копия. Старый `71450_metran150.pdf` также не восстановлен. Совпадение названия/номера версии не доказывает совпадение байтов.

Первое скачивание двух Siemens через Python не прошло проверку цепочки TLS. Повторное скачивание средствами Windows с обычной проверкой сертификатов прошло, оба SHA-256 совпали. Проверка сертификатов не отключалась. Ограничение размера браузерного инструмента для полного Siemens и тайм-аут браузерного инструмента Rosemount не помешали независимому скачиванию и проверке байтов.

## Источники без записанного публичного URL

- OPTIFLEX 1300C: отчёт `docs/optiflex1300c-source-verification-2026-10-13.md` прямо указывает отсутствие подтверждённого URL. Ожидаемый SHA-256 `c50821cdf7d9a868bc3543ce02b10857731e90f4948299afc68d490ecb407463`; файл не восстановлен.
- Micro Motion: отчёт `docs/micro-motion-source-verification-2026-10-13.md` прямо указывает отсутствие подтверждённого URL у предоставленного `Micro_motion.pdf` (`786bf06f67ec4e2e6194926709ba59fc2b60b043071c155125f3cb2cc8603335`). Исторический `MMI_ 1000_2000_Man_PN20001715_ReV_B_rus.pdf` (`472f1f8f81caaed5192453c91cd88d013324db83334f74d724ba614fa5fce0fa`) тоже не восстановлен. URL не придумывались.

## Оставшиеся исторические PDF

| Путь | Ожидаемый SHA-256 |
| --- | --- |
| `docs/Оборудование/ИВА-8/ТД/2020-13560-11 ОТ ИВА-8.pdf` | `8785ca493b569b0f64647a19921552695f87832326557d977600c77dc8905e8d` |
| `docs/Оборудование/Метран-281-286-288/ТД/281286288.pdf` | `499ebcab01dc8138aeaea0de7e48d2ca3c17a5be7fd9340b374f03775b4b1753` |
| `docs/Оборудование/_Общие материалы/ТД/4293727578.pdf` | `8568faf668300037b7d3661f42f4ddda4ad370059edc23292be6de6d99f156b1` |
| `docs/Оборудование/Метран-150/ТД/71450_metran150.pdf` | `4964a928894ddcef35ef72c975eec6e04502ab980547db60c04ffdc9278bc873` |
| `docs/Оборудование/БКТ.М/ТД/bktm.pdf` | `cfe6130554959938931fff9e0545a37cd8cceefe7817f7d7695b08ea3a23a539` |
| `docs/Оборудование/Тяжпромарматура — пневмоприводы/ТД/bukw13qb3iktooqxd9da16tpx8soqzv6.pdf` | `30f1883e47b41e072adcb13a2bf9cb6e960f544f25634e813f77728873894175` |
| `docs/Оборудование/Rosemount 8600D/ТД/Catalog_8600D_2019.pdf` | `bac104cc58771ae37eae5384f04cdfd81c0eead8afe1f8c1a6411b615038dea4` |
| `docs/Оборудование/SIPART PS2/ТД/dr6.pdf` | `4bb94dacbe999dd3462b153d17527203a005c48c394a7f9d9e62335801f4562f` |
| `docs/Оборудование/Метран-300ПР/ТД/Metran_300PR.pdf` | `c6892e6c326d34e8a34068f0f3ce06bdd6beabd99d3d0dd3ad816f6b70d169e8` |
| `docs/Оборудование/Micro Motion/ТД/MMI_ 1000_2000_Man_PN20001715_ReV_B_rus.pdf` | `472f1f8f81caaed5192453c91cd88d013324db83334f74d724ba614fa5fce0fa` |
| `docs/Оборудование/Yokogawa EJA-E/ТД/mp_66959-17.pdf` | `d2a9db128e19487f1bf6dd631b0e99b520ecbb4c283f8c53edabf5a1e988f435` |
| `docs/Оборудование/OPTIFLEX 1300 C/ТД/optiflex-1300-c-rpe.pdf` | `c50821cdf7d9a868bc3543ce02b10857731e90f4948299afc68d490ecb407463` |
| `docs/Оборудование/РУСТ — клапаны 300-400-500/ТД/RE-ZRK_01.00.00-po-TR-TS-012.pdf` | `d4e523c0c62c6ddef2c13502479e12c442fbb3177bd436a3a419e1fdaa1a89dc` |
| `docs/Оборудование/Сапфир-22-ДУ/ТД/sapfir_22_du.pdf` | `ea9eba64fa73dc7d50cf6e98d90320255fa65c425d27cb5293d088d5137c6683` |
| `docs/Оборудование/СГГ-20микро/ТД/sgg-20mikro-rpe.pdf` | `96fd51ed934c70361d2746d47bca770931acf92da5cbaf7045d905aafb986573` |
| `docs/Оборудование/СГГ-20микро/ТД/sgg-20mikro_ibyal_413531_012_re.pdf` | `7f2247341844a02108ef7a75536f0997f0355dbad00658acf4365fab5d8e9d1c` |
| `docs/Оборудование/SIPART PS2/ТД/Siemens sipart ps2.pdf` | `4bb94dacbe999dd3462b153d17527203a005c48c394a7f9d9e62335801f4562f` |

## Продолжение на ноутбуке

1. Скачать из частной папки Drive семь PDF и `manual-recovery-manifest-2026-11-03.json`. Проверить SHA-256 и размер каждого скачанного файла по манифесту.
2. У четырёх записей `verified_historical` использовать `historical_paths` для восстановления прежнего дерева `docs/Оборудование/` в частном хранилище. В этом клоне оригиналы намеренно находятся в игнорируемой `.private/recovered-manuals/originals/`; не добавлять их в публичный Git.
3. Три `verified_source_snapshot` хранить отдельно в `.private/recovered-manuals/source-snapshots/`. Они нужны для воспроизведения иллюстраций, но не закрывают недостающие исторические записи.
4. Остальные 17 PDF, 13 JPG и два предоставленных файла без URL получить с прежнего устройства или независимой копии. Для фотографий URLs руководств не являются способом восстановления. Пароли/ключи не искались и не расшифровывались.

Изменения продукта, тесты, сборки и публикация оригиналов в Git в этом этапе не выполнялись. Общий реестр `technical-documents.json` не переписан.
