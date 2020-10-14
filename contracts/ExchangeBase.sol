
pragma solidity ^0.5.0;

import "../interfaces/uniswapv2/IUniswapV2Factory.sol";
import "../interfaces/balancer/IBalancerPool.sol";
import "../interfaces/balancer/IBalancerRegistry.sol";
import "./UniversalERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";

contract IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}


contract ExchangeBase{
    
    using UniversalERC20 for IERC20;
    using SafeMath for uint256;
    using UniversalERC20 for IWETH;
    
    //WETH address
    IWETH constant internal weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    //uniswapv2 exchange address
    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    //balancer exchange address
    IBalancerRegistry constant internal balancerRegistry = IBalancerRegistry(0x65e67cbc342712DF67494ACEfc06fe951EE93982);
    
    
    
    // function _getMulitExpectedReturn(
    //     IERC20[] memory fromToken,
    //     IERC20[] memory destToken,
    //     uint256[] memory amounts,
    //     uint256 /*flags*/
    // ) public view virtual returns(uint256[] memory rets);

    // function _muiltSwap(
    //     IERC20[] memory fromToken,
    //     IERC20[] memory destToken,
    //     uint256[] memory amounts,
    //     uint256 /*flags*/
    // ) public payable virtual returns(uint256[] memory rets);

    function parsingTokenList(
        IERC20[] memory fromToken,
        IERC20[] memory destToken
    ) internal pure returns (IERC20[][] memory pair, bool reverse)
    {
        reverse = false;
        if(fromToken.length > 1 && destToken.length==1)
        {
            // uint256 len = fromToken.length;
            // IERC20[][] memory pair = new IERC20[][](len);
            for(uint i = 0; i < fromToken.length; i++){
                pair[i] = new IERC20[](2);
                pair[i][0] = fromToken[i];
                pair[i][1] = destToken[0];
            }
            return (pair, reverse);
        }
        else if(fromToken.length==1 && destToken.length>1)
        {
            // uint256 len = fromToken.length;
            // IERC20[][] memory pair = new IERC20[][](len);
            for(uint i = 0; i < destToken.length; i++){
                pair[i] = new IERC20[](2);
                pair[i][0] = fromToken[i];
                pair[i][1] = destToken[0];
            }
            reverse = true;
            return (pair, reverse);
        }
        else if(fromToken.length == 1 && destToken.length==1)
        {
            // IERC20[][] memory pair = new IERC20[][](1);
            pair[0] = new IERC20[](2);
            pair[0][0] = fromToken[0];
            pair[0][1] = destToken[0];
            return (pair, reverse);
        }
    }
}


