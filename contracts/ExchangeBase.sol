
pragma solidity ^0.5.0;

import "../interfaces/uniswapv2/IUniswapV2Factory.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";

contract ExchangeBase is IERC20 {

    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); 
    mapping (uint => address) tokenlist;
    
    function _getMulitExpectedReturn(
        IERC20[] memory fromToken,
        IERC20[] memory destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets);

    function _muiltSwap(
        IERC20[] memory fromToken,
        IERC20[] memory destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets);

    function parsingTokenList(
        IERC20[] memory fromToken,
        IERC20[] memory destToken
    ) internal pure returns (IERC20[][] memory pair)
    {
        if(fromToken.length > 1 && destToken.length==1)
        {
            // uint256 len = fromToken.length;
            // IERC20[][] memory pair = new IERC20[][](len);
            for(uint i = 0; i < fromToken.length; i++){
                pair[i] = new IERC20[](2);
                pair[i][0] = fromToken[i];
                pair[i][1] = destToken[0];
            }
            
        }
        else if(fromToken.length==1 && destToken.length>1)
        {
            // uint256 len = fromToken.length;
            // IERC20[][] memory pair = new IERC20[][](len);
            for(uint i = 0; i < destToken.length; i++){
                pair[i] = new IERC20[](2);
                pair[i][0] = fromToken[i];
                pair[i][1] = destToken[0];
            }
        }
        else if(fromToken.length == 1 && destToken.length==1)
        {
            // IERC20[][] memory pair = new IERC20[][](1);
            pair[0] = new IERC20[](2);
            pair[0][0] = fromToken[0];
            pair[0][1] = destToken[0];
        }
    }
}


