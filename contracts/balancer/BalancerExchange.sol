

pragma solidity ^0.5.0;

import "./interface/Balancer/IBalancerPool.sol";
import "./interface/Balancer/IBalancerRegistry.sol";
import "./BalancerLib.sol"



contract BalancerExchange is ExchangeBase{
    
    function getReturns(
        IBalancerPool pool,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amounts
    )
        external
        view
        returns(uint256 rets)
    {
        uint256 swapFee = pool.getSwapFee();
        uint256 fromBalance = pool.getBalance(fromToken);
        uint256 destBalance = pool.getBalance(destToken);
        uint256 fromWeight = pool.getDenormalizedWeight(fromToken);
        uint256 destWeight = pool.getDenormalizedWeight(destToken);

        rets = new uint256[](amounts.length);
        for (uint i = 0; i < amounts.length && amounts[i].mul(2) <= fromBalance; i++) {
            rets[i] = BalancerLib.calcOutGivenIn(
                fromBalance,
                fromWeight,
                destBalance,
                destWeight,
                amounts[i],
                swapFee
            );
        }
    }

    function _calculateBalancer(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 poolIndex
    ) internal view returns(uint256 rets) {
        address[] memory pools = balancerRegistry.getBestPoolsWithLimit(
            address(fromToken.isETH() ? weth : fromToken),
            address(destToken.isETH() ? weth : destToken),
            poolIndex + 1
        );
        if (poolIndex >= pools.length) {
            return (0);
        }

        rets = getReturns(
            IBalancerPool(pools[poolIndex]),
            fromToken.isETH() ? weth : fromToken,
            destToken.isETH() ? weth : destToken,
        );
    }


    function _getMulitExpectedReturn(
        IERC20[] fromToken,
        IERC20[] destToken,
        uint256[] memory amounts
    ) internal view returns(uint256[] memory rets){
        require(fromToken.length <=3 || destToken.length <=3 || amount.length <= 3, "!Invalid Parameter");
        IERC20[][] _pair;
        bool reserve;
        uint256 _res = 0;
        _pair, reserve = parsingTokenList(fromToken, destToken);
        if(reserve)
        {
            for(uint i=0; i<_pair.length; i++)
            {
                _res += _calculateUniswapV2(_pair[i][1], _pair[i][0], amounts[i]);
            }
            rets.push(_res);
        }
        else
        {
            for(uint i=0; i<_pair.length; i++)
            {
                rets.push(_calculateUniswapV2(_pair[i][0], _pair[i][1], amounts[i]));
            }
        }
    }

    function _muiltSwap(
        IERC20[] fromToken,
        IERC20[] destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets){
        require(fromToken.length <=3 || destToken.length <=3 || amount.length <= 3, "!Invalid Parameter");
        IERC20[][] _pair;
        bool reserve;
        uint256 _res = 0;
        _pair, reserve = parsingTokenList(fromToken, destToken);
        
        if(reserve)
        {
            for(uint i=0; i<_pair.length; i++)
            {
                _res += _swapOnUniswapV2Internal(_pair[i][1], _pair[i][0], amounts[i]);
            }
            rets.push(_res);
        }
        else
        {
            for(uint i=0; i<_pair.length; i++)
            {
                rets.push(_swapOnUniswapV2Internal(_pair[i][0], _pair[i][1], amounts[i]));
            }
        }
    }
}
