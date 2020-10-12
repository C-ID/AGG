pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IUniswapV2Factory.sol";
import "./UniversalERC20.sol";
import "./ExchangeBase.sol";
import "./uniswapv2/uniswapv2Exchange.sol";


contract Controller is IERC20, Ownable{

    string public exchangeName;
    mapping (string => address) warehouse;


    constructor(string _exchangeName) public {
        governance = msg.sender;
        registExchange();
    }

    function registExchange() internal view{ 
        warehouse["uniswapv2"] = new Uniswapv2Exchange();
    }

    function setExchange(string _exchangename) public {
        require(msg.sender == governance, "!governance");
        exchangeName = _exchangename;
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
        require(msg.sender == exchangeName, "!exchange");
        returnAmount = warehouse[exchangeName]._getMulitExpectedReturn(fromToken, destToken, amount);
    }


    function muiltSwap(
        IERC20[] fromToken,
        IERC20[] destToken,
        uint256[] amount
    )
        public
        payable
        returns(
            uint256 returnAmount,
        )
    {
        require(fromToken.length <=3 || destToken <= 3 || amount <=3, "!Invalid Parameter");
        require(msg.sender == exchangeName, "!exchange name");
        warehouse[exchangeName]._muiltSwap(fromToken, destToken, amount);
    }