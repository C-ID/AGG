pragma solidity ^0.5.0;

import "./IUniswapV2Exchange.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";


interface IUniswapV2Factory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapV2Exchange pair);
    function createPair(IERC20 tokenA, IERC20 tokenB) external returns (IUniswapV2Exchange pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}
