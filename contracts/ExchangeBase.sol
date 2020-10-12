
pragma solidity ^0.5.0;
import "./interface/IUniswapV2Factory.sol";

contract ExchangeBase is IERC20 {

    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); 
    mapping (string => address) exchangeList;

    constructor(exchangeList _exchangelist) public {
        _exchangelist["uniswapv2"] = uniswapV2
    }
    
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


