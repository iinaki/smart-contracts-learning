// get funds from users
// withdraw funds
// set a minimum funndimg value in USD

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 5e18; //1 decimal
    address[] public funders;
    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;
    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    } 

    // allow users to send $
    // hvae a minimum $ to send
    // 1. Como mandamos ETH a este contract?
    function fund() public payable {
        require(msg.value.getConversionRate() >= MINIMUM_USD, "didnt send enough ETH"); //1e18 = 1ETH 
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value; //lo q habian fundeado + lo nuevo    
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < funders.length; i++){
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        //payable(msg.sender).transfer(address(this).balance);
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess,"send failed");

        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "call failed");
    }

    modifier onlyOwner(){
        // require(msg.sender == i_owner, NotOwner());
        if(msg.sender == i_owner){
            revert NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }
    fallback() external payable {
        fund();
    }
}