//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";

/*
Casing is not enforced here. Users must be careful not to
implement duplicates by casing errors, e.g. by adding
WETH and wEth and weth as namespaces.

Casing rules are to be enforced by the MANAGER role.
*/

interface NamespaceInterface {
  function checkName(uint256 id, uint256 name, bytes memory constraintsData) external view;
}


// File contracts/ConstraintsInterface.sol

interface ConstraintsInterface {
  function check(uint256 namespace, uint256 name, bytes memory data) external view;
}



contract Namespace is NamespaceInterface, AccessControl {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

  mapping(uint256 => bool) public _initializedNamespaces;
  mapping(uint256 => ConstraintsInterface) public _constraints;

  event GracePeriodLengthSet(uint256 indexed namespaceId, uint256 gracePeriodLength);
  event ConstraintsSet(uint256 indexed namespaceId, ConstraintsInterface constraints);

  function initNamespace(uint256 id, ConstraintsInterface constraints) external onlyRole(MANAGER_ROLE) {
    require(_initializedNamespaces[id] == false, 'ALREADY_EXISTS');
    _initializedNamespaces[id] = true;
    _constraints[id] = constraints;
  }

  function _verifyNamespaceExists(uint256 id) view internal {
    require(_initializedNamespaces[id], 'DOESNT_EXIST');
  }

  function setConstraints(uint256 id, ConstraintsInterface constraints) external onlyRole(MANAGER_ROLE) {
    _verifyNamespaceExists(id);
    _constraints[id] = constraints;
    emit ConstraintsSet(id, constraints);
  }

  function checkName(
    uint256 id,
    uint256 name,
    bytes memory constraintsData
  ) external view override {
    _verifyNamespaceExists(id);
    _constraints[id].check(id, name, constraintsData);
  }
  
  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }
}