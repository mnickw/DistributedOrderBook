// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDepositary.sol";

contract Depositary is IDepositary, Ownable {
    mapping(address => SecurityContractValidationStatus) internal securityContractValidations;
    mapping(address => UserValidationStatus) internal userValidationStatus;

    function addSecurityContractValidationStatus (
        address securityContractAddr,
        SecurityContractValidationStatus status
    ) external virtual override onlyOwner returns (bool) {
        securityContractValidations[securityContractAddr] = status;
        return true;
    }
    
    function addUserValidationStatus (
        address userAddr,
        UserValidationStatus status
    ) external virtual override onlyOwner returns (bool) {
        userValidationStatus[userAddr] = status;
        return true;
    }

    function getSecurityContractValidationStatus (address securityContractAddr)
        external virtual override view returns (SecurityContractValidationStatus) {
        return securityContractValidations[securityContractAddr];
    }

    function getUserValidationStatus (address userAddr) external virtual override view returns (UserValidationStatus) {
        return userValidationStatus[userAddr];
    }
}