pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol";
// import "./IBalancerPool.sol";


interface IBRegistry {
    function getBestPoolsWithLimit(address fromToken, address destToken, uint256 limit)
        external view returns(address[] memory pools);
}
