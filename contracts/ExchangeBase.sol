
pragma solidity ^0.5.0;
import "./interface/IUniswapV2Factory.sol"

contract ExchangeBase is IERC20 {

    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); 
    
    
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

    function parsingTokenList(
        IERC20[] fromToken,
        IERC20[] destToken
    ) internal view returns (IERC20[][] pair)
    {
        
    }
}


