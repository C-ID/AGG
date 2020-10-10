
pragma solidity ^0.5.0;
import "./interface/IUniswapV2Factory.sol"

contract Exchange is IERC20 {

    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); 
    string exchangeName;
    
    function _getMulitExpectedReturn(
        IERC20[] fromToken,
        IERC20[] destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets);

    function _muiltSwap(
        IERC20[] fromToken,
        IERC20[] destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets);

    function setExchange(string _exchange)
    {
        exchangeName = _exchange;
    }
     
    function switchTo() {
        // switch 
    }
}

