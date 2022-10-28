//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

interface PricingOracleInterface {
  function getPriceForName(uint256 name, bytes memory data) external view returns (uint256 price, uint256 priceCentsUsd);
  function convertWeiToUsdCents(uint256 amount) external view returns (uint256 usdCents);
}


// File contracts/VerifierInterface.sol

interface VerifierInterface {
  function verifyProof(bytes memory proof, uint[] memory pubSignals) external view returns (bool);
}


contract PricingOracle is PricingOracleInterface {
  using SafeCast for int256;
  AggregatorV3Interface immutable public priceFeed;
  VerifierInterface immutable public _verifier;

  function _getLatestRoundData() internal view returns (uint256 price) {
    if (address(priceFeed) == address(0)) {
      return 10000000000;
    } else {
      (
        ,
        int feedPrice,
        ,
        ,
        
      ) = priceFeed.latestRoundData();
      return feedPrice.toUint256();
    }
  }

  function _getWeiPerUSDCent() internal view returns (uint256 price) {
    uint256 feedPrice = _getLatestRoundData();
    require(feedPrice > 0, "PricingOracle: Chainlink Oracle returned feedPrice of 0");
    uint256 factor = 10**24;
    return factor / feedPrice;
  }

  function getPriceForName(
    uint256 name, 
    bytes memory data
  ) external view override returns (uint256 price, uint256 priceCentsUsd) {
    uint[] memory pubSignals;
    bytes memory proof;
    (pubSignals, proof) = abi.decode(data, (uint[], bytes));
    require(pubSignals.length == 2, "PricingOracle: Invalid pubSignals");
    require(pubSignals[0] == name, "PricingOracle: Hash doesnt match");
    uint256 minLength = pubSignals[1];
    require(minLength >= 1, "PricingOracle: Length less than 1");
    uint256 namePrice = 500;
    if (minLength == 3) {
      namePrice = 900;
    } else if (minLength == 4) {
      namePrice = 700;
    }
    uint256 weiPerUSDCent = _getWeiPerUSDCent();
    uint256 _price = namePrice * weiPerUSDCent;
    return (_price, namePrice);
  }

  function convertWeiToUsdCents(
    uint256 amount
  ) external view override returns (uint256 usdCents) {
    uint256 weiPerUsdCent = _getWeiPerUSDCent();
    return amount / weiPerUsdCent;
  }

  constructor(VerifierInterface verifier) {
    _verifier = verifier;
    uint256 id;
    assembly {
      id := chainid()
    }
    address priceFeedAddress;
    if (id == 1) {
      priceFeedAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    } else if (id == 5) {
      priceFeedAddress = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
    }
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }
}