// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts@1.0.0/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    
    function getPrice(AggregatorV3Interface s_priceFeed) internal view returns (uint256){
        (,int256 price,,,) = s_priceFeed.latestRoundData();

        return uint256(price) * 1e10;
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface s_priceFeed) internal view returns (uint256){
        return (getPrice(s_priceFeed) * ethAmount) / 1e18;
    }
}