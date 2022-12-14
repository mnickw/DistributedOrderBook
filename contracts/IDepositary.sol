// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

enum SecurityContractValidationStatus { Invalid, Valid }
enum UserValidationStatus { Invalid, Valid }

interface IDepositary {

    function setSecurityContractValidationStatus (
        address securityContractAddr,
        SecurityContractValidationStatus status
    ) external;
    
    function setUserValidationStatus (
        address userAddr,
        UserValidationStatus status
    ) external;

    function getSecurityContractValidationStatus (address securityContractAddr)
        external view returns (SecurityContractValidationStatus);

    function getUserValidationStatus (address userAddr) external view returns (UserValidationStatus);
}