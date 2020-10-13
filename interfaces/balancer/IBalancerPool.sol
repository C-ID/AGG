pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IBalancerPool {
    function getSwapFee()
        external view returns (uint256 balance);

    function getDenormalizedWeight(IERC20 token)
        external view returns (uint256 balance);

    function getBalance(IERC20 token)
        external view returns (uint256 balance);

    function swapExactAmountIn(
        IERC20 tokenIn,
        uint256 tokenAmountIn,
        IERC20 tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    )
        external
        returns (uint256 tokenAmountOut, uint256 spotPriceAfter);
}