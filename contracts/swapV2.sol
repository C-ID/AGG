// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/ownership/Ownable.sol";
import "../interfaces/uniswapv2/IUniswapV2Factory.sol";
import "./DexExchangePlatform.sol";

library DisableFlags {
    function check(uint256 flags, uint256 flag) internal pure returns(bool) {
        return (flags & flag) != 0;
    }
}

contract swapTradeControllorV2 is Ownable, DexExchangePlatform{
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    using DisableFlags for uint256;
    
    string public VERSION; // Passed in as a constructor parameter.
    
    mapping(address => mapping(address => uint256)) public traderBalances;
    
    // Events
    event LogBalanceDecreased(address trader, address token, uint256 value);
    event LogBalanceIncreased(address trader, address token, uint256 value);

    
    constructor(
        string memory _VERSION
    ) public {
        VERSION = _VERSION;
    }

    function setTokenPairs(
        address[] calldata TokenList,
        uint256[] calldata amounts,
        string calldata flags
    ) external payable{
        require(TokenList.length==amounts.length + 1, "!");
        if(keccak256(abi.encodePacked(flags)) == keccak256(abi.encodePacked("1vM"))){
            for(uint i=1; i<TokenList.length; i++){
                _swapOnUniswapV2Internal(TokenList[0], TokenList[i], amounts[i-1]);
            }
        }
        else if(keccak256(abi.encodePacked(flags)) == keccak256(abi.encodePacked("Mv1")))
        {
            for(uint i=0; i<TokenList.length-1; i++){
                _swapOnUniswapV2Internal(TokenList[i], TokenList[TokenList.length], amounts[i]);
            }
        }
    }
    
    function muiltSwap(
        address[] calldata fromTokenList,
        address[] calldata toTokenList,
        uint256[] calldata amounts
    ) external payable {
        require(fromTokenList.length == toTokenList.length, "!InValid Parameters");
        require(fromTokenList.length == amounts.length, "!InValid Parameters");
        for(uint i=0; i<fromTokenList.length; i++){
            _swapOnUniswapV2Internal(fromTokenList[i], toTokenList[i], amounts[i]);
        }
    }
    
    function privateIncrementBalance(address _trader, address _token, uint256 _value) private {
        traderBalances[_trader][_token] = traderBalances[_trader][_token].add(_value);

        emit LogBalanceIncreased(_trader, _token, _value);
    }

    function privateDecrementBalance(address _trader, address _token, uint256 _value) private {
        require(traderBalances[_trader][_token] >= _value, "insufficient funds");
        traderBalances[_trader][_token] = traderBalances[_trader][_token].sub(_value);

        emit LogBalanceDecreased(_trader, _token, _value);
    }
}