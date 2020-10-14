// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/ownership/Ownable.sol";
import "../interfaces/uniswapv2/IUniswapV2Factory.sol";
import "./UniversalERC20.sol";
import "./ExchangeBase.sol";
import "./uniswapv2/uniswapv2Exchange.sol";



contract Controller is IERC20, Ownable{

    string public exchangeName;
    mapping (string => address) warehouse;


    constructor() public {
        registExchange();
    }

    function registExchange() internal view{ 
        warehouse["uniswapv2"] = new Uniswapv2Exchange();
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
        require(fromToken.length <=3 || destToken <= 3 || amount <=3, "!Invalid Parameter");
        require(msg.sender == exchangeName, "!exchange");
        returnAmount = warehouse[exchangeName]._getMulitExpectedReturn(fromToken, destToken, amount);
    }


    function muiltSwap(
        IERC20[] memory fromToken,
        IERC20[] memory destToken,
        uint256[] memory amount
    )
        public
        payable
        returns(
            uint256 returnAmount
        )
    {
        require(fromToken.length <=3 || destToken <= 3 || amount <=3, "!Invalid Parameter");
        require(msg.sender == exchangeName, "!exchange name");
        warehouse[exchangeName]._muiltSwap(fromToken, destToken, amount);
    }
}
