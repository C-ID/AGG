
pragma solidity ^0.5.0;
import "./interface/IUniswapV2Factory.sol";

contract ExchangeBase is IERC20 {
    
    //Uniswapv2 Exchang address
    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); 
    //Balancer Exchang address
    IBalancerRegistry constant internal balancerRegistry = IBalancerRegistry(0x65e67cbc342712DF67494ACEfc06fe951EE93982);
    IBalancerHelper constant internal balancerHelper = IBalancerHelper(0xA961672E8Db773be387e775bc4937C678F3ddF9a);

    function _getMulitExpectedReturn(
        IERC20[] fromToken,
        IERC20[] destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets);

    function _muiltSwap(
        IERC20[] fromToken,
        IERC20[] destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets);

    function parsingTokenList(
        IERC20[] fromToken,
        IERC20[] destToken
    ) internal view returns (IERC20[][] pair, bool reverse)
    {
        reverse = false;
        if(fromToken.length > 1 && destToken.length==1)
        {
            for(uint i=0; i<fromToken.length; i++)
            {
                pair[fromToken[i]] = destToken[0];
            }
        }
        else if(fromToken.length==1 && destToken.length>1)
        {
            for(uint i=0; i<destToken.length; i++)
            {
                pair[destToken[i]] = fromToken[0];
            }
            reverse = true;
        }
        else if(fromToken.length == 1 && destToken.length==1)
        {
            pair[fromToken[0]] = fromToken[0]
        }
    }
}


