

pragma solidity ^0.5.0;

import "./interface/IUniswapV2Factory.sol"


contract Uniswapv2Exchange is ExchangeBase{

    function _calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets) {
        rets = new uint256[](amounts.length);

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 destTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, destTokenReal);
        if (exchange != IUniswapV2Exchange(0)) {
            uint256 fromTokenBalance = fromTokenReal.universalBalanceOf(address(exchange));
            uint256 destTokenBalance = destTokenReal.universalBalanceOf(address(exchange));
            rets[i] = _calculateUniswapFormula(fromTokenBalance, destTokenBalance, amounts[i]);
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

    function calculateOneVsMuilt(

    )
    
    function _getMulitExpectedReturn(
        IERC20[] fromToken,
        IERC20[] destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets){
        require(fromToken.length <=3 || destToken.length <=3 || amount.length <= 3, "!Invalid Parameter")
        if (fromToken.length > 1 && destToken.length == 1) {
            
        }
    }

    function _muiltSwap(
        IERC20[] fromToken,
        IERC20[] destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets){


    }

}
