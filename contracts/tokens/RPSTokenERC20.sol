pragma solidity ^0.8.20;

import "./RPSBaseERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RPSTokenERC20 is RPSBaseERC20 {
    uint256 public constant COMMISSION_PERCENTAGE = 2; /// todo feature

    constructor() RPSBaseERC20("RPSToken", "RPS", 18, 1000000) {

    }

}