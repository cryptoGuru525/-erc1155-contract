//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Domain.sol";

// File contracts/PricingOracleInterface.sol

pragma solidity ^0.8.0;

interface PricingOracleInterface {
  function getPriceForName(uint256 name, bytes memory data) external view returns (uint256 price, uint256 priceCentsUsd);
  function convertWeiToUsdCents(uint256 amount) external view returns (uint256 usdCents);
}

// File contracts/RainbowTableInterface.sol

pragma solidity ^0.8.0;

interface RainbowTableInterface {
  function reveal(uint256[] memory preimage, uint256 hash) external;
  function lookup(uint256 hash) external returns (uint256[] memory preimage);
  function getHash(uint256 hash, uint256[] calldata preimage) external view returns (uint256);
  function isRevealed(uint256 hash) external view returns (bool);
}


contract LeasingAgent is AccessControl {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

  ContractRegistryInterface immutable public _contractRegistry;
  uint256 immutable public _namespaceId;
  bool public _enabled = false;
  uint256 public _premiumStartTime;
  uint256 public _premiumEndTime;
  uint256[] public _premiumPricePoints;
  event Enabled(bool enabled);
  event RegistrationPremiumSet(uint256 premiumStartTime, uint256 premiumEndTime, uint256[] premiumPricePoints);
  event Registered(uint256[] names, uint256[] quantities, uint256 payment);

  function enable(bool enabled) external onlyRole(MANAGER_ROLE) {
    _enabled = enabled;
    emit Enabled(enabled);
  }


  function setRegistrationPremiumDetails(uint256 premiumStartTime, uint256 premiumEndTime, uint256[] calldata premiumPricePoints) external onlyRole(MANAGER_ROLE) {
    require(premiumEndTime > premiumStartTime, "LeasingAgentV1: premiumEndTime must be larger than premiumStartTime");

    // each premiumPricePoint should be smaller than the previous
    for (uint256 i = 0; i < premiumPricePoints.length; i += 1) {
      if (i > 0) {
        require(premiumPricePoints[i] < premiumPricePoints[i-1], "LeasingAgentV1: premiumPricePoint[i] must be smaller than premiumPricePoint[i-1]");
      }
    }

    _premiumStartTime = premiumStartTime;
    _premiumEndTime = premiumEndTime;
    _premiumPricePoints = premiumPricePoints;
    emit RegistrationPremiumSet(premiumStartTime, premiumEndTime, premiumPricePoints);
  }

  function _registerName(
    uint256 name,
    uint256 quantity,
    bytes memory constraintsProof,
    Domain domain
  ) internal {
    require(quantity > 0, "LeasingAgentV1: invalid quantity");
    domain.register(
      msg.sender, // to
      _namespaceId, // namespace
      name, // name id
      constraintsProof
    );
  }

  function _transferToTreasury(uint256 total) internal {
    address payable _treasuryAddress = payable(_contractRegistry.get('Treasury'));
    (bool sent,) = _treasuryAddress.call{value: total}("");
    require(sent, "LeasingAgentV1: payment not sent");
  }

  // attempt to register the name.
  // compare it to hash details provided in commit
  function register(
    uint256[] calldata names, 
    uint256[] calldata quantities,
    bytes[] calldata constraintsProofs,
    bytes[] calldata pricingProofs
  ) public payable {
    require(_enabled, "LeasingAgentV1: registration disabled");
    require(names.length == constraintsProofs.length, "LeasingAgentV1: proof length mismatch");
    require(names.length == pricingProofs.length, "LeasingAgentV1: proof length mismatch");
    require(names.length == quantities.length, "LeasingAgentV1: quantities length mismatch");

    PricingOracleInterface _pricingOracle = PricingOracleInterface(_contractRegistry.get('PricingOracle'));
    Domain _domain = Domain(_contractRegistry.get('Domain'));

    uint256 total = 0;
    uint256 price;
    uint256 i;

    // get pricing for names
    for (i = 0; i < names.length; i += 1) {
      (price, /* priceCentsUsd */) = _pricingOracle.getPriceForName(names[i], pricingProofs[i]);
      total += price * quantities[i];
    }
    
    require(msg.value >= total, "LeasingAgentV1: insufficient payment");
    uint256 diff = msg.value - total;
    _transferToTreasury(total);
        // return over-payment to sender
    if (diff > 0) {
        payable(msg.sender).transfer(diff);
    }

    // register names
    emit Registered(names, quantities, msg.value);
    for (i = 0; i < names.length; i += 1) {
      _registerName(names[i], quantities[i], constraintsProofs[i], _domain);
    }
  }

  function registerWithPreimage(
    uint256[] calldata names, 
    uint256[] calldata quantities,
    bytes[] calldata constraintsProofs,
    bytes[] calldata pricingProofs,
    uint256[] calldata preimages
  ) external payable {
    require(preimages.length % 4 == 0, "LeasingAgentV1: incorrect preimage length");
    require(preimages.length / names.length == 4, "LeasingAgentV1: incorrect preimage length");
    revealImage(names, preimages);
    register(names, quantities, constraintsProofs, pricingProofs);
  }
  
  function revealImage(uint256[] calldata names, uint256[] calldata preimages) internal {
    RainbowTableInterface rainbowTable = RainbowTableInterface(_contractRegistry.get('RainbowTable'));
    for (uint256 i = 0; i < names.length; i += 1) {
      if (!rainbowTable.isRevealed(names[i])) {
        rainbowTable.reveal(preimages[i * 4:i * 4 + 4], names[i]);
      }
    }
  }

  constructor(address contractRegistryAddress, uint256 namespaceId) {
    _contractRegistry = ContractRegistryInterface(contractRegistryAddress);
    _namespaceId = namespaceId;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }
}