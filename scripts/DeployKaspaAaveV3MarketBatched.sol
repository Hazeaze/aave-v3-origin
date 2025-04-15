// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {DeployAaveV3MarketBatchedBase} from './misc/DeployAaveV3MarketBatchedBase.sol';

import {KaspaChainMarketInput} from '../src/deployments/inputs/KaspaChainMarketInput.sol';

contract KaspaChain is DeployAaveV3MarketBatchedBase, KaspaChainMarketInput {}
