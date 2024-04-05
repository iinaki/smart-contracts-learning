// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {SimpleStorage} from "./SimpleStorage.sol";

contract StorageFactory{
    SimpleStorage[] public simpleStorages;

    function createSimpleStorageContract() public {
        SimpleStorage simpleStorage = new SimpleStorage();

        simpleStorages.push(simpleStorage);
    }

    function sfsStore(uint256 _simpleStorageIndex, uint256 _newSimpleStorageNumber) public {
        simpleStorages[_simpleStorageIndex].store(_newSimpleStorageNumber);
    }

    function sfGet(uint256 i) public view returns (uint256){
        return simpleStorages[i].retrieve();
    }
}