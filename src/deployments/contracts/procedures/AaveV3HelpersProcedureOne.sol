// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Create2Utils} from '../utilities/Create2Utils.sol';
import {ConfigEngineReport} from '../../interfaces/IMarketReportTypes.sol';
import {AaveV3ConfigEngine, IAaveV3ConfigEngine, CapsEngine, BorrowEngine, CollateralEngine, RateEngine, PriceFeedEngine, EModeEngine, ListingEngine} from '../../../contracts/extensions/v3-config-engine/AaveV3ConfigEngine.sol';
import {IPool} from '../../../contracts/interfaces/IPool.sol';
import {IPoolConfigurator} from '../../../contracts/interfaces/IPoolConfigurator.sol';
import {IAaveOracle} from '../../../contracts/interfaces/IAaveOracle.sol';

contract AaveV3HelpersProcedureOne {
  function _deployConfigEngine(
    address pool,
    address poolConfigurator,
    address defaultInterestRateStrategy,
    address aaveOracle,
    address rewardsController,
    address collector,
    address aTokenImpl,
    address vTokenImpl
  ) internal returns (ConfigEngineReport memory configEngineReport) {
    IAaveV3ConfigEngine.EngineLibraries memory engineLibraries = IAaveV3ConfigEngine
      .EngineLibraries({
        listingEngine: _deployLibrary(type(ListingEngine).creationCode),
        eModeEngine: _deployLibrary(type(EModeEngine).creationCode),
        borrowEngine: _deployLibrary(type(BorrowEngine).creationCode),
        collateralEngine: _deployLibrary(type(CollateralEngine).creationCode),
        priceFeedEngine: _deployLibrary(type(PriceFeedEngine).creationCode),
        rateEngine: _deployLibrary(type(RateEngine).creationCode),
        capsEngine: _deployLibrary(type(CapsEngine).creationCode)
      });

    IAaveV3ConfigEngine.EngineConstants memory engineConstants = IAaveV3ConfigEngine
      .EngineConstants({
        pool: IPool(pool),
        poolConfigurator: IPoolConfigurator(poolConfigurator),
        defaultInterestRateStrategy: defaultInterestRateStrategy,
        oracle: IAaveOracle(aaveOracle),
        rewardsController: rewardsController,
        collector: collector
      });

    configEngineReport.listingEngine = engineLibraries.listingEngine;
    configEngineReport.eModeEngine = engineLibraries.eModeEngine;
    configEngineReport.borrowEngine = engineLibraries.borrowEngine;
    configEngineReport.collateralEngine = engineLibraries.collateralEngine;
    configEngineReport.priceFeedEngine = engineLibraries.priceFeedEngine;
    configEngineReport.rateEngine = engineLibraries.rateEngine;
    configEngineReport.capsEngine = engineLibraries.capsEngine;

    configEngineReport.configEngine = address(
      new AaveV3ConfigEngine(aTokenImpl, vTokenImpl, engineConstants, engineLibraries)
    );
    return configEngineReport;
  }

  // Helper function for deploying libraries
  function _deployLibrary(bytes memory bytecode) internal returns (address addr) {
    assembly {
      addr := create(0, add(bytecode, 0x20), mload(bytecode))
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }
  }
}
