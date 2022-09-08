// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IDepositary {
    enum SecurityContractValidationStatus { Invalid, Valid }
    enum UserValidationStatus { Invalid, Valid }

    function addSecurityContractValidationStatus (
        address securityContractAddr,
        SecurityContractValidationStatus status
    ) public virtual onlyOwner returns (bool);
    
    function addUserValidationStatus (
        address userAddr,
        UserValidationStatus status
    ) public virtual onlyOwner returns (bool);

    function getSecurityContractValidationStatus (address securityContractAddr)
        public virtual view returns (SecurityContractValidationStatus);

    function getUserValidationStatus (address userAddr) public virtual view returns (UserValidationStatus);
}