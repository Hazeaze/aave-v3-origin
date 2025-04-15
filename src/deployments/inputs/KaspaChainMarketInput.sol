// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './MarketInput.sol';

contract KaspaChainMarketInput is MarketInput {
  function _getMarketInput(
    address deployer
  )
    internal
    pure
    override
    returns (
      Roles memory roles,
      MarketConfig memory config,
      DeployFlags memory flags,
      MarketReport memory deployedContracts
    )
  {
    roles.marketOwner = deployer;
    roles.emergencyAdmin = deployer;
    roles.poolAdmin = deployer;

    //TODO: Add addresses of Chainlink (or analog) for the network base token and USD in the new network
    config.networkBaseTokenPriceInUsdProxyAggregator = address(0); 
    config.marketReferenceCurrencyPriceInUsdProxyAggregator = address(0); 

    config.marketId = 'Kaspa Chain Market';
    config.oracleDecimals = 8;

    config.paraswapAugustusRegistry = address(0); //TODO: Add paraswap augustus registry or may a 0x0 address
    config.l2SequencerUptimeFeed = address(0); //TODO: Add l2 sequencer uptime feed or may a 0x0 address
    config.l2PriceOracleSentinelGracePeriod = 0; //TODO: Add l2 price oracle sentinel grace period or may a 0

    config.providerId = 777;
    config.salt = bytes32(0); //TODO: Add salt if needed
    config.wrappedNativeToken = address(0); // TODO: Add kas wrapped native token
    config.flashLoanPremiumTotal = 0.0005e4;
    config.flashLoanPremiumToProtocol = 0.0004e4;

    config.incentivesProxy = address(0); //TODO: Add incentives proxy
    config.treasury = address(0); //TODO: Add treasury
    config.treasuryPartner = address(0); //TODO: Add treasury partner
    config.treasurySplitPercent = 0; //TODO: Add treasury split percent

    flags.l2 = true;

    return (roles, config, flags, deployedContracts);
  }
}
