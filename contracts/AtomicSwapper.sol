// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";
import "./DexExchangePlatform.sol";
import "../interfaces/uniswapv2/IUniswapV2Factory.sol";
import "./UniversalERC20.sol";

/// @notice AtomicSwapper implements the atomic swapping interface
/// for token Swap in Dex Exchange platform...
contract AtomicSwapper {
    
    string public VERSION; // Passed in as a constructor parameter.
    DexExchangePlatform public factory;
    
    using UniversalERC20 for IERC20;
    
    struct Swap{
        uint256 value;
        uint256 AmountIn;
        address payable openTrader;
        string exchangeName;
        IERC20 fromToken;
        IERC20 toToken;
        function(IERC20, IERC20, uint256) external view returns(uint256) viewTrader;
        function(IERC20, IERC20, uint256) external returns(uint256) swapTrader;
    }
    
    enum Exchanges{
        uniswapv2,
        balancer
    }

    enum States {
        INVALID,
        OPEN,
        CLOSED,
        EXPIRED
    }

    // Storage 
    mapping (bytes32 => Swap) private swaps;
    mapping (bytes32 => States) private swapStates;
    mapping (string => Exchanges) private swapExchange;
    mapping (bytes32 => uint256) public redeemedTime;
    mapping (string => function()) private traderFactory;
    mapping (string => function()) private traderVisFactory;

    //Events
    event LogOpen(bytes32 _swapID, string exchangeName);
    event LogExpire(bytes32 _swapID);



    /// @notice Throws if the swap is not invalid (i.e. has already been opened)
    modifier onlyInvalidSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.INVALID, "swap opened previously");
        _;
    }

    /// @notice Throws if the swap is not open.
    modifier onlyOpenSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.OPEN, "swap not open");
        _;
    }
    
    /// @notice Throws if the swap is not closed.
    modifier onlyClosedSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.CLOSED, "swap not redeemed");
        _;
        delete swapStates[_swapID];
        delete swaps[_swapID];
    }

    constructor(
        string memory _VERSION,
        DexExchangePlatform _factory
    ) public {
        VERSION = _VERSION;
        factory = _factory;
    }
    
    function registViewExchange(string memory ex) internal view returns (function(IERC20, IERC20, uint256) external view returns(uint256)){
        if (keccak256(abi.encodePacked(ex)) == keccak256(abi.encodePacked("uniswapv2")))
        {
            return factory._calculateUniswapV2;
        }
    }
    
    function registSwapExchange(string memory ex) internal view returns (function(IERC20, IERC20, uint256) external returns(uint256)){
        if (keccak256(abi.encodePacked(ex)) == keccak256(abi.encodePacked("uniswapv2"))){
            return factory._swapOnUniswapV2Internal;
        }
    }

    /// @notice Initiates the atomic swap.
    ///
    /// @param _swapID The unique atomic swap id.
    function initiate(
        bytes32 _swapID,
        string memory traderName,
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 amount
    ) internal onlyInvalidSwaps(_swapID) {
        // Store the details of the swap.
        Swap memory swap = Swap({
            value: amount,
            openTrader: msg.sender,
            AmountIn: amount,
            exchangeName: traderName,
            fromToken: _fromToken,
            toToken: _toToken,
            viewTrader: registViewExchange(traderName),
            swapTrader: registSwapExchange(traderName)
        });
        swaps[_swapID] = swap;
        swapStates[_swapID] = States.OPEN;
        
        // Logs open event
        emit LogOpen(_swapID, traderName);
    }

    /// @notice Redeems an atomic swap.
    /// @param swapID The unique atomic swap id.
    function redeem(
        bytes32 swapID,
        string calldata traderName,
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 amount
        ) external payable returns(uint256 amountOut) {
        
        /* solium-disable-next-line security/no-block-members */
        redeemedTime[swapID] = now;
        // _fromToken.universalApprove(address(this), amount);
        _fromToken.universalTransferFromSenderToThis(amount);
        uint256 remainingAmount = _fromToken.universalBalanceOf(address(this));
        require(remainingAmount == amount, "!Invalid Transfer");
        
        initiate(swapID, traderName, _fromToken, _toToken, amount);
        
        // Transfer the IERC20 Token from this contract to the swap trader.
        amountOut = audit(swapID);
        
        // Close the swap.
        swapStates[swapID] = States.CLOSED;
        
    }
    
    /// @notice Audits an atomic swap.
    /// @param _swapID The unique atomic swap id.
    function audit(bytes32 _swapID) internal returns(uint256 amountOut) {
        Swap memory swap = swaps[_swapID];
        function(IERC20, IERC20, uint256) external returns(uint256) swap_ = swap.swapTrader;
        swap.fromToken.universalApprove(address(this), swap.AmountIn);
        amountOut = swap_(swap.fromToken, swap.toToken, swap.AmountIn);
        swap.toToken.universalTransfer(msg.sender, amountOut);
        // closeSwap(_swapID);
    }


    /// @notice Checks whether a swap is initiatable or not.
    ///
    /// @param _swapID The unique atomic swap id.
    function initiatable(bytes32 _swapID) external view returns (bool) {
        return (swapStates[_swapID] == States.INVALID);
    }

    /// @notice Checks whether a swap is redeemable or not.
    /// @param _swapID The unique atomic swap id.
    function closeSwap(bytes32 _swapID) internal onlyClosedSwaps(_swapID) returns (bool) {
        return true;
    }
}