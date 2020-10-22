// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/ownership/Ownable.sol";
import "../interfaces/uniswapv2/IUniswapV2Factory.sol";
import "./UniversalERC20.sol";
import "./AtomicSwapper.sol";
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

contract swapTradeControllor is Ownable{
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;
    string public VERSION; // Passed in as a constructor parameter.
    
    AtomicSwapper public swapper;
    address constant public ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
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
    function deposit(address _token, uint256 _value) internal {
        address trader = msg.sender;

        uint256 receivedValue = _value;
        if (IERC20(_token).isETH()) {
            require(msg.value == _value, "mismatched value parameter and tx value");
        } else {
            require(msg.value == 0, "unexpected ether transfer");
            IERC20(_token).universalTransferFromSenderToThis(_value);
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
    function withdraw(address _token, uint256 _value) internal {
        address payable trader = msg.sender;

        privateDecrementBalance(trader, _token, _value);
        if (IERC20(_token).isETH()) {
            trader.transfer(_value);
        } else {
            IERC20(_token).universalTransfer(trader, _value);
        }
    }

    /// @notice swap trade confirm action. with no parameters owing to initiate func.
    function swapConfirmation(
        bytes32 _swapIDs,
        string memory traderName,
        address _fromTokens,
        address _toTokens,
        uint256 amounts
        ) internal returns(uint256 amountOut){
        amountOut = swapper.redeem(_swapIDs, traderName, IERC20(_fromTokens), IERC20(_toTokens), amounts);
    }

    function setTokenPairs( 
        bytes32[] calldata _swapIDs,
        string calldata traderName,
        address[] calldata _fromTokens,
        address[] calldata _toTokens,
        uint256[] calldata amounts
    ) external payable {
        require(_swapIDs.length<=3, "!Invalid Parameters");
        require(_swapIDs.length == _fromTokens.length, "!Invalid Parameters");
        require(_fromTokens.length == _toTokens.length, "!Invalid Parameters");
        require(_toTokens.length == amounts.length, "!Invalid Parameters");
        for(uint i = 0; i<_swapIDs.length; i++){
            IERC20(_fromTokens[i]).universalApprove(address(this), amounts[i]);
            deposit(_fromTokens[i], amounts[i]);
            uint256 amountOut = swapConfirmation(_swapIDs[i], traderName, _fromTokens[i], _toTokens[i], amounts[i]);
            IERC20(_toTokens[i]).universalTransfer(msg.sender, amountOut);
        }
        // if (_swapIDs.length==1)
        // {
        //     // IERC20(_fromTokens[0]).universalApprove(address(this), amounts[0]);
        //     // deposit(_fromTokens[0], amounts[0]);
        //     // (amountIn, from_, to_, name, sender, amountOut) = swapConfirmation(_swapIDs[0], traderName, _fromTokens[0], _toTokens[0], amounts[0]);
        //     // IERC20(_toTokens[0]).universalTransfer(msg.sender, amountOut);
        // }
        // else if(_swapIDs.length==2)
        // {
        //     swapper.initiate(_swapIDs[0], traderName, _fromTokens[0], _toTokens[0], amounts[0]);
        //     swapper.initiate(_swapIDs[1], traderName, _fromTokens[1], _toTokens[1], amounts[1]);
        // }
        // else if(_swapIDs.length==3)
        // {
        //     swapper.initiate(_swapIDs[0], traderName, _fromTokens[0], _toTokens[0], amounts[0]);
        //     swapper.initiate(_swapIDs[1], traderName, _fromTokens[1], _toTokens[1], amounts[1]);
        //     swapper.initiate(_swapIDs[2], traderName, _fromTokens[2], _toTokens[2], amounts[2]);
        // }
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