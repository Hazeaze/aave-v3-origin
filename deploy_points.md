# Пошаговое Руководство по Деплою Форка Aave V3 на Новую Сеть (с использованием aave-v3-origin)

Это руководство описывает процесс развертывания форка протокола Aave V3 на новую EVM-совместимую блокчейн-сеть, используя репозиторий `aave-v3-origin` и инструментарий Foundry.

**Предупреждение:** Деплой и настройка Aave V3 — это сложный и рискованный процесс. Любые ошибки могут привести к уязвимостям и потере средств. Требуется глубокое понимание протокола и тщательное тестирование. Это руководство не является исчерпывающим и может потребовать адаптации под специфику вашей сети.

## Этап 1: Подготовка и Конфигурация

### 1.1 Пререквизиты
- Установленный [Foundry](https://getfoundry.sh/).
- Локальная копия репозитория `aave-dao/aave-v3-origin`.
- Доступ к RPC-узлу для новой сети.
- Аккаунт (приватный ключ) с достаточным количеством нативного токена для оплаты газа в новой сети.
- API-ключ для блок-эксплорера новой сети (аналог Etherscan), если планируется верификация контрактов.

### 1.2 Установка Зависимостей
В корневой директории проекта выполните:
```bash
forge install
forge update # Опционально, для обновления зависимостей
```

### 1.3 Настройка Переменных Окружения (`.env`)
Создайте файл `.env` из `.env.example`:
```bash
cp .env.example .env
```
Отредактируйте `.env` и заполните **минимум** следующие переменные:

- **RPC Эндпоинт Новой Сети:**
  ```env
  RPC_<NEW_CHAIN_NAME>=<https://your_new_chain_rpc_url>
  ```
- **API Ключ Эксплорера:**
  ```env
  ETHERSCAN_API_KEY_<NEW_CHAIN_NAME>=<your_explorer_api_key>
  ```
- **Данные Деплоера:**
  ```env
  PRIVATE_KEY=<your_deployer_private_key>
  SENDER=<your_deployer_address> # Адрес, соответствующий PRIVATE_KEY
  ```

### 1.4 Настройка Foundry (`foundry.toml`)
Откройте `foundry.toml` и добавьте конфигурацию для вашей новой сети:

- **В секции `[rpc_endpoints]`:**
  ```toml
  <new_chain_name> = "${RPC_<NEW_CHAIN_NAME>}"
  ```
- **В секции `[etherscan]`:**
  ```toml
  <new_chain_name> = { key = "${ETHERSCAN_API_KEY_<NEW_CHAIN_NAME>}", chainId = <ID_вашей_сети>, url = "<api_url_эксплорера_если_не_стандартный>" }
  ```
  *(Замените `<ID_вашей_сети>` и `<api_url_эксплорера_если_не_стандартный>` на актуальные значения для вашей сети).*
- **(Опционально) Профиль Сети:** Если требуются особые настройки EVM.
  ```toml
  [profile.<new_chain_name>]
  evm_version = '<нужная_версия_evm>' # например, 'london' или 'shanghai'
  ```

### 1.5 Создание Конфигурации Рынка (`*MarketInput.sol`)
Этот шаг определяет параметры *вашего* рынка Aave V3.

1.  **Скопируйте:** `cp src/deployments/inputs/DefaultMarketInput.sol src/deployments/inputs/NewChainMarketInput.sol`
2.  **Отредактируйте `NewChainMarketInput.sol`:**
    - Измените имя контракта на `NewChainMarketInput`.
    - В функции `_getMarketInput` **внимательно настройте параметры**, специфичные для вашей сети:
        - `config.marketId`: Уникальное имя (e.g., "Aave V3 NewChain Market").
        - `config.providerId`: Уникальный ID.
        - `config.wrappedNativeToken`: **Критически важно!** Адрес канонического WETH/WBNB/WMATIC и т.д. в *новой* сети.
        - `config.oracleDecimals`, `config.flashLoanPremiumTotal`, `config.flashLoanPremiumToProtocol`: Настройте по необходимости.
        - `config.networkBaseTokenPriceInUsdProxyAggregator`, `config.marketReferenceCurrencyPriceInUsdProxyAggregator`: Адреса оракулов Chainlink (или аналога) для базового токена сети и USD в *новой* сети. **Необходимы рабочие оракулы!**
        - Другие параметры (`paraswapAugustusRegistry`, `l2SequencerUptimeFeed` и т.д.): Заполните, если релевантно, иначе оставьте `address(0)`.
        - `roles`: Укажите адреса `marketOwner`, `poolAdmin`, `emergencyAdmin`.

### 1.6 Создание Скрипта Деплоя Рынка (`*Deploy*.sol`)
Этот скрипт будет использовать вашу конфигурацию для запуска деплоя.

1.  **Скопируйте:** `cp scripts/DeployAaveV3MarketBatched.sol scripts/DeployAaveV3MarketBatchedNewChain.sol`
2.  **Отредактируйте `DeployAaveV3MarketBatchedNewChain.sol`:**
    ```solidity
    // SPDX-License-Identifier: BUSL-1.1
    pragma solidity ^0.8.0; // Убедитесь, что версия совпадает с foundry.toml

    import {DeployAaveV3MarketBatchedBase} from './misc/DeployAaveV3MarketBatchedBase.sol';
    // ИЗМЕНИТЕ ИМПОРТ на ваш файл конфигурации
    import {NewChainMarketInput} from '../src/deployments/inputs/NewChainMarketInput.sol';

    // ИЗМЕНИТЕ ИМЯ КОНТРАКТА и унаследуйтесь от вашей конфигурации
    contract NewChain is DeployAaveV3MarketBatchedBase, NewChainMarketInput {}
    ```

## Этап 2: Деплой Библиотек

Библиотеки Aave V3 деплоятся с использованием Create2 для получения предсказуемых адресов.

```bash
# Укажите имя вашей сети из foundry.toml
export CHAIN_NAME=<new_chain_name>

# Деплой и верификация первой группы библиотек
make deploy-libs-one chain=$CHAIN_NAME

# Деплой и верификация второй группы библиотек
make deploy-libs-two chain=$CHAIN_NAME
```
*Команды `make` включают шаг верификации через `npx catapulta-verify`, который использует данные из `broadcast/` и `foundry.toml`.*

## Этап 3: Деплой Основного Рынка

Запустите ваш кастомный скрипт деплоя, созданный на шаге 1.6.

```bash
# Имя сети из foundry.toml
export CHAIN_NAME=<new_chain_name>
# Путь к вашему скрипту и имя контракта
export DEPLOY_SCRIPT=scripts/DeployAaveV3MarketBatchedNewChain.sol:NewChain

# Опции аутентификации
export AUTH_OPTS="--private-key $PRIVATE_KEY"

forge script $DEPLOY_SCRIPT \
  --rpc-url $CHAIN_NAME \
  --broadcast \
  $AUTH_OPTS \
  --slow # Рекомендуется для реальных сетей
```
- Этот скрипт запустит `AaveV3BatchOrchestration.deployAaveV3`, который развернет все основные контракты (Pool, Configurator, Tokens, Oracle, ACL, DataProvider и т.д.).
- Следите за выводом консоли. Информация о деплое (адреса, транзакции) будет сохранена в `broadcast/DeployAaveV3MarketBatchedNewChain.sol/<chainId>/`.

## Этап 4: Пост-Деплойные Действия

### 4.1 Верификация Контрактов Рынка
Используйте `catapulta-verify` для верификации контрактов, задеплоенных на предыдущем шаге.

```bash
# ID вашей сети
export CHAIN_ID=<ID_вашей_сети>
# Путь к broadcast файлу
export BROADCAST_FILE=broadcast/DeployAaveV3MarketBatchedNewChain.sol/${CHAIN_ID}/run-latest.json

npx catapulta-verify -b $BROADCAST_FILE
```

### 4.2 Настройка Рынка (Критически Важный Этап!)

На данный момент контракты развернуты, но рынок пуст и не готов к работе. Этот этап включает добавление активов, настройку параметров риска и подключение оракулов. **Этот этап требует особой внимательности, точных данных для вашей сети и обычно выполняется отдельным скриптом Foundry.**

**Основные Контракты для Конфигурации:**

*   **`PoolConfigurator`**: Управляет параметрами резервов, E-Mode, лимитами. Вызывается `POOL_ADMIN`.
*   **`AaveOracle`**: Связывает активы с их источниками цен. Вызывается `ASSET_LISTING_ADMIN` (часто `POOL_ADMIN`).

**Рекомендуемый подход:** Создайте новый скрипт Foundry (e.g., `scripts/ConfigureNewChainMarket.s.sol`) для выполнения следующих транзакций конфигурации. Этот скрипт должен читать адреса `PoolConfigurator` и `AaveOracle` из broadcast-файла основного деплоя.

**Пошаговая Настройка через Скрипт:**

1.  **Получение Адресов Конфигураторов:**
    *   В скрипте прочитайте адреса `PoolConfigurator` и `AaveOracle` из файла `broadcast/.../run-latest.json`.

2.  **Инициализация Резервов (`PoolConfigurator.initReserves`)**
    *   **Цель:** Добавить каждый ERC20 актив в протокол.
    *   **Действие:** Для *каждого* актива подготовьте структуру `ConfiguratorInputTypes.InitReserveInput` и вызовите `initReserves`, передав массив этих структур.
    *   **Ключевые поля `InitReserveInput`:**
        *   `aTokenImpl`, `variableDebtTokenImpl`: Адреса *имплементаций* (обычно одинаковые для всех, задеплоены ранее).
        *   `underlyingAsset`: Адрес базового ERC20 токена в *новой* сети.
        *   `underlyingAssetDecimals`: Десятичные знаки базового токена.
        *   `interestRateStrategyAddress`: Адрес стратегии ставок (можно использовать `DefaultInterestRateStrategy` или кастомную).
        *   `treasury`: Адрес контракта `Collector`.
        *   `aTokenName`, `aTokenSymbol`, `variableDebtTokenName`, `variableDebtTokenSymbol`: Имена и символы для Aave-токенов.
    *   **Пример (фрагмент скрипта):**
        ```solidity
        // ... получение адресов configurator, oracle, treasury, имплементаций ...
        IPoolConfigurator configurator = IPoolConfigurator(CONFIGURATOR_ADDRESS);

        ConfiguratorInputTypes.InitReserveInput[] memory inputs = new ConfiguratorInputTypes.InitReserveInput[](2); // Пример для 2 активов
        // Настройка для USDC
        inputs[0] = ConfiguratorInputTypes.InitReserveInput({
            aTokenImpl: ATOKEN_IMPL_ADDRESS, variableDebtTokenImpl: VAR_DEBT_IMPL_ADDRESS,
            underlyingAssetDecimals: 6, interestRateStrategyAddress: DEFAULT_STRATEGY_ADDRESS,
            underlyingAsset: USDC_ADDRESS, treasury: TREASURY_ADDRESS, incentivesController: address(0),
            aTokenName: "Aave NewChain USDC", aTokenSymbol: "aNewUSDC",
            variableDebtTokenName: "Aave NewChain Variable Debt USDC", variableDebtTokenSymbol: "varNewUSDC",
            params: ""
        });
        // Настройка для WETH
        inputs[1] = ConfiguratorInputTypes.InitReserveInput({
            aTokenImpl: ATOKEN_IMPL_ADDRESS, variableDebtTokenImpl: VAR_DEBT_IMPL_ADDRESS,
            underlyingAssetDecimals: 18, interestRateStrategyAddress: DEFAULT_STRATEGY_ADDRESS,
            underlyingAsset: WETH_ADDRESS, treasury: TREASURY_ADDRESS, incentivesController: address(0),
            aTokenName: "Aave NewChain WETH", aTokenSymbol: "aNewWETH",
            variableDebtTokenName: "Aave NewChain Variable Debt WETH", variableDebtTokenSymbol: "varNewWETH",
            params: ""
        });

        vm.startBroadcast(POOL_ADMIN_PK); // Использовать ключ POOL_ADMIN
        configurator.initReserves(inputs);
        vm.stopBroadcast();
        ```

3.  **Настройка Параметров Риска (`PoolConfigurator.configureReserveAsCollateral`)**
    *   **Цель:** Разрешить использование актива как залог и определить его параметры риска.
    *   **Действие:** Для *каждого* актива, который будет залогом, вызовите `configureReserveAsCollateral`.
    *   **Параметры:**
        *   `asset`: Адрес базового ERC20 токена.
        *   `ltv`: Loan-to-Value (в bps, e.g., 8000 = 80%).
        *   `liquidationThreshold`: Порог ликвидации (в bps, e.g., 8500 = 85%).
        *   `liquidationBonus`: Бонус ликвидатора (в bps, e.g., 10500 = 5% бонус).
    *   **Пример (фрагмент скрипта):**
        ```solidity
        // Настройка для USDC как залога
        vm.startBroadcast(POOL_ADMIN_PK);
        configurator.configureReserveAsCollateral(USDC_ADDRESS, 8000, 8500, 10500);
        // Настройка для WETH как залога
        configurator.configureReserveAsCollateral(WETH_ADDRESS, 7500, 8000, 10500);
        vm.stopBroadcast();
        ```

4.  **Установка Источников Цен (`AaveOracle.setAssetSources`)**
    *   **Цель:** Связать каждый актив с его оракулом цены.
    *   **Действие:** Вызовите `setAssetSources`, передав два *соответствующих* массива: адреса активов и адреса их оракулов в новой сети.
    *   **Пример (фрагмент скрипта):**
        ```solidity
        IAaveOracle oracle = IAaveOracle(ORACLE_ADDRESS);

        address[] memory assets = new address[](2);
        assets[0] = USDC_ADDRESS;
        assets[1] = WETH_ADDRESS;

        address[] memory sources = new address[](2);
        sources[0] = CHAINLINK_USDC_USD_FEED; // Адрес оракула USDC/USD в новой сети
        sources[1] = CHAINLINK_WETH_USD_FEED; // Адрес оракула WETH/USD в новой сети

        vm.startBroadcast(POOL_ADMIN_PK); // Или ASSET_LISTING_ADMIN_PK
        oracle.setAssetSources(assets, sources);
        vm.stopBroadcast();
        ```

5.  **(Рекомендуется) Установка Лимитов (`PoolConfigurator.setSupplyCap`, `PoolConfigurator.setBorrowCap`)**
    *   **Цель:** Ограничить риски путем установки максимального объема предложения и заимствования.
    *   **Действие:** Для *каждого* актива вызовите `setSupplyCap` и `setBorrowCap`.
    *   **Параметры:** Адрес актива и лимит в *единицах базового токена* (e.g., `1_000_000 * 1e6` для 1 млн USDC).
    *   **Пример (фрагмент скрипта):**
        ```solidity
        uint256 usdcSupplyCap = 100_000_000 * 1e6; // 100M USDC
        uint256 usdcBorrowCap = 80_000_000 * 1e6;  // 80M USDC
        uint256 wethSupplyCap = 50_000 * 1e18; // 50k WETH
        uint256 wethBorrowCap = 40_000 * 1e18;  // 40k WETH

        vm.startBroadcast(POOL_ADMIN_PK);
        configurator.setSupplyCap(USDC_ADDRESS, usdcSupplyCap);
        configurator.setBorrowCap(USDC_ADDRESS, usdcBorrowCap);
        configurator.setSupplyCap(WETH_ADDRESS, wethSupplyCap);
        configurator.setBorrowCap(WETH_ADDRESS, wethBorrowCap);
        vm.stopBroadcast();
        ```

6.  **(Опционально) Другие Настройки:**
    *   **Резервный Фактор (`PoolConfigurator.setReserveFactor`):** Установка процента дохода, идущего в казну (в bps).
    *   **Активация/Деактивация Резервов (`PoolConfigurator.setReserveActive`):** По умолчанию активны после инициализации.
    *   **Включение/Выключение Заимствования (`PoolConfigurator.setReserveBorrowing`):** По умолчанию включено.
    *   **Настройка E-Mode (`PoolConfigurator.setEModeCategory`, `PoolConfigurator.setAssetEModeCategory`):** Для создания категорий с повышенной эффективностью заимствования (e.g., для стейблкоинов).
    *   **Комиссия Протокола при Ликвидации (`PoolConfigurator.setLiquidationProtocolFee`):** Установка комиссии для казны при ликвидациях (в bps).

**Запуск Скрипта Конфигурации:**
Выполните созданный скрипт конфигурации (например, `ConfigureNewChainMarketScript`) аналогично шагу 3, используя аутентификационные данные `POOL_ADMIN`.

```bash
# ... Установка переменных CHAIN_NAME, CONFIG_SCRIPT, AUTH_OPTS (для POOL_ADMIN) ...

forge script $CONFIG_SCRIPT \
  --rpc-url $CHAIN_NAME \
  --broadcast \
  $AUTH_OPTS \
  --slow
```
**Крайне важно тщательно протестировать этот скрипт конфигурации в локальном форке или тестнете перед запуском в основной сети! Неправильные параметры могут сделать рынок неработоспособным или уязвимым.**

### 4.3 Финальное Тестирование
После деплоя и конфигурации проведите **исчерпывающее тестирование** всех основных функций протокола в *новой* сети:
- Supply (Внесение средств)
- Borrow (Заимствование)
- Withdraw (Вывод средств)
- Repay (Погашение долга)
- Liquidation (Ликвидация)
- Переключение процентных ставок (если применимо)
- Проверка E-Mode (если настроено)
- Корректность отображения данных через `ProtocolDataProvider`.
- Взаимодействие с оракулами (проверка цен).

Убедитесь, что все работает как ожидается, прежде чем объявлять о запуске рынка.