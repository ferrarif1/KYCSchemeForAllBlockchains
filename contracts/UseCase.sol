// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "KYCManager.sol";


contract ExampleContractUsingKYC{
    KYCManager kycManager;
    mapping(address=>bool)public whiteList;
    constructor(address kycManagerConract){
        kycManager = KYCManager(kycManagerConract);
    }

    function approve()public {
       
    }

    function revoke()public {

    }
    


}