//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Domain.sol";

interface PoseidonInterface {
  function poseidon(bytes32[3] memory input) external pure returns(bytes32);
  function poseidon(uint256[3] memory input) external pure returns(uint256);
}


interface ResolverInterface {
  event StandardEntrySet(uint256 indexed name, uint256 indexed hash, uint256[] path, uint256 key, string data);
  event EntrySet(uint256 indexed name, uint256 indexed hash, uint256[] path, string key, string data);
  function resolveStandard(uint256 datasetId, uint256 hash, uint256 key) external returns (string memory data);
  function resolve(uint256 datasetId, uint256 hash, string memory key) external returns (string memory data);
}


interface RainbowTableInterface {
  function reveal(uint256[] memory preimage, uint256 hash) external;
  function lookup(uint256 hash) external returns (uint256[] memory preimage);
  function getHash(uint256 hash, uint256[] calldata preimage) external view returns (uint256);
  function isRevealed(uint256 hash) external view returns (bool);
}


contract PublicResolver is ResolverInterface {
  ContractRegistryInterface contractRegistry;
  
  // domain hash => subdomain hash => key => data
  mapping(uint256 => mapping(uint256 => mapping(uint256 => string))) standardEntries;
  mapping(uint256 => mapping(uint256 => mapping(string => string))) customEntries;

  function resolveStandard(uint256 name, uint256 hash, uint256 key) public view override returns (string memory data) {
    return standardEntries[name][hash][key];
  }

  function setStandard(uint256 name, uint256[] memory path, uint256 key, string memory data) public {
    _canWrite(name);
    uint256 hash = _getHash(name, path);
    standardEntries[name][hash][key] = data;
    emit StandardEntrySet(name, hash, path, key, data);
  }

  function resolve(uint256 name, uint256 hash, string memory key) public view override returns (string memory data) {
    return customEntries[name][hash][key];
  }

  // in this case, the name is the dataset ID
  function set(uint256 name, uint256[] memory path, string memory key, string memory data) public {
    _canWrite(name);
    uint256 hash = _getHash(name, path);
    customEntries[name][hash][key] = data;
    emit EntrySet(name, hash, path, key, data);
  }

  function _canWrite(uint256 name) internal view {
    Domain domain = Domain(contractRegistry.get('Domain'));
    require(domain.balanceOf(msg.sender, name) > 0, "ResolverRegistry: not owner");
    require(!domain.isSuspended(name), "ResolverRegistry: domain suspended");
  }

  function _getHash(uint256 hash, uint256[] memory preimage) internal view returns (uint256) {
    if (preimage.length == 0) return hash;
    RainbowTableInterface rainbowTable = RainbowTableInterface(contractRegistry.get('RainbowTable'));
    return rainbowTable.getHash(hash, preimage);
  }

  constructor(address contractRegistryAddress) {
    contractRegistry = ContractRegistryInterface(contractRegistryAddress);
  }
}