// get funds from users
// withdraw funds
// set a minimum funndimg value in USD

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts@1.0.0/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18; //1 decimal
    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    // address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    } 

    // allow users to send $
    // hvae a minimum $ to send
    // 1. Como mandamos ETH a este contract?
    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "didnt send enough ETH"); //1e18 = 1ETH 
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value; //lo q habian fundeado + lo nuevo    
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLenght = s_funders.length;
        for (uint256 i = 0; i < fundersLenght; i++){
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "call failed");
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++){
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

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

    // View  / Pure Functions (Getters)

    function getVersion() public view returns (uint256){
        return s_priceFeed.version();
    }

    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256){
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address){
        return s_funders[index];
    }

    function getOwner() external view returns (address){
        return i_owner;
    }
}