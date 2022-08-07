// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./BoolWallet.sol";

contract MoNWallet is BoolWallet {
    uint required;
    constructor(uint requiredSigs, address[] memory pubKeys) BoolWallet(pubKeys) {
        required = requiredSigs;
    }

    // function isAuthorized(bytes32 msgHash, bytes[] calldata signatures) internal view override returns (bool) {
    //     uint count = 0;
    //     for(uint i = 0; i < signatures.length; i++) {
    //         if (keys[recoverSig(signatures[i], msgHash)] > 0) {
    //             count++;
    //         }
    //     }
    //     return count >= required;
    // }

    function boolAuthorized(bool[] memory hasSig) internal view override returns (bool){
        uint count = 0;
        for(uint i = 0; i < hasSig.length; i++) {
            if (hasSig[i]) {
                count++;
            }
        }
        return count >= required;
    }
}