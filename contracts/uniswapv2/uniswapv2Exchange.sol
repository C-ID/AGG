

pragma solidity ^0.5.0;

import "../../interfaces/uniswapv2/IUniswapV2Factory.sol";
import "../../interfaces/uniswapv2/IUniswapV2Exchange.sol";
import "../ExchangeBase.sol";
import "../UniversalERC20.sol";

contract Uniswapv2Exchange is ExchangeBase{
    
    using UniswapV2ExchangeLib for IUniswapV2Exchange;
    using UniversalERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath for uint;
    
    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router constant internal uniswapV2router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // function create(
    //     IERC20 fromToken,
    //     IERC20 destToken,){
    //     uniswapV2.getPair(fromToken, destToken);
    // }
    function _calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amounts
    ) internal view returns(uint256 rets) {
        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 destTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, destTokenReal);
        // emit log(exchange);
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
    
    function _getExpectedReturn(
        IERC20  fromToken,
        IERC20  destToken,
        uint256 amounts
    ) public view returns(uint256 rets){
        rets =  _calculateUniswapV2(fromToken,destToken,amounts);
    }

    
    function _getMulitExpectedReturn(
        IERC20[] memory fromToken,
        IERC20[] memory destToken,
        uint256[] memory amounts
    ) public view returns(uint256[] memory rets){
        require(fromToken.length <=3 || destToken.length <=3 || amounts.length <= 3, "!Invalid Parameter");
     
        // (IERC20[][] memory _pair, bool reserve) = parsingTokenList(fromToken, destToken);
        // rets = new uint256[](_pair.length);
        // if(reserve)
        // {
            
        //     for(uint i=0; i<_pair.length; i++)
        //     {
        //       rets[i] = _calculateUniswapV2(_pair[i][1], _pair[i][0], amounts[i]);
        //     }
        //   return rets;
        // }
        // else
        // {
        //     for(uint i=0; i<_pair.length; i++)
        //     {
        //         rets[i] = _calculateUniswapV2(_pair[i][0], _pair[i][1], amounts[i]);
        //     }
        //     return rets;
        // }
        
        // ["0xc778417E063141139Fce010982780140Aa0cD5Ab","0xaD6D458402F60fD3Bd25163575031ACDce07538D"]
        // ["0x20fE562d797A42Dcb3399062AE9546cd06f63280"]
        // [1,2]
        
        if(fromToken.length > 1 && destToken.length==1)
        {
            rets = new uint256[](fromToken.length);
            for(uint i=0; i<fromToken.length; i++){
                rets[i] =_calculateUniswapV2(fromToken[i], destToken[0], amounts[i]);
            }
            return rets;
        }
        else if(fromToken.length==1 && destToken.length>1)
        {
            rets = new uint256[](destToken.length);
            for(uint i=0; i<destToken.length; i++){
                rets[i] =_calculateUniswapV2(fromToken[0], destToken[i], amounts[i]);
            }
            return rets;
        }
        else if(fromToken.length == 1 && destToken.length==1)
        {
            rets = new uint256[](1);
            rets[0] =_calculateUniswapV2(fromToken[0], destToken[0], amounts[0]);
            return rets;
        }
    }

    function _muiltSwap(
        IERC20[] memory fromToken,
        IERC20[] memory destToken,
        uint256[] memory amounts
    ) public payable returns(uint256[] memory rets){

        // (IERC20[][] memory _pair, bool reserve) = parsingTokenList(fromToken, destToken);
        // rets = new uint256[](_pair.length);
        
        // if(reserve)
        // {
        //     for(uint i=0; i<_pair.length; i++)
        //     {
        //         rets[i] = _swapOnUniswapV2Internal(_pair[i][1], _pair[i][0], amounts[i]);
        //     }
        // }
        // else
        // {
        //     for(uint i=0; i<_pair.length; i++)
        //     {
        //         rets[i] = _swapOnUniswapV2Internal(_pair[i][0], _pair[i][1], amounts[i]);
        //     }
        // }
        if(fromToken.length > 1 && destToken.length==1)
        {
            for(uint i=0; i<fromToken.length; i++){
                rets[i] =_swapOnUniswapV2Internal(fromToken[i], destToken[0], amounts[i]);
            }
            return rets;
        }
        else if(fromToken.length==1 && destToken.length>1)
        {
            for(uint i=0; i<destToken.length; i++){
                rets[i] =_swapOnUniswapV2Internal(fromToken[0], destToken[i], amounts[i]);
            }
            return rets;
        }
        else if(fromToken.length == 1 && destToken.length==1)
        {
            rets[0] =_swapOnUniswapV2Internal(fromToken[0], destToken[0], amounts[0]);
            return rets;
        }
    }
    
    // function _swapOnUniswapV2Internal(
    //     address fromToken,
    //     address destToken,
    //     uint amount
    // ) internal returns(uint[] memory returnAmount){
    //     address[] memory path = new address[](2);
    //     uint min = 0;
    //     path[0] = fromToken;
    //     path[1] = destToken;
    //     returnAmount = uniswapV2router.swapExactTokensForTokens(amount, min, path, msg.sender, min);
    // }
    
    

    function _swapOnUniswapV2Internal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) public payable returns(uint256 returnAmount) {
        // if (fromToken.isETH()) {
        //     weth.deposit.value(amount)();
        // }
  
        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromToken, destToken);
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

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

}
