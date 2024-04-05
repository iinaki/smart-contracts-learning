// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract SimpleStorage{
    uint256 myFavNumb;

    struct Person{
        uint256 favNumb;
        string name;
    }

    Person[] public listOfPeople;

    mapping(string => uint256) public nameToNumb;

    function store(uint256 _favNumb) public virtual{
        myFavNumb = _favNumb;
    }

    function retrieve() public view returns (uint256){
        return myFavNumb;
    }

    function addPerson(string memory name, uint256 number) public{
        nameToNumb[name] = number;
    }
}