// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/ownership/Ownable.sol";
import "../interfaces/uniswapv2/IUniswapV2Factory.sol";
import "./UniversalERC20.sol";
import "./AtomicSwapper.sol";

contract swapTradeControllor is Ownable{
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    string public VERSION; // Passed in as a constructor parameter.
    
    AtomicSwapper public swapper;
    IWETH constant internal weth = IWETH(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    
    mapping(address => mapping(address => uint256)) public traderBalances;
    mapping(address => mapping(address => uint256)) public traderWithdrawalSignals;
    
    // Events
    event LogBalanceDecreased(address trader, address token, uint256 value);
    event LogBalanceIncreased(address trader, address token, uint256 value);
    event LogAtomicSwapperContractUpdated(AtomicSwapper previousAtomicSwapperContract, AtomicSwapper newAtomicSwapperContract);
    
    constructor(
        string memory _VERSION,
        AtomicSwapper _swapper
    ) public {
        VERSION = _VERSION;
        swapper = _swapper;
    }

    /// @notice Allows the owner of the contract to update the address of the
    /// AtomicSwapper contract.
    ///
    /// @param _swapper the address of the new AtomicSwapper contract
    function updateAtomicSwapperContract(AtomicSwapper _swapper) external onlyOwner {
        // Basic validation knowing that RenExSettlement exposes VERSION
        require(bytes(_swapper.VERSION()).length > 0, "invalid settlement contract");

        emit LogAtomicSwapperContractUpdated(swapper, _swapper);
        swapper = _swapper;
    }

    /// @notice Restricts trader withdrawing to be called if a signature from a
    /// RenEx broker is provided, or if a certain amount of time has passed
    /// since a trader has called `signalBackupWithdraw`.
    /// @dev If the trader is withdrawing after calling `signalBackupWithdraw`,
    /// this will reset the time to zero, writing to storage.
    modifier withBrokerSignatureOrSignal(address _token, bytes memory _signature) {
        address trader = msg.sender;

        // If a signature has been provided, verify it - otherwise, verify that
        // the user has signalled the withdraw
        if (_signature.length > 0) {
            // require (brokerVerifierContract.verifyWithdrawSignature(trader, _token, _signature), "invalid signature");
        } else  {
            require(traderWithdrawalSignals[trader][_token] != 0, "not signalled");
            /* solium-disable-next-line security/no-block-members */
            // require((now - traderWithdrawalSignals[trader][_token]) > SIGNAL_DELAY, "signal time remaining");
            traderWithdrawalSignals[trader][_token] = 0;
        }
        _;
    }

    /// @notice Deposits ETH or an ERC20 token into the contract.
    ///
    /// @param _token The token's address (must be a registered token).
    /// @param _value The amount to deposit in the token's smallest unit.
    function deposit(address[] memory _token, uint256[] memory _value) internal {
        address trader = msg.sender;
        for(uint i=0; i<_token.length; i++){
            uint256 receivedValue  = _value[i];
            if (IERC20(_token[i]).isETH()) {
                require(msg.value >= _value[i], "!Invalid parameter");
            } else {
                require(msg.value == 0, "Unexpected ether transfer");
                IERC20(_token[i]).transferFrom(msg.sender, address(this), _value[i]);
            }
            privateIncrementBalance(trader, _token[i], receivedValue);
        }
    }

    /// @notice swap trade confirm action. with no parameters owing to initiate func.
    function swapConfirmation(
        bytes32 _swapIDs,
        // string memory traderName,
        address _fromToken,
        address _toToken,
        uint256 amount
        ) private returns(uint256 amountOut){
        // deposit(_fromToken, amount);
        // uint256 confirmed = traderBalances[msg.sender][_fromToken];
        // uint256 confirmed = IERC20(_fromToken).universalBalanceOf(address(this));
        string memory traderName = "uniswapv2";
        uint256 confirmed = address(this).balance;
        IERC20(_fromToken).universalApprove(address(swapper), amount);
        amountOut = swapper.redeem.value(IERC20(_fromToken).isETH() ? amount : 0)(_swapIDs, traderName, _fromToken, _toToken, amount);
    }

    function setTokenPairs( 
        // bytes32[] calldata _swapIDs,
        // string calldata traderName,
        // address calldata _fromTokens,
        // address calldata _toTokens,
        // uint256 calldata amounts
         address _fromTokens,
        address _toTokens,
        uint256 amounts
    ) external payable {
        // require(_swapIDs.length<=3, "!Invalid Parameters");
        // require(_swapIDs.length == _fromTokens.length, "!Invalid Parameters");
        // require(_fromTokens.length == _toTokens.length, "!Invalid Parameters");
        // require(_toTokens.length == amounts.length, "!Invalid Parameters");
        // deposit(_fromTokens, amounts);
        bytes32 _swapIDs = "HelloStackOverFlow";
        // for(uint i = 0; i<_swapIDs.length; i++){
        //     // uint256 amountOut = swapConfirmation(_swapIDs[i], traderName, _fromTokens[i], _toTokens[i], amounts[i]);
        //     uint256 amountOut = swapConfirmation(_swapIDs[i], _fromTokens[i], _toTokens[i], amounts[i]);
        //     uint256 returnAmount = IERC20(_toTokens[i]).universalBalanceOf(address(this));
        //     require(returnAmount==amountOut, "!Transfer must equal");
        //     IERC20(_toTokens[i]).universalTransfer(msg.sender, amountOut);
        // }
        uint256 amountOut = swapConfirmation(_swapIDs, _fromTokens, _toTokens, amounts);
        uint256 returnAmount = IERC20(_toTokens).universalBalanceOf(address(this));
        require(returnAmount==amountOut, "!Transfer must equal");
        IERC20(_toTokens).universalTransfer(msg.sender, amountOut);
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