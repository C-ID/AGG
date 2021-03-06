pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/Math.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";
import "../../contracts/UniversalERC20.sol";


interface IUniswapV2Exchange {
    function getReserves() external view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
}

interface IUniswapV2Router {
    // function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts) external;
    // function getAmountsIn(uint amountOut, address[] memory path) public view returns (uint[] memory amounts) external;
    function swapExactTokensForTokens(
                                      uint amountIn,
                                      uint amountOutMin,
                                      address[] calldata path,
                                      address to,
                                      uint deadline
                                    ) external returns (uint[] memory amounts);
}

library UniswapV2ExchangeLib {
    using Math for uint256;
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    function getReturn(
        IUniswapV2Exchange exchange,
        IERC20 fromToken,
        IERC20 destToken,
        uint amountIn
    ) internal view returns (uint256 result, bool needSync, bool needSkim) {
        uint256 reserveIn = fromToken.universalBalanceOf(address(exchange));
        uint256 reserveOut = destToken.universalBalanceOf(address(exchange));
        (uint112 reserve0, uint112 reserve1,) = exchange.getReserves();
        if (fromToken > destToken) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        needSync = (reserveIn < reserve0 || reserveOut < reserve1);
        needSkim = !needSync && (reserveIn > reserve0 || reserveOut > reserve1);

        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(Math.min(reserveOut, reserve1));
        uint256 denominator = Math.min(reserveIn, reserve0).mul(1000).add(amountInWithFee);
        result = (denominator == 0) ? 0 : numerator.div(denominator);
    }
}
