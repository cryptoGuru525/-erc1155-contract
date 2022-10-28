//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Domain.sol";

interface PoseidonInterface {
  function poseidon(bytes32[3] memory input) external pure returns(bytes32);
  function poseidon(uint256[3] memory input) external pure returns(uint256);
}

interface RainbowTableInterface {
  function reveal(uint256[] memory preimage, uint256 hash) external;
  function lookup(uint256 hash) external returns (uint256[] memory preimage);
  function getHash(uint256 hash, uint256[] calldata preimage) external view returns (uint256);
  function isRevealed(uint256 hash) external view returns (bool);
}

contract ResolverRegistry {
  ContractRegistryInterface contractRegistry;

  // to achieve data clearing, we observe event logs
  event ResolverSet(uint256 indexed name, uint256 indexed hash, uint256[] path, address resolver, uint256 datasetId);

  // name => subdomain hash => resolver address
  mapping(uint256 => mapping(uint256 => address)) resolvers;

  // name => subdomain hash => dataset id (on the specified resolver)
  mapping(uint256 => mapping(uint256 => uint256)) datasetIds;
  
  function set(uint256 name, uint256[] memory path, address resolver, uint256 datasetId) public {
    _canWrite(name);
    RainbowTableInterface rainbowTable = RainbowTableInterface(contractRegistry.get('RainbowTable'));
    uint256 hash;
    if (path.length > 0) {
      hash = rainbowTable.getHash(name, path);
    } else {
      hash = name;
    }
    resolvers[name][hash] = resolver;
    datasetIds[name][hash] = datasetId;
    emit ResolverSet(name, hash, path, resolver, datasetId);
  }

  function get(uint256 name, uint256 hash) public view returns (address resolver, uint256 datasetId) {
    require(resolvers[name][hash] != address(0), "ResolverRegistry: resolver not set");
    return (resolvers[name][hash], datasetIds[name][hash]);
  }

  function _canWrite(uint256 name) internal view {
    Domain domain = Domain(contractRegistry.get('Domain'));
    require(domain.balanceOf(msg.sender, name) > 0, "ResolverRegistry: not owner");
    require(!domain.isSuspended(name), "ResolverRegistry: domain suspended");
  }

  constructor(address contractRegistryAddress) {
    contractRegistry = ContractRegistryInterface(contractRegistryAddress);
  }
}