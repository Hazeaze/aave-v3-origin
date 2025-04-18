// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import 'forge-std/console.sol';
import '../src/deployments/interfaces/IMarketReportTypes.sol';
import {AaveV3LibrariesBatch1} from '../src/deployments/projects/aave-v3-libraries/AaveV3LibrariesBatch1.sol';
import {AaveV3LibrariesBatch2} from '../src/deployments/projects/aave-v3-libraries/AaveV3LibrariesBatch2.sol';
import {IMetadataReporter} from '../src/deployments/interfaces/IMetadataReporter.sol';
import {DeployUtils} from '../src/deployments/contracts/utilities/DeployUtils.sol';
import {FfiUtils} from '../src/deployments/contracts/utilities/FfiUtils.sol';
import {Create2Utils} from '../src/deployments/contracts/utilities/Create2Utils.sol';

contract DeployAaveV3Libs is FfiUtils, Script, DeployUtils {
  function run() external {
    console.log('=== Aave V3 Library Deployment ===');
    console.log('Sender:', msg.sender);

    // Deploy first batch of libraries
    deployBatchOne();

    // Deploy second batch of libraries
    deployBatchTwo();

    console.log('=== Library Deployment Complete ===');
    console.log('Note: If you did not include the --verify flag, run verification manually with:');
    console.log('forge verify-contract <DEPLOYED_ADDRESS> <CONTRACT_NAME> --chain <CHAIN_ID>');
  }

  function deployBatchOne() internal {
    console.log('Deploying Batch 1 Libraries...');

    bool found = _librariesPathExists();
    if (found) {
      address lastLib = _getLatestLibraryAddress();
      if (lastLib.code.length > 0) {
        console.log('[Batch 1] Libraries detected. Skipping re-deployment.');
        return;
      } else {
        _deleteLibrariesPath();
        console.log(
          'Batch 1: FOUNDRY_LIBRARIES was detected and removed. Continuing with fresh deployment.'
        );
      }
    }

    vm.startBroadcast();
    AaveV3LibrariesBatch1 batch1 = new AaveV3LibrariesBatch1();
    vm.stopBroadcast();

    LibrariesReport memory report = batch1.getLibrariesReport();

    string memory librariesSolcString = string(abi.encodePacked(getLibraryString1(report)));

    // Write deployment JSON report
    IMetadataReporter metadataReporter = IMetadataReporter(
      _deployFromArtifacts('MetadataReporter.sol:MetadataReporter')
    );
    metadataReporter.writeJsonReportLibraryBatch1(report);

    string memory sedCommand = string(
      abi.encodePacked('echo FOUNDRY_LIBRARIES=', librariesSolcString, ' >> .env')
    );
    string[] memory command = new string[](3);

    command[0] = 'bash';
    command[1] = '-c';
    command[2] = string(abi.encodePacked('response="$(', sedCommand, ')"; $response;'));
    vm.ffi(command);

    console.log('Batch 1 Libraries deployed successfully');
  }

  function deployBatchTwo() internal {
    console.log('Deploying Batch 2 Libraries...');

    vm.startBroadcast();
    AaveV3LibrariesBatch2 batch2 = new AaveV3LibrariesBatch2();
    vm.stopBroadcast();

    LibrariesReport memory report = batch2.getLibrariesReport();

    string memory prevLibrariesString = vm.envString('FOUNDRY_LIBRARIES');
    string memory librariesSolcString = string(
      abi.encodePacked(prevLibrariesString, ',', getLibraryString2(report))
    );

    // Write deployment JSON report
    IMetadataReporter metadataReporter = IMetadataReporter(
      _deployFromArtifacts('MetadataReporter.sol:MetadataReporter')
    );
    metadataReporter.writeJsonReportLibraryBatch2(report);

    string memory sedCommand = string(
      abi.encodePacked('echo FOUNDRY_LIBRARIES=', librariesSolcString, ' > .env')
    );
    string[] memory command = new string[](3);

    command[0] = 'bash';
    command[1] = '-c';
    command[2] = string(abi.encodePacked('response="$(', sedCommand, ')"; $response;'));
    vm.ffi(command);

    console.log('Batch 2 Libraries deployed successfully');
  }

  function getLibraryString1(LibrariesReport memory report) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          'src/contracts/protocol/libraries/logic/BorrowLogic.sol:BorrowLogic:',
          vm.toString(report.borrowLogic),
          ',',
          'src/contracts/protocol/libraries/logic/BridgeLogic.sol:BridgeLogic:',
          vm.toString(report.bridgeLogic),
          ',',
          'src/contracts/protocol/libraries/logic/ConfiguratorLogic.sol:ConfiguratorLogic:',
          vm.toString(report.configuratorLogic),
          ',',
          'src/contracts/protocol/libraries/logic/EModeLogic.sol:EModeLogic:',
          vm.toString(report.eModeLogic)
        )
      );
  }

  function getLibraryString2(LibrariesReport memory report) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          'src/contracts/protocol/libraries/logic/FlashLoanLogic.sol:FlashLoanLogic:',
          vm.toString(report.flashLoanLogic),
          ',',
          'src/contracts/protocol/libraries/logic/PoolLogic.sol:PoolLogic:',
          vm.toString(report.poolLogic),
          ',',
          'src/contracts/protocol/libraries/logic/LiquidationLogic.sol:LiquidationLogic:',
          vm.toString(report.liquidationLogic),
          ',',
          'src/contracts/protocol/libraries/logic/SupplyLogic.sol:SupplyLogic:',
          vm.toString(report.supplyLogic)
        )
      );
  }
}