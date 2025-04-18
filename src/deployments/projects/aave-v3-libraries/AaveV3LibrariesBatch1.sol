// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../contracts/LibraryReportStorage.sol';
import {Create2Utils} from '../../contracts/utilities/Create2Utils.sol';
import {BorrowLogic} from '../../../contracts/protocol/libraries/logic/BorrowLogic.sol';
import {BridgeLogic} from '../../../contracts/protocol/libraries/logic/BridgeLogic.sol';
import {ConfiguratorLogic} from '../../../contracts/protocol/libraries/logic/ConfiguratorLogic.sol';
import {EModeLogic} from '../../../contracts/protocol/libraries/logic/EModeLogic.sol';

contract AaveV3LibrariesBatch1 is LibraryReportStorage {
  constructor() {
    _librariesReport = _deployAaveV3Libraries();
  }

  function _deployAaveV3Libraries() internal returns (LibrariesReport memory libReport) {
    libReport.borrowLogic = _deployLibrary(type(BorrowLogic).creationCode);
    libReport.bridgeLogic = _deployLibrary(type(BridgeLogic).creationCode);
    libReport.configuratorLogic = _deployLibrary(type(ConfiguratorLogic).creationCode);
    libReport.eModeLogic = _deployLibrary(type(EModeLogic).creationCode);
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