// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/ownership/Ownable.sol";
import "../interfaces/uniswapv2/IUniswapV2Factory.sol";
import "./UniversalERC20.sol";
import "./DexExchangePlatform.sol";
// import "./uniswapv2/uniswapv2Exchange.sol";



// contract Controller is Ownable{

//     string public exchangeName;
//     using UniversalERC20 for IERC20;
//     using SafeMath for uint256;
//     mapping (address => uint256) public warehouse;
//     Uniswapv2Exchange public uniswapv2;
//     uint256 public confirmed;
//     uint256 public confirmed_;
    
//     function() external payable {
//         // solium-disable-next-line security/no-tx-origin
//         require(msg.sender != tx.origin);
//     }
//     constructor() public {
//         registExchange();
//     }

//     function registExchange() internal view{ 
//         warehouse["uniswapv2"] = new Uniswapv2Exchange();
//     }

//     function setExchange(string memory _exchangename) public {
//         exchangeName = _exchangename;
//     }

//     function getMulitExpectedReturn(
//         IERC20[] memory fromToken,
//         IERC20[] memory destToken,
//         uint256[] memory amount
//     )
//         public
//         view
//         returns(
//             uint256[] memory returnAmount
//         )
//     {
//         // require(fromToken.length <=3 || destToken <= 3 || amount <=3, "!Invalid Parameter");
//         // require(msg.sender == exchangeName, "!exchange");
//         returnAmount = warehouse[exchangeName]._getMulitExpectedReturn(fromToken, destToken, amount);
//     }


//     function muiltSwap(
//         IERC20[] memory fromToken,
//         IERC20[] memory destToken,
//         uint256[] memory amount
//     )
//         public
//         payable
//         returns(
//             uint256 returnAmount
//         )
//     {
//         require(fromToken.length <=3 || destToken <= 3 || amount <=3, "!Invalid Parameter");
//         require(msg.sender == exchangeName, "!exchange name");
//         warehouse[exchangeName]._muiltSwap(fromToken, destToken, amount);
//     }
// }

/// @notice AtomicSwapper implements the atomic swapping interface
/// for token Swap in Dex Exchange platform...
contract AtomicSwapper {
    
    string public VERSION; // Passed in as a constructor parameter.
    DexExchangePlatform public factory;
    
    struct Swap{
        uint256 value;
        uint256 openAmount;
        address payable openTrader;
        string exchangeName;
        IERC20 fromToken;
        IERC20 toToken;
        function(IERC20, IERC20, uint256) swapTrader;
        function(IERC20, IERC20, uint256) visiTrader;
    }
    
    struct tokenPair{
        IERC20 fromToken;
        IERC20 destToken;
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
    mapping (bytes32 => uint256) public redeemedTime;
    mapping (string => function(IERC20, IERC20, uint256)) private traderFactory;
    mapping (string => function(IERC20, IERC20, uint256)) private traderVisFactory;

    //Events
    event LogOpen(bytes32 _swapID, string exchangeName);
    event LogExpire(bytes32 _swapID);
    event LogClose(bytes32 _swapID, bytes32 _secretKey);


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
    
    // modifier onlyExpirableSwaps(bytes32 _swapID) {
    //     /* solium-disable-next-line security/no-block-members */
    //     require(now >= swaps[_swapID].timelock, "swap not expirable");
    //     _;
    // }

    /// @notice Throws if the swap is not closed.
    modifier onlyClosedSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.CLOSED, "swap not redeemed");
        _;
    }

    /// @notice Throws if the secret key is not valid.
    // modifier onlyWithSecretKey(bytes32 _swapID, bytes32 _secretKey) {
    //     require(swaps[_swapID].secretLock == sha256(abi.encodePacked(_secretKey)), "invalid secret");
    //     _;
    // }

    constructor(
        string memory _VERSION,
        DexExchangePlatform _factory
    ) public {
        VERSION = _VERSION;
        factory = _factory;
    }
    
    function registExchange() internal pure {
        
    }

    /// @notice Initiates the atomic swap.
    ///
    /// @param _swapID The unique atomic swap id.
    /// @param _withdrawTrader The address of the withdrawing trader.
    /// @param _secretLock The hash of the secret (Hash Lock).
    /// @param _timelock The unix timestamp when the swap expires.
    function initiate(
        bytes32 _swapID,
        string memory traderName,
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 amount
    ) internal view onlyInvalidSwaps(_swapID) {
        // Store the details of the swap.
        Swap memory swap = Swap({
            value: msg.value,
            openTrader: msg.sender,
            openAmount: amount,
            exchangeName: traderName,
            fromToken: _fromToken,
            toToken: _toToken,
            swapTrader: traderFactory[traderName],
            visiTrader: traderVisFactory[traderName]
        });
        swaps[_swapID] = swap;
        swapStates[_swapID] = States.OPEN;

        // Logs open event
        emit LogOpen(_swapID, traderName);
    }

    /// @notice Redeems an atomic swap.
    ///
    /// @param _swapID The unique atomic swap id.
    /// @param _secretKey The secret of the atomic swap.
    function redeem(bytes32 _swapID, bytes32 _secretKey) external onlyOpenSwaps(_swapID) {
        // Close the swap.

        swapStates[_swapID] = States.CLOSED;
        /* solium-disable-next-line security/no-block-members */
        redeemedTime[_swapID] = now;

        // Transfer the ETH funds from this contract to the withdrawing trader.
        // swaps[_swapID].swapTrader(swaps[_swapID].value);

        // Logs close event
        emit LogClose(_swapID, _secretKey);
    }

    /// @notice Refunds an atomic swap.
    ///
    /// @param _swapID The unique atomic swap id.
    function refund(bytes32 _swapID) external onlyOpenSwaps(_swapID) {
        // Expire the swap.
        swapStates[_swapID] = States.EXPIRED;

        // Transfer the ETH value from this contract back to the ETH trader.
        swaps[_swapID].openTrader.transfer(swaps[_swapID].value);

        // Logs expire event
        emit LogExpire(_swapID);
    }

    /// @notice Audits an atomic swap.
    ///
    /// @param _swapID The unique atomic swap id.
    function audit(bytes32 _swapID) external view returns (uint256 value, IERC20 from, IERC20 to, string memory name, address customer) {
        Swap memory swap = swaps[_swapID];
        return (
            swap.value,
            swap.fromToken,
            swap.toToken,
            swap.exchangeName,
            swap.openTrader
        );
    }

    /// @notice Audits the secret of an atomic swap.
    ///
    /// @param _swapID The unique atomic swap id.
    // function auditSecret(bytes32 _swapID) external view onlyClosedSwaps(_swapID) returns (bytes32 secretKey) {
    //     return swaps[_swapID].secretKey;
    // }

    /// @notice Checks whether a swap is refundable or not.
    ///
    /// @param _swapID The unique atomic swap id.
    // function refundable(bytes32 _swapID) external view returns (bool) {
    //     /* solium-disable-next-line security/no-block-members */
    //     return (now >= swaps[_swapID].timelock && swapStates[_swapID] == States.OPEN);
    // }

    /// @notice Checks whether a swap is initiatable or not.
    ///
    /// @param _swapID The unique atomic swap id.
    function initiatable(bytes32 _swapID) external view returns (bool) {
        return (swapStates[_swapID] == States.INVALID);
    }

    /// @notice Checks whether a swap is redeemable or not.
    ///
    /// @param _swapID The unique atomic swap id.
    function redeemable(bytes32 _swapID) external view returns (bool) {
        return (swapStates[_swapID] == States.OPEN);
    }

    /// @notice Generates a deterministic swap id using initiate swap details.
    ///
    /// @param _secretLock The hash of the secret.
    /// @param _timelock The expiry timestamp.
    function swapID(bytes32 _secretLock, uint256 _timelock) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_secretLock, _timelock));
    }
}


contract swapTradeControllor is Ownable{
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;
    string public VERSION; // Passed in as a constructor parameter.
    
    AtomicSwapper public swapper;
    address constant public ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    mapping(address => mapping(address => uint256)) public traderBalances;
    mapping(address => mapping(address => uint256)) public traderWithdrawalSignals;
    
    // Events
    event LogBalanceDecreased(address trader, IERC20 token, uint256 value);
    event LogBalanceIncreased(address trader, IERC20 token, uint256 value);
    event LogAtomicSwapperContractUpdated(address previousAtomicSwapperContract, address newAtomicSwapperContract);
    
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
    function deposit(IERC20 _token, uint256 _value) internal {
        address trader = msg.sender;

        uint256 receivedValue = _value;
        if (_token.isETH()) {
            require(msg.value == _value, "mismatched value parameter and tx value");
        } else {
            require(msg.value == 0, "unexpected ether transfer");
            receivedValue = _token.universalTransferFromSenderToThis(trader, address(this), _value);
        }
        privateIncrementBalance(trader, _token, receivedValue);
    }

    /// @notice Withdraws ETH or an ERC20 token from the contract. A broker
    /// signature is required to guarantee that the trader has a sufficient
    /// balance after accounting for open orders. As a trustless backup,
    /// traders can withdraw 48 hours after calling `signalBackupWithdraw`.
    ///
    /// @param _token The token's address.
    /// @param _value The amount to withdraw in the token's smallest unit.
    /// @param _signature The broker signature
    function withdraw(IERC20 _token, uint256 _value, bytes memory _signature) internal {
        address trader = msg.sender;

        privateDecrementBalance(trader, _token, _value);
        if (_token.isETH()) {
            trader.transfer(_value);
        } else {
            _token.universalTransfer(trader, _value);
        }
    }

    /// @notice swap trade confirm action. with no parameters owing to initiate func.
    function swapConfirmation() external payable {

    }

    function setTokenPairs() external view{
        
    }

    function privateIncrementBalance(address _trader, IERC20 _token, uint256 _value) private {
        traderBalances[_trader][_token] = traderBalances[_trader][_token].add(_value);

        emit LogBalanceIncreased(_trader, _token, _value);
    }

    function privateDecrementBalance(address _trader, IERC20 _token, uint256 _value) private {
        require(traderBalances[_trader][_token] >= _value, "insufficient funds");
        traderBalances[_trader][_token] = traderBalances[_trader][_token].sub(_value);

        emit LogBalanceDecreased(_trader, _token, _value);
    }
}