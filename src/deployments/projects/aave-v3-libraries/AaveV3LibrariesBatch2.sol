// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../contracts/LibraryReportStorage.sol';
import {Create2Utils} from '../../contracts/utilities/Create2Utils.sol';

import {FlashLoanLogic} from '../../../contracts/protocol/libraries/logic/FlashLoanLogic.sol';
import {LiquidationLogic} from '../../../contracts/protocol/libraries/logic/LiquidationLogic.sol';
import {PoolLogic} from '../../../contracts/protocol/libraries/logic/PoolLogic.sol';
import {SupplyLogic} from '../../../contracts/protocol/libraries/logic/SupplyLogic.sol';

contract AaveV3LibrariesBatch2 is LibraryReportStorage {
  constructor() {
    _librariesReport = _deployAaveV3Libraries();
  }

  function _deployAaveV3Libraries() internal returns (LibrariesReport memory libReport) {
    libReport.flashLoanLogic = _deployLibrary(type(FlashLoanLogic).creationCode);
    libReport.liquidationLogic = _deployLibrary(type(LiquidationLogic).creationCode);
    libReport.poolLogic = _deployLibrary(type(PoolLogic).creationCode);
    libReport.supplyLogic = _deployLibrary(type(SupplyLogic).creationCode);
    return libReport;
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
