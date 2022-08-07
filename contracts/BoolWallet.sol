// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AbstractWallet.sol";

abstract contract BoolWallet is AbstractWallet {
    uint total;
    constructor(address[] memory pubKeys) AbstractWallet(pubKeys) {
        total = pubKeys.length;
    }

    function isAuthorized(bytes32 msgHash, bytes[] calldata signatures) internal view override returns (bool) {
        bool[] memory hasSig = new bool[](total);
        for(uint i = 0; i < signatures.length; i++) {
            uint pos = keys[recoverSig(signatures[i], msgHash)];
            if (pos > 0) {
                hasSig[pos - 1] = true;
            }
        }
        return boolAuthorized(hasSig);
    }

    function boolAuthorized(bool[] memory hasSig) internal view virtual returns (bool);
}