
pragma solidity ^0.5.0;

import "../interfaces/uniswapv2/IUniswapV2Factory.sol";
import "../interfaces/balancer/IBalancerPool.sol";
import "../interfaces/balancer/IBalancerRegistry.sol";
import "../interfaces/balancer/BalancerLib.sol";
import "./UniversalERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";

contract IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}


contract DexExchangePlatform{
    
    using UniversalERC20 for IERC20;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using UniswapV2ExchangeLib for IUniswapV2Exchange;

    
    //WETH address, mainnet and ropsten testnet address are bellow.
    // IWETH constant internal weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IWETH constant internal weth = IWETH(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    // IWETH constant internal weth = IWETH(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    //uniswapv2 exchange address
    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    //balancer exchange address
    // IBRegistry constant internal balancerRegistry = IBRegistry(0xC5570FC7C828A8400605e9843106aBD675006093)
    
    //uniswapv2 swap strategy are bellow
    function _calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amounts
    ) external view returns(uint256 rets) {
        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 destTokenReal = destToken.isETH() ? weth : destToken;

        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, destTokenReal);

        if (exchange != IUniswapV2Exchange(0)) {
            uint256 fromTokenBalance = fromToken.universalBalanceOf(address(exchange));
            uint256 destTokenBalance = destToken.universalBalanceOf(address(exchange));
            rets = _calculateUniswapFormula(fromTokenBalance, destTokenBalance, amounts);
            return (rets);
        }
    }
    
    function _calculateUniswapFormula(uint256 fromBalance, uint256 toBalance, uint256 amount) internal pure returns(uint256) {
        if (amount == 0) {
            return 0;
        }
        return amount.mul(toBalance).mul(997).div(
            fromBalance.mul(1000).add(amount.mul(997))
        );
    }

    function _swapOnUniswapV2Internal(
        address fromToken,
        address destToken,
        uint256 amount
    ) public payable returns(uint256 returnAmount) {
        
        if (IERC20(fromToken).isETH()) {
            weth.deposit.value(amount)();
        } else {
            IERC20(fromToken).universalTransferFrom(msg.sender, address(this), amount);
        }
        
        if(IERC20(fromToken).isETH() && destToken==address(weth)){
            IERC20(destToken).safeTransfer(msg.sender, amount);
            IERC20(fromToken).universalTransfer(msg.sender, IERC20(fromToken).universalBalanceOf(address(this)));
            return amount;
        }
        
        IERC20 fromTokenReal = IERC20(fromToken).isETH() ? weth : IERC20(fromToken);
        IERC20 toTokenReal = IERC20(destToken).isETH() ? weth : IERC20(destToken);
        
        uint256 remainingAmount = fromTokenReal.universalBalanceOf(address(this));
     
        require(remainingAmount == amount, "!Invalid Transfer");
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, toTokenReal);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(fromTokenReal, toTokenReal, amount);
        if (needSync) {
            // exchange.sync();
        }
        else if (needSkim) {
            // exchange.skim(0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint256(address(fromToken)) < uint256(address(destToken))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }
        
        if (IERC20(destToken).isETH()) {
            uint wethOut = weth.balanceOf(address(this));
            // weth.withdraw(wethOut);
            msg.sender.transfer(wethOut);
        } else {
            IERC20(destToken).safeTransfer(msg.sender, IERC20(destToken).universalBalanceOf(address(this)));
        }
        
        IERC20(fromToken).universalTransfer(msg.sender, IERC20(fromToken).universalBalanceOf(address(this)));
    }
    
    //Balancer swap strategy are bellow
    // function getReturns(
    //     IBalancerPool pool,
    //     IERC20 fromToken,
    //     IERC20 destToken,
    //     uint256 amounts
    // )
    //     internal
    //     view
    //     returns(uint256 rets)
    // {
    //     uint256 swapFee = pool.getSwapFee();
    //     uint256 fromBalance = pool.getBalance(fromToken);
    //     uint256 destBalance = pool.getBalance(destToken);
    //     uint256 fromWeight = pool.getDenormalizedWeight(fromToken);
    //     uint256 destWeight = pool.getDenormalizedWeight(destToken);
    //     rets = BalancerLib.calcOutGivenIn(
    //         fromBalance,
    //         fromWeight,
    //         destBalance,
    //         destWeight,
    //         amounts,
    //         swapFee
    //     );
    // }
    
    // function _calculateBalancer(
    //     IERC20 fromToken,
    //     IERC20 destToken,
    //     uint256 amount,
    //     uint256 poolIndex
    // ) external view returns(uint256 rets) {
    //     address[] memory pools = balancerRegistry.getBestPoolsWithLimit(
    //         address(fromToken.isETH() ? weth : fromToken),
    //         address(destToken.isETH() ? weth : destToken),
    //         32
    //     );
    //     if (poolIndex >= pools.length) {
    //         return 0;
    //     }
    //     IBalancerPool bpool = IBalancerPool(0x81C2Ad88dCa489c080dDCd558AAE9De6E9477FfB);
    //     rets = getReturns(
    //         // IBalancerPool(pools[poolIndex]),
    //         bpool,
    //         fromToken.isETH() ? weth : fromToken,
    //         destToken.isETH() ? weth : destToken,
    //         amount
    //     );
    // }
    
    // function _swapOnBalancerX(
    //     IERC20 fromToken,
    //     IERC20 destToken,
    //     uint256 amount,
    //     uint256 poolIndex
    // ) public payable {
    //     address[] memory pools = balancerRegistry.getBestPoolsWithLimit(
    //         address(fromToken.isETH() ? weth : fromToken),
    //         address(destToken.isETH() ? weth : destToken),
    //         poolIndex + 1
    //     );

    //     if (fromToken.isETH()) {
    //         weth.deposit.value(amount)();
    //     }

    //     (fromToken.isETH() ? weth : fromToken).universalApprove(pools[poolIndex], amount);
    //     IBalancerPool(pools[0]).swapExactAmountIn(
    //         fromToken.isETH() ? weth : fromToken,
    //         amount,
    //         destToken.isETH() ? weth : destToken,
    //         0,
    //         uint256(-1)
    //     );

    //     if (destToken.isETH()) {
    //         weth.withdraw(weth.balanceOf(address(this)));
    //     }
    // }

    // function _swapOnBalancer1(
    //     IERC20 fromToken,
    //     IERC20 destToken,
    //     uint256 amount,
    //     uint256 flags
    // ) internal {
    //     _swapOnBalancerX(fromToken, destToken, amount, 0);
    // }

    // function _swapOnBalancer2(
    //     IERC20 fromToken,
    //     IERC20 destToken,
    //     uint256 amount
    // ) internal {
    //     _swapOnBalancerX(fromToken, destToken, amount, 1);
    // }

    // function _swapOnBalancer3(
    //     IERC20 fromToken,
    //     IERC20 destToken,
    //     uint256 amount
    // ) internal {
    //     _swapOnBalancerX(fromToken, destToken, amount, 2);
    // }
    
    // //Aave swap
    // function _aaveSwap(
    //     IERC20 fromToken,
    //     IERC20 destToken,
    //     uint256 amount
    // ) private {
    //     if (fromToken == destToken) {
    //         return;
    //     }
    //     IERC20 underlying = aaveRegistry.tokenByAToken(IAaveToken(address(fromToken)));
    //     if (underlying != IERC20(0)) {
    //         IAaveToken(address(fromToken)).redeem(amount);
    //         return _aaveSwap(
    //             underlying,
    //             destToken,
    //             amount,
    //             distribution,
    //             flags
    //         );
    //     }

    //     underlying = aaveRegistry.tokenByAToken(IAaveToken(address(destToken)));
    //     if (underlying != IERC20(0)) {

    //         uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

    //         underlying.universalApprove(aave.core(), underlyingAmount);
    //         aave.deposit.value(underlying.isETH() ? underlyingAmount : 0)(
    //             underlying.isETH() ? ETH_ADDRESS : underlying,
    //             underlyingAmount,
    //             1101
    //         );
    //     }
    // }
    
}


