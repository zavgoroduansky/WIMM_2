# WIMM Handoff (Updated 2026-03-10, latest-27)

## Поточний стан
Проєкт: `/Users/ozavhorodianskyi/Documents/xCode/WIMM_2/WIMM`

Остання перевірка збірки:
- `xcodebuild -project WIMM.xcodeproj -scheme WIMM -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
- Результат: BUILD SUCCEEDED.

## Важливе виправлення з останнього кроку
Було запитано:
1. Перейти на схему з міграціями, щоб зміни структури БД не ламали запуск.
2. Прибрати CloudKit і залишити локальне збереження через SwiftData.
3. Додати нову іконку апки і вибір типу графіка в Reports.
4. Почати SOLID-рефакторинг структури моделей і прибрати невикористані файли.
5. Поглибити DI для підготовки до unit-тестів (без static API у доменних хелперах).
6. Перенести бізнес-логіку у ViewModel (щоб View були максимально dumb) і підготувати шаблони unit-тестів.
7. Винести всі моки в окремі файли і покрити ViewModel для інших View.

Статус: виконано.

### Що саме змінено
- Додано `versioned schema`:
  - `WIMMSchemaV1`
  - `WIMMSchemaV2`
  - `WIMMMigrationPlan` з `lightweight` stage `V1 -> V2`.

- Оновлено ініціалізацію `ModelContainer`:
  - контейнер створюється через `Schema(versionedSchema: WIMMSchemaV2.self)`;
  - застосовується `migrationPlan: WIMMMigrationPlan.self`;
  - використовується тільки локальна конфігурація `ModelConfiguration(isStoredInMemoryOnly: false)` (без CloudKit).

- В результаті:
  - локальне оновлення структури проходить через план міграцій;
  - немає залежності від iCloud/CloudKit entitlement.

- Додано нову іконку застосунку:
  - зелений фон + білий напис `WIMM`;
  - додані файли `AppIcon.png`, `AppIcon-Dark.png`, `AppIcon-Tinted.png`;
  - `AppIcon.appiconset/Contents.json` оновлено з `filename` для кожного appearance.

- Оновлено `Reports`:
  - новий picker `Chart Type`: `Bar` / `Pie`;
  - доданий `SectorMark` для кругової діаграми;
  - доданий вибір місяця з усіх доступних місяців у даних (включно з поточним);
  - графіки працюють як для поточного місяця, так і для старіших записів.

- SOLID-рефакторинг моделей:
  - видалено монолітний `FinanceModels.swift`;
  - моделі та enum-и розділено по окремих файлах;
  - винесено допоміжну доменну логіку з `Account`:
    - `AccountEnabledCurrenciesCodec` (encode/decode enabled currencies);
    - `AccountBalanceCalculator` (розрахунок балансів);
  - `Account` тепер делегує ці обовʼязки helper-сутностям.

- Прибрано невикористаний файл:
  - `WIMM/Item.swift` (тип `Item` не використовувався в застосунку).

- DI-рефакторинг:
  - `AccountEnabledCurrenciesCodec`:
    - введено протокол `AccountEnabledCurrenciesCoding`;
    - instance methods замість static.
  - `AccountBalanceCalculator`:
    - введено протокол `AccountBalanceCalculating`;
    - instance methods замість static.
  - `Account`:
    - додано `@Transient` залежності `enabledCurrenciesCodec` і `balanceCalculator`;
    - залежності можна інжектити через `init` (з дефолтними реалізаціями).
  - `TransactionService`:
    - замість static enum API -> протокол `TransactionServicing` + клас `TransactionService`;
    - `NewTransactionView` приймає інжектований `transactionService`.
  - `AccountGroupBalanceService`:
    - введено протокол `AccountGroupBalanceServicing` + інстансний клас;
    - інжекція сервісу в `AccountGroupHeaderView`;
    - протокол/реалізація позначені `@MainActor`.

- ViewModel-рефакторинг (View-first -> VM-first):
  - Додано `WIMM/ViewModels/NewTransactionViewModel.swift`:
    - винесено валідації, сортування/фільтрацію, preload/sync полів, `save(...)`;
    - DI через `TransactionServicing`.
  - Додано `WIMM/ViewModels/ReportsViewModel.swift`:
    - винесено month options, агрегацію даних, конвертацію валют, totals/missing;
    - DI через `ExchangeRateProvider`.
  - `WIMM/Views/NewTransactionView.swift`:
    - переведено на `@StateObject` ViewModel;
    - View містить лише bindings + UI (без бізнес-логіки).
  - `WIMM/Views/ReportsView.swift`:
    - переведено на `@StateObject` ViewModel;
    - View містить лише bindings + рендер графіків.

- Unit test templates:
  - додано `WIMMTests/NewTransactionViewModelTests.swift`
    - шаблон тесту фільтрації категорій;
    - шаблон тесту `save` через мок `TransactionServicing`.
  - додано `WIMMTests/ReportsViewModelTests.swift`
    - шаблон тесту month options;
    - шаблон тесту агрегації/конвертації з мок `ExchangeRateProvider`.
  - виправлено конфлікт типів у тестах (`Category` vs `objc_category`) через `WIMM.Category`.

- Повний ViewModel refactor для інших View:
  - Додано:
    - `WIMM/ViewModels/AccountsViewModel.swift`
    - `WIMM/ViewModels/CategoriesViewModel.swift`
    - `WIMM/ViewModels/HistoryViewModel.swift`
    - `WIMM/ViewModels/SettingsViewModel.swift`
    - `WIMM/ViewModels/AddAccountViewModel.swift`
    - `WIMM/ViewModels/AddCategoryViewModel.swift`
    - `WIMM/ViewModels/ManageAccountsViewModel.swift`
  - Переведено на ViewModel:
    - `WIMM/Views/AccountsView.swift`
    - `WIMM/Views/CategoriesView.swift`
    - `WIMM/Views/HistoryView.swift`
    - `WIMM/Views/SettingsView.swift`
    - `WIMM/Views/AddAccountView.swift`
    - `WIMM/Views/AddCategoryView.swift`
    - `WIMM/Views/SettingsManagementViews.swift`

- Моки винесено в окремі файли:
  - `WIMMTests/Mocks/ServiceMocks.swift`
  - `WIMMTests/Mocks/TestDataFactory.swift`

- Додано тести на нові ViewModel:
  - `WIMMTests/AccountsViewModelTests.swift`
  - `WIMMTests/CategoriesViewModelTests.swift`
  - `WIMMTests/HistoryViewModelTests.swift`
  - `WIMMTests/AddAccountViewModelTests.swift`
  - `WIMMTests/AddCategoryViewModelTests.swift`
  - `WIMMTests/ManageAccountsViewModelTests.swift`
  - `WIMMTests/ManageCategoriesViewModelTests.swift`
  - `WIMMTests/EditAccountCurrenciesViewModelTests.swift`
  - `WIMMTests/SettingsViewModelTests.swift`

## Релевантні файли
- `WIMM/Models/Entities/AccountGroup.swift`
- `WIMM/Models/Entities/Account.swift`
- `WIMM/Models/Entities/Category.swift`
- `WIMM/Models/Entities/Transaction.swift`
- `WIMM/Models/Enums/CurrencyCode.swift`
- `WIMM/Models/Enums/CategoryKind.swift`
- `WIMM/Models/Enums/TransactionKind.swift`
- `WIMM/Models/Support/AccountEnabledCurrenciesCodec.swift`
- `WIMM/Models/Support/AccountBalanceCalculator.swift`
- `WIMM/Models/SchemaMigration.swift`
- `WIMM/Services/TransactionService.swift`
- `WIMM/Services/ExchangeRateService.swift`
- `WIMM/Services/Money.swift`
- `WIMM/WIMMApp.swift`
- `WIMM/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `WIMM/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- `WIMM/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png`
- `WIMM/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted.png`
- `WIMM/Views/ReportsView.swift`
- `WIMM/ViewModels/NewTransactionViewModel.swift`
- `WIMM/ViewModels/ReportsViewModel.swift`
- `WIMM/ViewModels/AccountsViewModel.swift`
- `WIMM/ViewModels/CategoriesViewModel.swift`
- `WIMM/ViewModels/HistoryViewModel.swift`
- `WIMM/ViewModels/SettingsViewModel.swift`
- `WIMM/ViewModels/AddAccountViewModel.swift`
- `WIMM/ViewModels/AddCategoryViewModel.swift`
- `WIMM/ViewModels/ManageAccountsViewModel.swift`
- `WIMMTests/NewTransactionViewModelTests.swift`
- `WIMMTests/ReportsViewModelTests.swift`
- `WIMMTests/Mocks/ServiceMocks.swift`
- `WIMMTests/Mocks/TestDataFactory.swift`
- `WIMMTests/AccountsViewModelTests.swift`
- `WIMMTests/CategoriesViewModelTests.swift`
- `WIMMTests/HistoryViewModelTests.swift`
- `WIMMTests/AddAccountViewModelTests.swift`
- `WIMMTests/AddCategoryViewModelTests.swift`
- `WIMMTests/ManageAccountsViewModelTests.swift`
- `WIMMTests/ManageCategoriesViewModelTests.swift`
- `WIMMTests/EditAccountCurrenciesViewModelTests.swift`
- `WIMMTests/SettingsViewModelTests.swift`

## Build status
- Після DI-рефакторингу: `BUILD SUCCEEDED`.
- Після ViewModel-рефакторингу:
  - `xcodebuild -project WIMM.xcodeproj -scheme WIMM -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
  - Результат: `BUILD SUCCEEDED`.
- Після додавання test templates:
- Після повного ViewModel refactor + окремих mocks:
  - `xcodebuild -project WIMM.xcodeproj -scheme WIMM -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
  - Результат: `BUILD SUCCEEDED`.
  - `xcodebuild -project WIMM.xcodeproj -scheme WIMM -destination 'generic/platform=iOS Simulator' build-for-testing`
  - Результат: `TEST BUILD SUCCEEDED`.
- Після додавання test templates:
  - `xcodebuild -project WIMM.xcodeproj -scheme WIMM -destination 'generic/platform=iOS Simulator' build-for-testing`
  - Результат: `TEST BUILD SUCCEEDED`.
- `WIMM/Views/AddAccountView.swift`
- `WIMM/Views/NewTransactionView.swift`
- `WIMM/Views/AccountsView.swift`
- `WIMM/Views/SettingsManagementViews.swift`
- `WIMM/Views/CategoriesView.swift`
- `WIMM/Views/HistoryView.swift`

## Узгоджені UX-правила (актуально)
1. `+` є на Accounts, Categories, History і відкриває `NewTransaction` (default: expense).
2. Tap на рахунку (Accounts) -> `NewTransaction` з preselected account.
3. Tap на категорії (Categories) -> `NewTransaction` з preselected category.
4. У виборі рахунку показується `AccountGroup • Account`.
5. Категорії income/expense розділені і фільтруються за типом транзакції.
6. Коментар (`note`) відображається в History.
7. В transfer у History показується напрямок переказу (from -> to).

## Гарячий фікс (latest-9)
- Симптом: після запуску app списки `Accounts/Categories/History/Settings Management` були порожні, хоча `Reports` показував дані.
- Причина: після переходу на ViewModel частина екранів залежала від `ViewModel.update(...)` і не завжди отримувала актуалізацію з `@Query` при первинному/пізнішому завантаженні.
- Виправлення:
  - замінено синхронізацію `onAppear/onChange` на `task(id:)` із стабільним ключем синхронізації:
    - `WIMM/Views/AccountsView.swift`
    - `WIMM/Views/CategoriesView.swift`
    - `WIMM/Views/HistoryView.swift`
    - `WIMM/Views/SettingsManagementViews.swift`
- Додатково:
  - `BUILD SUCCEEDED` після фіксу.

## Гарячий фікс (latest-10)
- Симптом: після додавання рахунків/категорій через Settings дані зникали або зʼявлялись із затримкою.
- Причина: ViewModel кешували копії масивів із `@Query` (`update(...)` + локальний state), через що виникала розсинхронізація між source-of-truth і відображенням.
- Виправлення: для екранів з проблемою прибрано кешування `@Query` у ViewModel.
  - ViewModel тепер працюють як pure-функції над вхідними масивами з View.
  - Оновлено:
    - `WIMM/ViewModels/AccountsViewModel.swift`
    - `WIMM/ViewModels/CategoriesViewModel.swift`
    - `WIMM/ViewModels/HistoryViewModel.swift`
    - `WIMM/ViewModels/ManageAccountsViewModel.swift`
  - Перепідключено View:
    - `WIMM/Views/AccountsView.swift`
    - `WIMM/Views/CategoriesView.swift`
    - `WIMM/Views/HistoryView.swift`
    - `WIMM/Views/SettingsManagementViews.swift`
- Перевірка:
  - `xcodebuild ... build` -> `BUILD SUCCEEDED`
  - `xcodebuild ... build-for-testing` -> `TEST BUILD SUCCEEDED`

## Архітектурний refactor (latest-11)
- Запроваджено повний шар `Repository/Store` для SwiftData:
  - `WIMM/Repositories/FinanceRepository.swift`
  - `FinanceRepositorying` (протокол)
  - `SwiftDataFinanceRepository` (реалізація)
  - `ModelContext` інжектиться в repository.

- Шаблон тепер такий для всіх екранів:
  - `View` = тільки UI + тригери.
  - `ViewModel` = бізнес-логіка + оркестрація.
  - `Repository` = fetch/save/delete/create (SwiftData).

- Прибрано пряму роботу з `@Query`/`ModelContext` як джерелом даних у View:
  - `AccountsView`, `CategoriesView`, `HistoryView`, `ReportsView`, `NewTransactionView`, `SettingsManagementViews`, `AddAccountView`, `AddCategoryView` тепер викликають ViewModel, а ViewModel працюють через `FinanceRepository`.

- ViewModel оновлені для завантаження через repository:
  - `AccountsViewModel`, `CategoriesViewModel`, `HistoryViewModel`, `ReportsViewModel`, `NewTransactionViewModel`, `AddAccountViewModel`, `AddCategoryViewModel`, `ManageAccountsViewModel`, `ManageCategoriesViewModel`, `EditAccountCurrenciesViewModel`.

- Перевірка після refactor:
  - `xcodebuild -project WIMM.xcodeproj -scheme WIMM -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` -> `BUILD SUCCEEDED`
  - `xcodebuild -project WIMM.xcodeproj -scheme WIMM -destination 'generic/platform=iOS Simulator' build-for-testing` -> `TEST BUILD SUCCEEDED`

## Feature update (latest-12)
- Додано поле кольору категорії:
  - `WIMM/Models/Entities/Category.swift`: `colorHex: String?`.
- Додано міграцію без втрати даних:
  - `WIMM/Models/SchemaMigration.swift`:
    - додано `WIMMSchemaV3`;
    - додано stage `lightweight V2 -> V3`.
  - `WIMM/WIMMApp.swift`:
    - контейнер переведено на `Schema(versionedSchema: WIMMSchemaV3.self)`.

- Додано палітру кольорів категорій (20 кольорів) і hex->Color мапінг:
  - `WIMM/Services/CategoryColorPalette.swift`.

- Додано компактний модальний color picker:
  - `WIMM/Views/CategoryColorPickerSheet.swift`.

- Категорії: створення/редагування з вибором кольору:
  - `WIMM/ViewModels/AddCategoryViewModel.swift` (нове поле `colorHex`).
  - `WIMM/Views/AddCategoryView.swift` (кнопка Color + маленький sheet).
  - `WIMM/ViewModels/ManageAccountsViewModel.swift` (`ManageCategoriesViewModel` + `EditCategoryViewModel`):
    - якщо у категорії є транзакції: можна змінити лише `name` і `color`;
    - якщо транзакцій немає: можна змінити `name`, `kind`, `color`;
    - delete категорії заблоковано, якщо є транзакції.
  - `WIMM/Views/SettingsManagementViews.swift`:
    - Manage Categories розділено на 2 таби (`Expense` / `Income`);
    - редагування категорій через sheet.

- Рахунки/групи: редагування і правила:
  - `WIMM/ViewModels/ManageAccountsViewModel.swift`:
    - якщо по рахунку є транзакції: editable тільки `name`, `icon`;
    - якщо транзакцій немає: editable `name`, `icon`, `group`, `currencies`, `primary currency`;
    - delete рахунку заблоковано, якщо є транзакції.
  - `WIMM/Views/SettingsManagementViews.swift`:
    - додано `EditAccountView` (sheet) з умовним UI залежно від правил;
    - групи рахунків можна перейменовувати завжди.

- History: видалення транзакцій:
  - `WIMM/ViewModels/HistoryViewModel.swift`:
    - додано `delete(entry:using:)`;
    - для transfer видаляються обидві транзакції по `transferGroupId`.
  - `WIMM/Views/HistoryView.swift`:
    - swipe-to-delete для записів.

- Reports: колір сегментів/барів за кольором категорії:
  - `WIMM/ViewModels/ReportsViewModel.swift`:
    - `CategoryChartItem` тепер містить `colorHex`;
    - агрегація враховує колір категорії.
  - `WIMM/Views/ReportsView.swift`:
    - bar/pie використовують `CategoryColorPalette.color(hex:)`.

- Тести:
  - `WIMMTests/ManageCategoriesViewModelTests.swift` оновлено під нову сигнатуру сортування/фільтрації.

- Build note:
  - локальна перевірка `xcodebuild` у поточному середовищі блокується падінням `CoreSimulator` сервісів (`simdiskimaged`), тому фінальну compile-верифікацію потрібно підтвердити в Xcode на машині користувача.

## Hotfix (latest-13): Duplicate version checksums
- Симптом:
  - краш на старті при створенні `ModelContainer`:
  - `NSInvalidArgumentException: Duplicate version checksums detected.`
- Причина:
  - `WIMMSchemaV1/V2/V3` посилались на ті самі поточні `@Model` типи, тому SwiftData обчислював дубльовані checksums між версіями.
- Виправлення:
  - `WIMM/WIMMApp.swift` переведено на створення контейнера без `migrationPlan`, напряму через поточні моделі:
    - `ModelContainer(for: AccountGroup.self, Account.self, Category.self, Transaction.self, ...)`
  - це прибирає checksum-конфлікт і залишає автоматичну lightweight migration для сумісних змін.
- Важливо:
  - якщо потрібні саме явні versioned migrations, треба робити snapshot-моделі по версіях (`WIMMSchemaV2.Account`, `WIMMSchemaV3.Account`, ...), а не посилатись на одні й ті самі runtime-класи в різних версіях.

## UX fix (latest-14): явне редагування в Settings
- Симптом:
  - користувач не бачить/не знаходить редагування рахунків, категорій, груп рахунків.
- Виправлення:
  - `WIMM/Views/SettingsManagementViews.swift`:
    - tap по рядку `Account Group` відкриває перейменування групи;
    - tap по рядку `Account` відкриває `Edit Account`;
    - tap по рядку `Category` відкриває `Edit Category`;
    - додано іконку `pencil` у рядках для явної affordance.
- Бізнес-правила редагування/видалення не змінювались:
  - account з транзакціями: editable лише name/icon; delete заборонено;
  - category з транзакціями: editable лише name/color; delete заборонено;
  - account group: rename завжди дозволено.

## DI pattern (latest-15): зовнішнє створення ViewModel для Accounts
- Мета:
  - прибрати створення `AccountsViewModel` всередині `AccountsView`;
  - підготувати pattern для повного DI на всі екрани.

- Що зроблено:
  - Додано composition-root контейнер:
    - `WIMM/Dependencies/AppDependencies.swift`
    - відповідає за фабрики:
      - `makeFinanceRepository(modelContext:)`
      - `makeAccountsViewModel(modelContext:)`
      - `makeAccountGroupBalanceService()`

  - Додано host/scene для екрана Accounts:
    - `WIMM/Views/AccountsScene.swift`
    - створює `@StateObject AccountsViewModel` ззовні через `AppDependencies` і передає його в `AccountsView`.

  - Оновлено `AccountsView`:
    - `WIMM/Views/AccountsView.swift`
    - тепер приймає:
      - `@ObservedObject var viewModel: AccountsViewModel`
      - `let makeBalanceService: () -> AccountGroupBalanceServicing`
    - більше не створює `ViewModel` самостійно.

  - Оновлено `AccountsViewModel`:
    - `WIMM/ViewModels/AccountsViewModel.swift`
    - інжекція `repository` через `init(repository:)`
    - `load()` без параметрів (працює через інжектовану залежність).

  - Підключено в `ContentView`:
    - `WIMM/ContentView.swift`
    - додано `@StateObject private var dependencies = AppDependencies()`
    - вкладка Accounts тепер рендериться через `AccountsScene(modelContext:dependencies:)`.

  - Оновлено тести під новий ініціалізатор VM:
    - `WIMMTests/AccountsViewModelTests.swift`
    - VM створюється з `SwiftDataFinanceRepository` на in-memory `ModelContext`.

- Pattern для масштабування:
  - `App`/`Content` тримає `AppDependencies`.
  - Для кожного екрану додається `*Scene` host, що створює VM.
  - Сам `*View` приймає готову VM через інжекцію.

## DI масштабування (latest-16): патерн розмножено на всі екрани
- Мета:
  - прибрати створення `ViewModel` всередині `View` для всіх основних екранів і модалок;
  - підготувати код до unit-тестів (чітка композиція залежностей).

- Додано/оновлено DI фабрики:
  - `WIMM/Dependencies/AppDependencies.swift`:
    - фабрики для всіх VM:
      - `makeCategoriesViewModel`
      - `makeHistoryViewModel`
      - `makeReportsViewModel`
      - `makeSettingsViewModel`
      - `makeManageAccountsViewModel`
      - `makeManageCategoriesViewModel`
      - `makeAddAccountViewModel`
      - `makeAddCategoryViewModel(initialKind:)`
      - `makeNewTransactionViewModel(...)`
    - фабрики сервісів/репозиторіїв:
      - `makeFinanceRepository(modelContext:)`
      - `makeAccountGroupBalanceService()`

- Нові `*Scene` host-и (створюють VM зовні через dependencies):
  - `WIMM/Views/CategoriesScene.swift`
  - `WIMM/Views/HistoryScene.swift`
  - `WIMM/Views/ReportsScene.swift`
  - `WIMM/Views/SettingsScene.swift`
  - `WIMM/Views/ManageAccountsScene.swift`
  - `WIMM/Views/ManageCategoriesScene.swift`
  - `WIMM/Views/AddAccountScene.swift`
  - `WIMM/Views/AddCategoryScene.swift`
  - `WIMM/Views/NewTransactionScene.swift`
  - (раніше додано `WIMM/Views/AccountsScene.swift`)

- Оновлено `View`-шари: тепер приймають готові VM (ObservedObject) і фабрики залежностей:
  - `WIMM/Views/AccountsView.swift`
  - `WIMM/Views/CategoriesView.swift`
  - `WIMM/Views/HistoryView.swift`
  - `WIMM/Views/ReportsView.swift`
  - `WIMM/Views/SettingsView.swift`
  - `WIMM/Views/SettingsManagementViews.swift`
  - `WIMM/Views/AddAccountView.swift`
  - `WIMM/Views/AddCategoryView.swift`
  - `WIMM/Views/NewTransactionView.swift`

- Оновлено root wiring:
  - `WIMM/ContentView.swift` тепер рендерить у всіх табах `*Scene`, не raw `*View`.

- Точкові зміни у VM/tests:
  - `WIMM/ViewModels/AccountsViewModel.swift` має `init(repository:)` + `load()`.
  - `WIMMTests/AccountsViewModelTests.swift` оновлено під DI-ініціалізатор.

- Поточний архітектурний стан:
  - `View` = dumb UI + bindings/події;
  - `Scene` = створення VM + композиція залежностей;
  - `AppDependencies` = composition root-фабрики;
  - `Repository` = доступ до SwiftData.

## DI polish (latest-17)
- Прибрано останній self-init VM у header-підвʼю Accounts:
  - `WIMM/Views/AccountsView.swift`
  - `AccountGroupHeaderView` більше не створює `AccountGroupHeaderViewModel`, а працює напряму з `balanceService` + локальним `@State summaryText`.
- Видалено тепер непотрібний `AccountGroupHeaderViewModel`:
  - `WIMM/ViewModels/AccountsViewModel.swift`.

- У `SettingsManagementViews` також прибрано локальне створення VM в edit/rename sheet-вью:
  - `EditAccountView`, `EditCategoryView`, `RenameEntityView` переведені на `@ObservedObject` VM, які створюються в parent sheet closure.

## Architecture hardening (latest-18)
- Прибрано щільну звʼязаність `View -> конкретний Scene type`.
- Замість цього `View` приймають фабрики у вигляді `AnyView`:
  - `AccountsView.makeNewTransactionView`
  - `CategoriesView.makeNewTransactionView`
  - `HistoryView.makeNewTransactionView`
  - `SettingsView.makeManageAccountsView / makeManageCategoriesView`
  - `ManageAccountsView.makeAddAccountView`
  - `ManageCategoriesView.makeAddCategoryView`
- Оновлені `*Scene` обгортають дочірні сцени через `AnyView(...)`.

- Додаткова перевірка:
  - у `Views/` більше немає прямого `@Environment(\.modelContext)` і `SwiftDataFinanceRepository(...)`;
  - `View` працюють лише через інжектовані VM/factory closures.

- Стан build у sandbox:
  - через обмеження середовища і недоступні simulator runtimes (`No available simulator runtimes for platform iphonesimulator`) повна валідація `xcodebuild` тут неможлива;
  - логи не показали Swift compile errors з коду, падіння відбувається на runtime/tooling-рівні середовища.

## Views restructuring + previews (latest-19)
- Виконано повний рефактор структури View:
  - `Views/ContentView.swift` перенесено в `Views/`.
  - Створено структуру папок:
    - `Views/ReusableViews/`
    - `Views/ReusableViews/Forms/`
    - `Views/SceneViews/`
    - `Views/TabViews/`
  - `TabViews`: `AccountsView`, `CategoriesView`, `HistoryView`, `ReportsView`, `SettingsView`.
  - `SceneViews`: всі `*Scene` файли.
  - `ReusableViews`: менеджмент-екрани і форми, color picker, preview support.

- Розбиття великих view:
  - `SettingsManagementViews.swift` видалено.
  - Створено окремі файли:
    - `Views/ReusableViews/ManageAccountsView.swift`
    - `Views/ReusableViews/ManageCategoriesView.swift`
    - `Views/ReusableViews/Forms/EditAccountView.swift`
    - `Views/ReusableViews/Forms/EditCategoryView.swift`
    - `Views/ReusableViews/Forms/RenameEntityView.swift`
  - Внутрішні рядки винесено в дрібні subviews (`AccountGroupRowView`, `AccountRowView`, `CategoryRowView`).

- Прев’ю:
  - додані `#Preview` для кожної View/Scene/форма.
  - створено `Views/ReusableViews/PreviewSupport.swift` для in-memory контексту та фейкового rate provider.

- Поточний стан build:
  - `xcodebuild` у sandbox продовжує падати через недоступні simulator runtimes;
  - Swift compile errors не відображаються в логах (ймовірно, код компілюється в нормальному Xcode середовищі).

## Rows extraction (latest-20)
- Заповнено папку `Views/ReusableViews/Rows`:
  - `AccountGroupRowView`
  - `AccountRowView`
  - `CategoryRowView`
- Відповідні inline-rows прибрані з:
  - `Views/ReusableViews/ManageAccountsView.swift`
  - `Views/ReusableViews/ManageCategoriesView.swift`

## View decomposition (latest-27)
- Декомпозиція `NewTransactionView`:
  - `Views/ReusableViews/NewTransaction/TransactionTypePickerView.swift`
  - `Views/ReusableViews/NewTransaction/IncomeExpenseFieldsView.swift`
  - `Views/ReusableViews/NewTransaction/TransferFieldsView.swift`
  - `Views/ReusableViews/NewTransaction/TransactionMetaSectionView.swift`
  - `Views/ReusableViews/Forms/NewTransactionView.swift` тепер компонує з цих частин.

- Декомпозиція `ReportsView`:
  - `Views/ReusableViews/Reports/ReportsMonthPickerView.swift`
  - `Views/ReusableViews/Reports/ReportsChartTypePickerView.swift`
  - `Views/ReusableViews/Reports/ReportsChartView.swift`
  - `Views/ReusableViews/Reports/ReportsTotalsView.swift`
  - `Views/ReusableViews/Reports/ReportsMissingRatesView.swift`
  - `Views/TabViews/ReportsView.swift` тепер компонує з цих частин.

- Додаткові rows:
  - `Views/ReusableViews/Rows/AccountRowView.swift`
  - `Views/ReusableViews/Rows/CategorySummaryRowView.swift`
  - `Views/TabViews/AccountsView.swift` і `Views/TabViews/CategoriesView.swift` оновлені для використання rows.

- Прев’ю:
  - `#Preview` додані для всіх нових під‑view.

## Next steps (пропозиція)
1. Додати тести для нових сценаріїв:
   - delete restriction для account/category;
   - account/category edit permission matrix;
   - history transfer delete (видалення пари транзакцій).
2. Додати тести на міграції (мінімум сценарій підняття зі старого стору).

## Як продовжити в новій сесії
"Продовжимо з `CONTEXT_HANDOFF_2026-03-06.md`, стан після переходу на versioned schema/migration plan (локальна SwiftData без CloudKit)."

## Unit tests expansion (latest-27)
- Додано нові unit-тести для бізнес-логіки та сервісів (без UI):
  - `WIMMTests/MoneyTests.swift`
  - `WIMMTests/AccountEnabledCurrenciesCodecTests.swift`
  - `WIMMTests/AccountBalanceCalculatorTests.swift`
  - `WIMMTests/TransactionServiceTests.swift`
  - `WIMMTests/AccountGroupBalanceServiceTests.swift`
  - `WIMMTests/EditEntityViewModelTests.swift`
- Розширено існуючі тести:
  - `WIMMTests/NewTransactionViewModelTests.swift`
  - `WIMMTests/ManageAccountsViewModelTests.swift`
  - `WIMMTests/ManageCategoriesViewModelTests.swift`
  - `WIMMTests/HistoryViewModelTests.swift`
  - `WIMMTests/ReportsViewModelTests.swift`
  - `WIMMTests/AddAccountViewModelTests.swift`
  - `WIMMTests/AddCategoryViewModelTests.swift`
  - `WIMMTests/AccountsViewModelTests.swift`
  - `WIMMTests/CategoriesViewModelTests.swift`
  - `WIMMTests/EditAccountCurrenciesViewModelTests.swift`
  - `WIMMTests/SettingsViewModelTests.swift`
- Нові сценарії покриття:
  - баланс по валютах, кодування enabled currencies, Money parsing/format;
  - TransactionService validations/transfer rules;
  - delete transfer/transaction у History;
  - missing FX rates у Reports;
  - можливість/обмеження редагування/видалення Accounts/Categories;
  - діапазон сортування, tap-handlers, та default behaviors.

### Build/test status (latest-27)
- `xcodebuild -project WIMM.xcodeproj -scheme WIMM -destination 'generic/platform=iOS Simulator' build-for-testing`
  - Результат: `TEST BUILD FAILED` через помилки SimRuntime (XPC simdiskimaged crash). Локальні компіляційні помилки не зафіксовані.

## Unit test scheme + warnings fix (latest-27)
- Виправлено `#expect(false, ...)` в `TransactionServiceTests`:
  - замість завжди-фейлячих очікувань тепер перевіряється конкретна помилка через `caught`.
- Додано shared scheme для запуску всіх unit тестів одним запуском:
  - `WIMM.xcodeproj/xcshareddata/xcschemes/WIMM-UnitTests.xcscheme`
  - у TestAction включено `WIMMTests` target.

## Scheme visibility fix (latest-27)
- Додано копію `WIMM-UnitTests.xcscheme` у workspace shared schemes:
  - `WIMM.xcodeproj/project.xcworkspace/xcshareddata/xcschemes/WIMM-UnitTests.xcscheme`
- Це потрібно, якщо Xcode відкриває workspace і не бачить схем з .xcodeproj.

## Test fix (latest-27)
- В `EditAccountViewModel.toggleCurrency` додано захист від порожнього списку валют:
  - якщо після вимкнення валюти список порожній, повертається primary назад.
  - це стабілізує тест `editAccountViewModelMaintainsPrimaryCurrency()`.

## History day sections (latest-27)
- History тепер розбиває записи по днях через секції:
  - `HistoryViewModel.DaySection` + `sections(from:)`.
  - `HistoryView` рендерить `Section` з хедером дати і елементами за день.
- Дата прибрана з рядка елемента (вона в хедері секції).

## History header formatting (latest-27)
- Хедери секцій у History тепер формуються як:
  - Today / Yesterday для поточних днів,
  - інакше формат `d MMM yyyy`.
- Логіка в `HistoryViewModel.sectionTitle(for:)`.

## Reports refresh + FX DI cleanup + tests (latest-28)
- `ReportsViewModel.taskKey` тепер враховує стабільний підпис транзакцій, щоб перерахунок звіту тригерився при зміні суми/дати/валюти без зміни кількості.
- `ExchangeRateProvider` отримав `convert(...)` з дефолтною реалізацією; `AccountGroupBalanceService` більше не робить каст до `FrankfurterRateProvider`.
- Додані тести:
  - `WIMMTests/ExchangeRateCacheTests.swift`
  - `WIMMTests/HistoryViewModelTests.swift` (перевірка видалення transfer-групи)
  - `WIMMTests/ReportsViewModelTests.swift` (taskKey змінюється при зміні деталей транзакції).

## DI unification + cache TTL + formatter cache (latest-29)
- ViewModel-и тепер отримують репозиторій через `init`, `load()` більше не приймає залежності; Views/Scenes/Previews оновлені відповідно.
- `NewTransactionViewModel` має єдиний `save()` з винесеною в приватні методи валідацією/побудовою save action (без дублювання логіки).
- `Money.format(...)` кешує `NumberFormatter` по `CurrencyCode`.
- `ExchangeRateCache` використовує TTL 12 годин для валідності кешу.
- Оновлені тести для нового DI і додано перевірку TTL в `ExchangeRateCacheTests`.

### Build/test status (latest-29)
- `xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator,name=iPhone 15' test`
  - `CoreSimulatorService connection became invalid` / sandbox restrictions; тести не стартували.

## Preview fix for NewTransaction fields (latest-30)
- В `IncomeExpenseFieldsView` та `TransferFieldsView` прибрано `return` з `#Preview` (result builder), і оновлено прев’ю під новий DI (`NewTransactionViewModel(repository:)` + `loadData`).
  - Повторний запуск `xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator,name=iPhone 15' test` знову впав на `CoreSimulatorService connection became invalid` (sandbox restriction).
  - `#Preview` повернуто у стандартний стиль (як в інших файлах), без `let _ =` для `loadData`, щоб уникнути `Type of expression is ambiguous`.

## EditAccountCurrenciesViewModel DI fix (latest-31)
- `EditAccountCurrenciesViewModel` тепер приймає `FinanceRepositorying` через `init`, щоб не було `repository` out-of-scope.
- Оновлено тести `EditAccountCurrenciesViewModelTests` під новий init.

## UseCases + RepositoryProvider refactor (latest-32)
- Додано `WIMM/UseCases`: `ReportsUseCase`, `HistoryUseCase`, `NewTransactionUseCase`; бізнес-логіка винесена з відповідних ViewModel.
- `HistoryEntryTone/HistoryEntry/HistoryDaySection` переїхали у `HistoryUseCase`; `HistoryViewModel` тепер використовує `HistoryUseCase` для побудови entries/sections/sectionTitle.
- `ReportsViewModel` тепер делегує агрегацію до `ReportsUseCase`.
- `NewTransactionViewModel` тепер використовує `NewTransactionUseCase` для load/save.
- `AppDependencies` тепер конфігурується один раз через `configure(modelContext:)` і містить готові VM/repository; `Scenes` більше не прокидають `modelContext`.
- `ContentView` показує `ProgressView` до завершення `configure(...)`.
- Додані/оновлені тести для `HistoryViewModel` (sectionTitle Today/Yesterday) та FX провайдера (`FrankfurterRateProviderTests`) з мокнутим `URLSession`.
- Додано `MockURLProtocol` для тестів URLSession.

### Build/test status (latest-32)
- `xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator,name=iPhone 15' test`
  - `CoreSimulatorService connection became invalid` / sandbox restrictions; тести не стартували.

## HistoryUseCase DI fix (latest-33)
- HistoryViewModel більше не створює HistoryUseCase() у default init (це викликало Call to main actor-isolated initializer), тепер use case інжектиться ззовні.
- Оновлено HistoryView preview і HistoryViewModelTests під новий init.

### Build/test status (latest-33)
- xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator' test
  - CoreSimulatorService connection became invalid / sandbox restrictions; тести не стартували.

## ReportsUseCase DI fix (latest-34)
- ReportsViewModel більше не створює ReportsUseCase в init, use case інжектиться ззовні.
- Додано ReportsUseCase.defaultSelectedMonthStart() для дефолтного місяця.
- Оновлено AppDependencies, ReportsView preview та ReportsViewModelTests під новий init.

### Build/test status (latest-34)
- xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator' test
  - CoreSimulatorService connection became invalid / sandbox restrictions; тести не стартували.

## DI cleanup (latest-35)
- SwiftDataFinanceRepository більше не створює TransactionService всередині, тепер DI виконується у AppDependencies/Preview/Test коді.
- FrankfurterRateProvider більше не має default параметрів; session/cache/calendar інжектяться зовні.
- HistoryUseCase і ReportsUseCase більше не створюють DateFormatter усередині; форматери інжектяться через DateFormatting.
- ReportsViewModel тепер приймає monthLabelFormatter через init.
- Додано DateFormatting/DateFormatterFactory для стандартних форматерів.
- Оновлено всі previews та тести під нові init сигнатури.

### Build/test status (latest-35)
- xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator' test
  - CoreSimulatorService connection became invalid / sandbox restrictions; тести не стартували.

## Categories sorting + amount color (latest-36)
- Expense categories у CategoriesView тепер сортуються за сумою витрат поточного місяця (desc).
- CategorySummaryRowView більше не фарбує суму червоним, використовується стандартний колір.
- Додано unit‑тест для сортування за витратами.

### Build/test status (latest-36)
- xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator' test
  - CoreSimulatorService connection became invalid / sandbox restrictions; тести не стартували.

## Category list dot (latest-37)
- CategorySummaryRowView тепер показує кольорову крапку з colorHex перед назвою категорії в CategoriesView.
- Оновлено preview та виклики CategorySummaryRowView.

### Build/test status (latest-37)
- xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator' test
  - CoreSimulatorService connection became invalid / sandbox restrictions; тести не стартували.

## UseCase coverage (latest-38)
- Додані unit‑тести для NewTransactionUseCase, ReportsUseCase, HistoryUseCase.
- Розширені TransactionServiceTests: invalidAmount і currencyNotEnabledForAccount для createIncome/createExpense/createTransfer.

### Build/test status (latest-38)
- xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator' test
  - CoreSimulatorService connection became invalid / sandbox restrictions; тести не стартували.

## NewTransactionUseCaseTests catch fix (latest-39)
- Додано загальний catch у NewTransactionUseCaseTests для вичерпності обробки помилок.

### Build/test status (latest-39)
- xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator' test
  - CoreSimulatorService connection became invalid / sandbox restrictions; тести не стартували.

## EditAccountCurrenciesViewModelTests fix (latest-40)
- Оновлено тест: save(account:using:) -> save(account:), щоб відповідати новому init+repository DI.

### Build/test status (latest-40)
- xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator' test
  - CoreSimulatorService connection became invalid / sandbox restrictions; тести не стартували.

## NewTransactionViewModelTests fix (latest-41)
- saveTransferUsesRepository тепер використовує той самий MockFinanceRepository, щоб перевірки createTransferCalls/transactions були валідні.

### Build/test status (latest-41)
- xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator' test
  - CoreSimulatorService connection became invalid / sandbox restrictions; тести не стартували.

## NewTransactionViewModelTests scope fix (latest-42)
- В transferRequiresAmountToWhenCurrenciesDiffer повернуто MockFinanceRepository (repo не був у скоупі).

### Build/test status (latest-42)
- xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator' test
  - CoreSimulatorService connection became invalid / sandbox restrictions; тести не стартували.

## NewTransactionViewModelTests repo fix (latest-43)
- saveTransferUsesRepository тепер використовує repo у ViewModel, щоб очікування createTransferCalls/transactions були валідні.

### Build/test status (latest-43)
- xcodebuild -project WIMM.xcodeproj -scheme WIMM-UnitTests -destination 'platform=iOS Simulator' test
  - CoreSimulatorService connection became invalid / sandbox restrictions; тести не стартували.

## FrankfurterRateProviderTests warning fix (latest-44)
- Замінено `#expect(false)` на `#expect(throws: ExchangeRateError.self)` у негативних тестах, щоб прибрати warning від макроса `expect`.

### Build/test status (latest-44)
- Not run (not requested).

## NewTransactionViewModelTests repo fix (latest-45)
- `saveTransferUsesRepository` тепер ініціалізує `NewTransactionViewModel` тим самим `repo`, що й перевірки `createTransferCalls/transactions`.

### Build/test status (latest-45)
- Not run (not requested).

## FrankfurterRateProviderTests serialization fix (latest-46)
- Додано `@Suite(.serialized)` для `FrankfurterRateProviderTests`, щоб уникнути гонок за `MockURLProtocol.requestHandler` під час паралельних тестів.

### Build/test status (latest-46)
- Not run (not requested).

## NewTransactionUseCaseTests warning fix (latest-47)
- У двох тестах використано `#expect(throws: TransactionServiceError.self)` замість `#expect(false, ...)`, щоб прибрати warning і перевірити тип помилки.

### Build/test status (latest-47)
- Not run (not requested).

## CategoriesView monthly expense scale (latest-48)
- Додано розрахунок частки витрат по категорії за поточний місяць і відображення зеленої шкали під назвою категорії.
- Оновлено `CategorySummaryRowView` і додано тест для `expenseProgress`.

### Build/test status (latest-48)
- Not run (not requested).

## CategoriesView progress calculation fix (latest-49)
- Перенесено розрахунок прогресу в `CategoriesViewModel` (`expenseProgressByCategory`) та прибрано назву-помилку параметра, що конфліктувала з методом.

### Build/test status (latest-49)
- Not run (not requested).
