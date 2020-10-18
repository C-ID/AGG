// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/ownership/Ownable.sol";
import "../interfaces/uniswapv2/IUniswapV2Factory.sol";
import "./UniversalERC20.sol";
import "./ExchangeBase.sol";
import "./uniswapv2/uniswapv2Exchange.sol";



contract Controller is Ownable{

    string public exchangeName;
    using UniversalERC20 for IERC20;
    using SafeMath for uint256;
    mapping (address => uint256) public warehouse;
    Uniswapv2Exchange public uniswapv2;
    uint256 public confirmed;
    uint256 public confirmed_;
    
    function() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    constructor() public {
        registExchange();
    }

    function registExchange() internal { 
        uniswapv2 = new Uniswapv2Exchange();
    }

    function setExchange(string memory _exchangename) public {
        exchangeName = _exchangename;
    }

    function getMulitExpectedReturn(
        IERC20[] memory fromToken,
        IERC20[] memory destToken,
        uint256[] memory amount
    )
        public
        view
        returns(
            uint256[] memory returnAmount
        )
    {
        // require(fromToken.length <=3 || destToken <= 3 || amount <=3, "!Invalid Parameter");
        // require(msg.sender == exchangeName, "!exchange");
        returnAmount = uniswapv2._getMulitExpectedReturn(fromToken, destToken, amount);
    }


    function muiltSwap(
        IERC20[] memory fromToken,
        IERC20[] memory destToken,
        uint256[] memory amount
    )
        public
        payable
        returns(
            uint256[] memory returnAmount
        )
    {
        require(fromToken.length <=3 || destToken.length <= 3 || amount.length <=3, "!Invalid Parameter");
        // require(msg.value != 0, "!Invalid Amount");
        // returnAmount = new uint256[](fromToken.length);
        for(uint i=0; i<fromToken.length; i++)
        {
            
            warehouse[fromToken[i]] = fromToken[i].universalBalanceOf(msg.sender);
            // fromToken[i].universalTransferFromSenderToThis(msg.value);
            // confirmed_ = fromToken[i].balanceOf(address(this));
            // fromToken[i].universalTransferFromSenderToThis(
            //     Math.min(
            //             fromToken[i].balanceOf(msg.sender),
            //             fromToken[i].allowance(msg.sender, address(this))
            //         ));
            // confirmed_ = fromToken[i].universalBalanceOf(address(this)).sub(amount[0]);
            // fromToken[i].universalApprove(address(uniswapv2), amount[i]);
            // returnAmount = uniswapv2._muiltSwap.value(confirmed)(fromToken, destToken, amount);
            
        }
    // confirmed = fromToken[0].universalBalanceOf(msg.sender);
    // fromToken[0].universalTransferFromSenderToThis(
    //             amount[0] != uint256(-1)
    //                 ? amount[0]
    //                 : Math.min(
    //                     fromToken[0].balanceOf(msg.sender),
    //                     fromToken[0].allowance(msg.sender, address(this))
    //                 ));
    // confirmed_ = fromToken[0].universalBalanceOf(address(this)).sub(amount[0]);
    
    }
}
