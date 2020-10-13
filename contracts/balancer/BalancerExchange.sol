

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

        ret = BalancerLib.calcOutGivenIn(
            fromBalance,
            fromWeight,
            destBalance,
            destWeight,
            amounts,
            swapFee
        );
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

    function _swapOnBalancerX(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/,
        uint256 poolIndex
    ) internal {
        address[] memory pools = balancerRegistry.getBestPoolsWithLimit(
            address(fromToken.isETH() ? weth : fromToken),
            address(destToken.isETH() ? weth : destToken),
            poolIndex + 1
        );

        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        (fromToken.isETH() ? weth : fromToken).universalApprove(pools[poolIndex], amount);
        IBalancerPool(pools[poolIndex]).swapExactAmountIn(
            fromToken.isETH() ? weth : fromToken,
            amount,
            destToken.isETH() ? weth : destToken,
            0,
            uint256(-1)
        );

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnBalancer1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnBalancerX(fromToken, destToken, amount, flags, 0);
    }

    function _swapOnBalancer2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnBalancerX(fromToken, destToken, amount, flags, 1);
    }

    function _swapOnBalancer3(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnBalancerX(fromToken, destToken, amount, flags, 2);
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
                _res += _calculateBalancer(_pair[i][1], _pair[i][0], amounts[i], 0);
            }
            rets.push(_res);
        }
        else
        {
            for(uint i=0; i<_pair.length; i++)
            {
                rets.push(_calculateBalancer(_pair[i][0], _pair[i][1], amounts[i], 0));
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
                _res += _swapOnBalancerX(_pair[i][1], _pair[i][0], amounts[i], 0);
            }
            rets.push(_res);
        }
        else
        {
            for(uint i=0; i<_pair.length; i++)
            {
                rets.push(_swapOnBalancerX(_pair[i][0], _pair[i][1], amounts[i], 0));
            }
        }
    }
}
