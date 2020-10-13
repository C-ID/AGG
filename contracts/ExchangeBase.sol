
pragma solidity ^0.5.0;
import "../interfaces/uniswapv2/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ExchangeBase is IERC20 {

    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); 
    mapping (uint => address) tokenlist;
    
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
    ) internal view returns (IERC20[][] pair)
    {
        if(from.length > 1 && destToken.length==1)
        {
            for(uint i = 0; i < from.length; i++){
                pair[from[i]] = destToken[0];
            }
            
        }
        else if(from.length==1 && destToken.length>1)
        {
            for(uint i = 0; i < destToken.length; i++){
                pair[from[0]] = destToken[0];
            }
        }
        else if(fromToken.length == 1 && destToken.length==1)
        {
            pair[fromToken[0]] = destToken[0];
        }
    }
}


