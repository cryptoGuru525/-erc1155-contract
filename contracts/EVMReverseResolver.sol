//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Domain.sol";

// File contracts/ReverseResolverAuthenticatorInterface.sol

interface ReverseResolverAuthenticatorInterface {
  function canWrite(uint256 name, uint256[] memory path, address sender) external view returns (bool);
}

// File contracts/RainbowTableInterface.sol

interface RainbowTableInterface {
  function reveal(uint256[] memory preimage, uint256 hash) external;
  function lookup(uint256 hash) external returns (uint256[] memory preimage);
  function getHash(uint256 hash, uint256[] calldata preimage) external view returns (uint256);
  function isRevealed(uint256 hash) external view returns (bool);
}


contract EVMReverseResolver {
  ContractRegistryInterface public immutable contractRegistry;

  event EntrySet(uint256 indexed name, uint256[] path, address target);

  struct Entry {
    uint256 name;
    uint256 hash;
  }

  // name => hash => msg.sender, used for data clearing
  mapping(uint256 => mapping(uint256 => address)) entries;

  // EVM address => hash => subdomain hash
  mapping(address => Entry) reverseLookups;

  // set the reverse for the name.
  function set(uint256 name, uint256[] calldata path) external {
    ReverseResolverAuthenticatorInterface reverseResolverRegistry = ReverseResolverAuthenticatorInterface(contractRegistry.get('ReverseResolverRegistry'));
    require(reverseResolverRegistry.canWrite(name, path, msg.sender), "EVMReverseResolver: not authorized");
    uint256 hash = _getHash(name, path);

    // unset the existing entry for hash
    address currAddress = entries[name][hash];
    Entry memory currEntry = reverseLookups[currAddress];
    if (currEntry.name != 0 && currEntry.hash != 0) {
      reverseLookups[currAddress] = Entry(0, 0);
      entries[currEntry.name][currEntry.hash] = address(0);
    }

    // unset the existing entry for this sender
    currEntry = reverseLookups[msg.sender];
    if (currEntry.name != 0 && currEntry.hash != 0) {
      entries[currEntry.name][currEntry.hash] = address(0);
    }

    reverseLookups[msg.sender] = Entry(name, hash);
    entries[name][hash] = msg.sender;
    emit EntrySet(name, path, msg.sender);
  }

  // remove the reverse for the name
  function clear(uint256 name, uint256[] calldata path) external {
    ReverseResolverAuthenticatorInterface reverseResolverRegistry = ReverseResolverAuthenticatorInterface(contractRegistry.get('ReverseResolverRegistry'));
    uint256 hash = _getHash(name, path);
    address currAddress = entries[name][hash];
    if (currAddress == msg.sender) {
      reverseLookups[msg.sender] = Entry(0, 0);
    } else {
      require(reverseResolverRegistry.canWrite(name, path, msg.sender), "EVMReverseResolver: not authorized");
      reverseLookups[currAddress] = Entry(0, 0);
    }
    entries[name][hash] = address(0);
    emit EntrySet(name, path, address(0));
  }

  // get the name for an address
  function get(address target) external view returns (uint256 name, uint256 hash) {
    Domain domain = Domain(contractRegistry.get('Domain'));
    Entry memory entry = reverseLookups[target];
    require(entry.name != 0 && entry.hash != 0, "EVMReverseResolver: does not exist");
    require(!domain.isSuspended(entry.name), "EVMReverseResolver: domain suspended");
    return (entry.name, entry.hash);
  }

  // get the entry for a name / hash pair. used for data clearing.
  function getEntry(uint256 name, uint256 hash) external view returns (address entry) {
    Domain domain = Domain(contractRegistry.get('Domain'));
    require(!domain.isSuspended(name), "EVMReverseResolver: domain suspended");
    return entries[name][hash];
  }

  // computes the hash for a set of labels. each label is represented by two
  // indicies in the preimage[] array. uses hash to start (use "0" to start
  // from nothing).
  function _getHash(uint256 hash, uint256[] calldata preimage) internal view returns (uint256) {
    if (preimage.length == 0) return hash;
    RainbowTableInterface rainbowTable = RainbowTableInterface(contractRegistry.get('RainbowTable'));
    return rainbowTable.getHash(hash, preimage);
  }

  constructor(ContractRegistryInterface _contractRegistry) {
    contractRegistry = _contractRegistry;
  }
}