pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BaseDEX is Ownable {
    mapping(address => bool) private _listings;
    mapping(address => mapping(address => uint256)) private _tokenRates;

    constructor() Ownable(msg.sender) {

    }

    /**
    * @dev Emitted when a swap occurs.
    * @param customer Address of the customer performing the swap.
    * @param soldToken Address of the token being sold.
    * @param boughtToken Address of the token being bought.
    * @param amountSoldTokens Amount of sold tokens.
    */
    event Swap(address indexed customer, address indexed soldToken, address indexed boughtToken, uint256 amountSoldTokens);

    /**
    * @dev Modifier that checks if tokens are listed and not the same.
    * @param tokenToSell Address of the token to be sold.
    * @param tokenToBuy Address of the token to be bought.
    */
    modifier onlyForListed(address tokenToSell, address tokenToBuy) {
        require(tokenToSell == address(0) || _listings[tokenToSell] == true, "Token to buy must be listed");
        require(tokenToBuy == address(0) || _listings[tokenToBuy] == true, "Token to sell must be listed");
        require(tokenToSell != tokenToBuy, "Can not swap the same token");
        _;
    }

    /**
    * @dev Allows the owner to list a new token contract.
    * @param listingTokenContract Address of the token contract to be listed.
    */
    function tokenListing(address listingTokenContract) external onlyOwner() {
        _listings[listingTokenContract] = true;
    }

    /**
    * @dev Allows the owner to delist a token contract.
    * @param delistingTokenContract Address of the token contract to be removed from the listining.
    */
    function tokenDelisting(address delistingTokenContract) external onlyOwner() {
        _listings[delistingTokenContract] = false;
    }

    /**
    * @dev Sets the swap rate between two tokens.
    * @param tokenToSell Address of the token to be sold.
    * @param tokenToBuy Address of the token to be bought.
    * @param rate The rate at which the `tokenToSell` is exchanged for `tokenToBuy`.
    */
    function setSwapRate(address tokenToSell, address tokenToBuy, uint256 rate) external {
        _tokenRates[tokenToSell][tokenToBuy] = rate;
    }

    /**
     * @dev Returns the swap rate between two tokens.
     * @param tokenToSell Address of the token to be sold.
     * @param tokenToBuy Address of the token to be bought.
     * @return rate The rate at which the `tokenToSell` is exchanged for `tokenToBuy`.
     */
    function getSwapRate(address tokenToSell, address tokenToBuy) view public returns(uint256) {
        return _tokenRates[tokenToSell][tokenToBuy];
    }

    /**
    * @dev Swaps tokens or ETH between the caller and the contract.
    * 
    * This function supports the following scenarios:
    * 1. Selling ETH for a token: The caller sends ETH to the contract and receives tokens in return.
    * 2. Buying ETH with a token: The caller sends tokens to the contract and receives ETH in return.
    * 3. Swapping one token for another token: The caller exchanges one token for another.
    * 
    * Requirements:
    * - Tokens involved in the transaction must be listed on the platform.
    * - For ETH transactions, `msg.value` must match the `amount` being swapped.
    * 
    * @param tokenToSell The address of the token to sell. Use address(0) to indicate ETH.
    * @param tokenToBuy The address of the token to buy. Use address(0) to indicate ETH.
    * @param amount The amount of tokens or ETH to swap.
    */
    function swapTokens(address tokenToSell, address tokenToBuy, uint256 amount) public onlyForListed(tokenToSell, tokenToBuy) payable {
        // To sell Eth, get Token, send Eth
        if (tokenToSell == address(0)) {
            require(msg.value == amount, "Ethereum value must be same with amount of buing token");
            // @TODO: Implement swap rate calculation and apply it to the transfer
            require(IERC20(tokenToBuy).transfer(msg.sender, amount),"Unsuccessful transfer to buy token");
            emit Swap(msg.sender, tokenToSell, tokenToBuy, amount);                        
        }
        // To buy Eth, to sell Token, send Token, get Eth
        else if (tokenToBuy == address(0)) {
            require(address(this).balance >= amount, "Insufficient the Contract Eth balance");
            require(IERC20(tokenToSell).transferFrom(msg.sender, address(this), amount), "Unsuccessful transfer to sell token");
            (bool successCall, ) = msg.sender.call{value: amount}("");
            require(successCall, "Unsuccessful transfer Eth");
            emit Swap(msg.sender, tokenToSell, tokenToBuy, amount);
        } else {
        require(IERC20(tokenToSell).transferFrom(msg.sender, address(this), amount),"Unsuccessful transfer to sell token");
        require(IERC20(tokenToBuy).transfer(msg.sender, amount),"Unsuccessful transfer to buy token");
        emit Swap(msg.sender, tokenToSell, tokenToBuy, amount);
        }
    }

    /**
    * @dev Allows the owner to withdraw Eth from the contract.
    * @param amount The amount of Eth to withdraw.
    */
    function withdrawEthereum(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool succesfulCall, ) = msg.sender.call{value: amount}("");
        require(succesfulCall, "Failed to withdraw Ether");
    }

    receive() external payable {}
}