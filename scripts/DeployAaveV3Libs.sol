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

/**
 * # Deploy and verify on testnet (include --verify flag for automatic verification)
    forge script scripts/DeployAaveV3Libs.sol --rpc-url testnet --slow --broadcast --verify
 * # Deploy and verify on mainnet
    forge script scripts/DeployAaveV3Libs.sol --rpc-url mainnet --slow --broadcast --verify
 */
contract DeployAaveV3Libs is FfiUtils, Script, DeployUtils {
  bytes public createV2FactoryBytecode;

  constructor() {
    createV2FactoryBytecode = bytes(
      hex'604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3'
    );
  }

  function run() external {
    console.log('=== Aave V3 Library Deployment ===');
    console.log('Sender:', msg.sender);

    deployCreateV2Factory();
    // Deploy first batch of libraries
    deployBatchOne();

    // Deploy second batch of libraries
    deployBatchTwo();

    console.log('=== Library Deployment Complete ===');
    console.log('Note: If you did not include the --verify flag, run verification manually with:');
    console.log('forge verify-contract <DEPLOYED_ADDRESS> <CONTRACT_NAME> --chain <CHAIN_ID>');
  }

  function deployCreateV2Factory() internal {
    address factory;
    bytes memory bytecode = createV2FactoryBytecode;
    assembly {
      factory := create(0, add(bytecode, 0x20), mload(bytecode))
    }
    
    require(factory.code.length > 0, 'Factory deployment failed');
    require(factory == Create2Utils.CREATE2_FACTORY, 'Factory deployment failed, update the factory address in the Create2Utils');
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
