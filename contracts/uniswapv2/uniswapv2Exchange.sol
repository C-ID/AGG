

pragma solidity ^0.5.0;

import "../../interfaces/uniswapv2/IUniswapV2Factory.sol";
import "../../interfaces/uniswapv2/IUniswapV2Exchange.sol";
import "../ExchangeBase.sol";

contract Uniswapv2Exchange is ExchangeBase{
    
    using UniswapV2ExchangeLib for IUniswapV2Exchange;

    function _calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amounts
    ) internal view returns(uint256 rets) {
        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 destTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, destTokenReal);
        if (exchange != IUniswapV2Exchange(0)) {
            uint256 fromTokenBalance = fromTokenReal.universalBalanceOf(address(exchange));
            uint256 destTokenBalance = destTokenReal.universalBalanceOf(address(exchange));
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

    
    function _getMulitExpectedReturn(
        IERC20[] memory fromToken,
        IERC20[] memory destToken,
        uint256[] memory amounts
    ) public view returns(uint256[] memory rets){
        require(fromToken.length <=3 || destToken.length <=3 || amounts.length <= 3, "!Invalid Parameter");
     
        (IERC20[][] memory _pair, bool reserve) = parsingTokenList(fromToken, destToken);
        rets = new uint256[](_pair.length);
        if(reserve)
        {
            
            for(uint i=0; i<_pair.length; i++)
            {
              rets[i] = _calculateUniswapV2(_pair[i][1], _pair[i][0], amounts[i]);
            }
           return rets;
        }
        else
        {
            for(uint i=0; i<_pair.length; i++)
            {
                rets[i] = _calculateUniswapV2(_pair[i][0], _pair[i][1], amounts[i]);
            }
            return rets;
        }
    }

    function _muiltSwap(
        IERC20[] memory fromToken,
        IERC20[] memory destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) public payable returns(uint256[] memory rets){

        (IERC20[][] memory _pair, bool reserve) = parsingTokenList(fromToken, destToken);
        rets = new uint256[](_pair.length);
        
        if(reserve)
        {
            for(uint i=0; i<_pair.length; i++)
            {
                rets[i] = _swapOnUniswapV2Internal(_pair[i][1], _pair[i][0], amounts[i]);
            }
        }
        else
        {
            for(uint i=0; i<_pair.length; i++)
            {
                rets[i] = _swapOnUniswapV2Internal(_pair[i][0], _pair[i][1], amounts[i]);
            }
        }
    }

    function _swapOnUniswapV2Internal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256 returnAmount) {
        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }
        // IUniswapV2Exchange exchange = IUniswapV2Exchange(0xa6f3ef841d371a82ca757FaD08efc0DeE2F1f5e2);
        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, toTokenReal);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(fromTokenReal, toTokenReal, amount);
        if (needSync) {
            exchange.sync();
        }
        else if (needSkim) {
            exchange.skim(0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint256(address(fromTokenReal)) < uint256(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

}
