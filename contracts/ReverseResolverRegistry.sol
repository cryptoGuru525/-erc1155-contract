//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Domain.sol";

interface ReverseResolverAuthenticatorInterface {
  function canWrite(uint256 name, uint256[] memory path, address sender) external view returns (bool);
}

contract ReverseResolverRegistryV1 is AccessControl, ReverseResolverAuthenticatorInterface {
  bytes32 public constant MANAGER_ROLE = keccak256('MANAGER');

  event AuthenticatorSet(uint256 name, address contractAddress);
  event ResolverSet(uint256 standardKey, address resolverAddress);

  ContractRegistryInterface public immutable contractRegistry;

  // standardKey => reverse resolver address
  mapping(uint256 => address) private reverseResolvers;

  // domainName => custom authorization contract address
  mapping(uint256 => ReverseResolverAuthenticatorInterface) public authenticators;

  function setResolver(uint256 standardKey, address resolverAddress) onlyRole(MANAGER_ROLE) external {
    reverseResolvers[standardKey] = resolverAddress;
    emit ResolverSet(standardKey, resolverAddress);
  }

  function getResolver(uint256 standardKey) external view returns (address resolverAddress) {
    resolverAddress = reverseResolvers[standardKey];
    require(resolverAddress != address(0), 'ReverseResolverRegistryV1: address not set');
  }

  function canWrite(uint256 name, uint256[] memory path, address sender) external view override(ReverseResolverAuthenticatorInterface) returns (bool) {
    // this method is called by ReverseResolvers to check if the caller is
    // authorized to set a reverse resolution record for the name & the path.
    // in most cases, we simply want to check if the sender is the owner of the name
    // however, there may be cases where the owner of the name wants to authorize
    // others to set values on subdomains (e.g. where users can own subdomains)
    Domain domain = Domain(contractRegistry.get('Domain'));
    if (domain.isSuspended(name)) return false; // name suspended
    if(domain.balanceOf(msg.sender, name) > 0) {
      return true;
    }

    ReverseResolverAuthenticatorInterface authenticator = authenticators[name];
    if (address(authenticator) != address(0)) {
      return authenticator.canWrite(name, path, sender);
    } 
    return false;
  }

  function setAuthenticator(uint256 name, ReverseResolverAuthenticatorInterface authenticator) external {
    Domain domain = Domain(contractRegistry.get('Domain'));
    require(!domain.isSuspended(name), "ReverseResolverRegistryV1: domain suspended");
    require(domain.balanceOf(msg.sender, name) > 0, "ResolverRegistry: not owner");
    authenticators[name] = authenticator;
    emit AuthenticatorSet(name, address(authenticator));
  }

  constructor(ContractRegistryInterface _contractRegistry) {
    contractRegistry = _contractRegistry;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }
}