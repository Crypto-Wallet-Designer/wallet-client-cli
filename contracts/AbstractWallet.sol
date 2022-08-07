// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract AbstractWallet {
    uint nonce;
    mapping (address => uint) keys;

    constructor(address[] memory pubKeys) {
        for (uint i = 0; i < pubKeys.length; i++) {
            keys[pubKeys[i]] = i+1;
        }
    }
    
    receive() external payable { }

    function getNonce() public view returns (uint) {
        return nonce;
    }

    function isAuthorized(bytes32 msgHash, bytes[] calldata signatures) internal virtual returns (bool);

    function requireAuthorized(bytes32 msgHash, bytes[] calldata signatures) internal {
        require(isAuthorized(msgHash, signatures), "Not Authorized");
    }

    function transfer(address payable destination, uint amount, bytes[] calldata signatures) external {
        uint n  = nonce;
        bytes32 msgHash = hashTransfer(n, destination, amount);
        requireAuthorized(msgHash, signatures);
        nonce = n + 1;
        destination.transfer(amount);
    }

    function hashTransfer(uint n, address destination, uint amount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("transfer", n, destination, amount));
    }

    function call(address dest, bytes calldata cd, uint amount, bytes[] calldata signatures) external {
        uint n  = nonce;
        bytes32 msgHash = hashCall(n, dest, cd, amount);
        requireAuthorized(msgHash, signatures);
        nonce = n + 1;
        (bool success, bytes memory errMsg) = dest.call{value:amount}(cd);
        require(success, string(errMsg));
    }

    function hashCall(uint n, address destination, bytes calldata cd, uint amount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("call", n, destination, cd, amount));
    }

    function replace(address originalKey, address newKey, bytes[] calldata signatures) external {
        uint n  = nonce;
        bytes32 msgHash = hashReplace(n, originalKey, newKey);
        requireAuthorized(msgHash, signatures);
        nonce = n + 1;
        replaceOne(originalKey, newKey);
    }

    function replaceOne(address originalKey, address newKey) internal {
        uint originalPos = keys[originalKey];
        require(originalPos != 0, "Not an original key");
        require(keys[newKey] == 0, "Not an new key");
        keys[newKey] = originalPos;
        keys[originalKey] = 0;
    }

    function hashReplace(uint n, address a, address b) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("replace", n, a, b));
    }

    function rotate(address[] memory originalKeys, address[] memory newKeys, bytes[] calldata signatures) external {
        require(originalKeys.length == newKeys.length, "keys must have same length");
        uint n  = nonce;
        bytes32 msgHash = hashRotate(n, originalKeys, newKeys);
        requireAuthorized(msgHash, signatures);
        nonce = n + 1;
        for(uint i=0;i<originalKeys.length;i++) {
            replaceOne(originalKeys[i], newKeys[i]);
        }
    }

    function hashRotate(uint n, address[] memory a, address[] memory b) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("rotate", n, a, b));
    }

    function recoverSig(bytes calldata sig, bytes32 msgHash) internal pure returns (address) {
        uint8 v = uint8(sig[64]);
        uint src;
        assembly {
            src := sig.offset
        }
        bytes32 r;
        assembly {
            r := calldataload(src)
        }
        src += 0x20;
        bytes32 s;
        assembly {
            s:= calldataload(src)
        }
        return ecrecover(msgHash, v, r, s);
    }
}