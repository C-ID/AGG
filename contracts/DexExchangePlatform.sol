
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


contract DexExchangePlatform{
    
    using UniversalERC20 for IERC20;
    using SafeMath for uint256;
    using UniswapV2ExchangeLib for IUniswapV2Exchange;
    // using UniversalERC20 for IWETH;
    
    //WETH address, mainnet and ropsten testnet address are bellow.
    // IWETH constant internal weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IWETH constant internal weth = IWETH(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    //uniswapv2 exchange address
    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    //balancer exchange address
    // IBalancerRegistry constant internal balancerRegistry = IBalancerRegistry(0x65e67cbc342712DF67494ACEfc06fe951EE93982);
    
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
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) public returns(uint256 returnAmount) {
        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, toTokenReal);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(fromToken, destToken, amount);
        if (needSync) {
            exchange.sync();
        }
        else if (needSkim) {
            exchange.skim(0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5);
        }

        fromToken.universalTransfer(address(exchange), amount);
        if (uint256(address(fromToken)) < uint256(address(destToken))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }
    }
}


