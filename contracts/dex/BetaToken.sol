pragma solidity ^0.8.20;

import "contracts/tokens/RPSBaseERC20.sol";

contract BetaToken is RPSBaseERC20 {
    constructor() RPSBaseERC20("BetaToken", "BETA", 18, 1000000) {
        
    }
}