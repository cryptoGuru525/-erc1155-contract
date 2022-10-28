//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/AccessControl.sol";


// File contracts/ConstraintsInterface.sol

pragma solidity ^0.8.0;

interface ConstraintsInterface {
  function check(uint256 namespace, uint256 name, bytes memory data) external view;
}


// File contracts/VerifierInterface.sol

pragma solidity ^0.8.0;

interface VerifierInterface {
  function verifyProof(bytes memory proof, uint[] memory pubSignals) external view returns (bool);
}


// File contracts/ConstraintsV1.sol

pragma solidity ^0.8.0;


contract ConstraintsV1 is ConstraintsInterface, AccessControl {
  VerifierInterface public _verifier;
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
  mapping(uint256 => bool) _blockedNames;
  event NamesBlocked(uint256[] names, bool blocked);
  event VerifierSet(VerifierInterface verifier);

  function check(
    uint256 namespace,
    uint256 name, 
    bytes calldata data
  ) external view override {
    uint[] memory pubSignals;
    bytes memory proof;
    (pubSignals, proof) = abi.decode(data, (uint[], bytes));
    require(pubSignals.length == 2, "ConstraintsV1: Invalid pubSignals length");
    require(namespace == pubSignals[0], "ConstraintsV1: Proof doesn't match namespace");
    require(name == pubSignals[1], "ConstraintsV1: Proof doesn't match provided name");
    require(!_blockedNames[name], "ConstraintsV1: Name blocked");
    require(_verifier.verifyProof(proof, pubSignals), "ConstraintsV1: Verifier failed");
  }

  function blockNames(
    uint256[] calldata names
  ) external onlyRole(MANAGER_ROLE) {
    for (uint256 i = 0; i < names.length; i += 1) {
      _blockedNames[names[i]] = true;
    }
    emit NamesBlocked(names, true);
  }

  function unblockNames(
    uint256[] calldata names
  ) external onlyRole(MANAGER_ROLE) {
    for (uint256 i = 0; i < names.length; i += 1) {
      _blockedNames[names[i]] = false;
    }
    emit NamesBlocked(names, false);
  }

  function isNameBlocked(uint256 name) external view returns (bool) {
    return _blockedNames[name];
  }

  function setVerifier(
    VerifierInterface verifier
  ) external onlyRole(MANAGER_ROLE) {
    _verifier = verifier;
    emit VerifierSet(verifier);
  }

  constructor(VerifierInterface verifier) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _verifier = verifier;
  }
}