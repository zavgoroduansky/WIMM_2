# WIMM Handoff (Updated 2026-03-07, latest-9)

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

## Next steps (пропозиція)
1. Додати `WIMMSchemaV3` при наступній зміні моделей і новий stage у `WIMMMigrationPlan`.
2. Додати тести на міграції (мінімум сценарій підняття зі старого стору).

## Як продовжити в новій сесії
"Продовжимо з `CONTEXT_HANDOFF_2026-03-06.md`, стан після переходу на versioned schema/migration plan (локальна SwiftData без CloudKit)."
