pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IUniswapV2Factory.sol";
import "./UniversalERC20.sol";
import "./Exchange.sol"


contract Controller is IERC20, Ownable{


    Exchange public exchange;

    constructor(address _exchange) public {
        governance = msg.sender;
        exchange = _exchange;
    }

    function setExchange(address _exchange) public {
        require(msg.sender == governance, "!governance");
        exchange = _exchange;
    }

    function getMulitExpectedReturn(
        IERC20[] fromToken,
        IERC20[] destToken,
        uint256[] amount
    )
        public
        view
        returns(
            uint256[] returnAmount
        )
    {
        require(fromToken.length <=3 || destToken <= 3 || amount <=3, "!Invalid Parameter");
        require(msg.sender == exchange, "!exchange");
        returnAmount = exchange._getMulitExpectedReturn(fromToken, destToken, amount);
    }


    function muiltSwap(
        IERC20[] fromToken,
        IERC20[] destToken,
        uint256[] amount
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        require(fromToken.length <=3 || destToken <= 3 || amount <=3, "!Invalid Parameter");
        require(msg.sender == exchange, "!exchange");
        exchange._muiltSwap(fromToken, destToken, amount);
    }