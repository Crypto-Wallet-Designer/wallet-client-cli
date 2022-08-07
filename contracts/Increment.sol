// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Increment {

    uint value;

    function getValue() public view returns (uint) {
        return value;
    }

    function inc() external {
        value = value + 1;
    }

    function incWith(uint v) external {
        value = value + v;
    }

    function incWithPay(uint v) external payable {
        value = value + v;
    }

    function exactPayToIncrement(uint v) external payable {
        require(msg.value == 1000000000, "not exact!");
        value = value + v;
    }

}