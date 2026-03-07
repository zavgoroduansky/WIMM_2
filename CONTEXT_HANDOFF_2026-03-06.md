# WIMM Handoff (Updated 2026-03-06, latest)

## Поточний стан
Проєкт: `/Users/ozavhorodianskyi/Documents/xCode/WIMM_2/WIMM`

Остання перевірка збірки:
- `xcodebuild -project WIMM.xcodeproj -scheme WIMM -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
- Результат: BUILD SUCCEEDED.

## Важливе виправлення з останнього кроку
Було запитано:
1. В історії трансферу має бути видно, з якого рахунку і на який рахунок зроблено переказ.
2. На екрані Accounts загальна сума в групі має оновлюватися коректно з урахуванням різних валют.
3. Відображення символу валюти має бути уніфіковане в усьому застосунку.

Статус: виконано.

### Що саме змінено
- `HistoryView`:
  - для transfer-рядка додано явний маршрут: `Transfer: <fromGroup • fromAccount> → <toGroup • toAccount>`.

- `AccountGroupHeaderView` в `AccountsView`:
  - виправлено тригер перерахунку total;
  - `taskID` тепер включає детермінований підпис стану балансів усіх рахунків у групі (по валютах), тому після нових транзакцій сума групи перераховується.

- `Money.format`:
  - уніфіковано формат: символ валюти завжди перед числом (`€123.45`, `₴123.45`, `$123.45`) в усіх екранах, де використовується цей форматер.

## Релевантні файли
- `WIMM/Models/FinanceModels.swift`
- `WIMM/Services/TransactionService.swift`
- `WIMM/Services/ExchangeRateService.swift`
- `WIMM/Services/Money.swift`
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

## Next steps (пропозиція)
1. Drag & drop рахунків між різними групами (зараз reorder тільки в межах групи).
2. Додати фільтри на History (період/рахунок/валюта/тип).
3. Додати тести на мультивалютні сценарії.

## Як продовжити в новій сесії
"Продовжимо з `CONTEXT_HANDOFF_2026-03-06.md`, стан після фіксів History transfer details + correct group totals refresh + unified currency symbol formatting."
