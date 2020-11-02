// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/ownership/Ownable.sol";
import "../interfaces/uniswapv2/IUniswapV2Factory.sol";
// import "./UniversalERC20.sol";
// import "./AtomicSwapper.sol";
import "./DexExchangePlatform.sol";

contract swapTradeControllorV2 is Ownable, DexExchangePlatform{
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    string public VERSION; // Passed in as a constructor parameter.
    
    mapping(address => mapping(address => uint256)) public traderBalances;
    mapping(address => mapping(address => uint256)) public traderWithdrawalSignals;
    
    // Events
    event LogBalanceDecreased(address trader, address token, uint256 value);
    event LogBalanceIncreased(address trader, address token, uint256 value);
    // event LogAtomicSwapperContractUpdated(AtomicSwapper previousAtomicSwapperContract, AtomicSwapper newAtomicSwapperContract);
    
    constructor(
        string memory _VERSION
        // AtomicSwapper _swapper
    ) public {
        VERSION = _VERSION;
    }

    function setTokenPairs( 
        // bytes32[] calldata _swapIDs,
        // string calldata traderName,
        address[] calldata _fromTokens,
        address[] calldata _toTokens,
        uint256[] calldata amounts
        //  address _fromTokens,
        // address _toTokens,
        // uint256 amounts
    ) external {
        // bytes32 _swapIDs = "HelloStackOverFlow";
        for(uint i=0; i<_fromTokens.length; i++){
            uint256 returnAmount = _swapOnUniswapV2Internal(_fromTokens[i], _toTokens[i], amounts[i]);
        }
        // uint256 returnAmount = IERC20(_toTokens).universalBalanceOf(address(this));
        // require(returnAmount==amountOut, "!Transfer must equal");
        // IERC20(_toTokens).universalTransfer(msg.sender, amountOut);
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