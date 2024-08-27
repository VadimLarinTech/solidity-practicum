pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/** 
 * @title RPSBaseERC20
 * @dev Base contract for the RPS token, implementing core ERC20 functionality with additional game-specific logic
 * for the Rock, Paper, Scissors game.
 */
abstract contract RPSBaseERC20 is IERC20, Ownable {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner;
    bool private _paused;

    uint256 private _totalSupply;
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) _allowances;

    constructor(string memory tokenName_, string memory tokenSymbol_, uint8 tokenDecimals_, uint256 amountOfMintTokens) Ownable(msg.sender) {
        _name = tokenName_;
        _symbol = tokenSymbol_;
        _decimals = tokenDecimals_;
        mint(owner(), amountOfMintTokens);
        _paused = false;
    }

    /**
     * MODIFIERS
     */

    /**
     * @dev Modifier that checks if the contract is paused.
     * Reverts if the contract is not paused.
     */
    modifier whenPaused() {
        require(_paused, "Contract is paused");
        _;
    }

    /**
     * @dev Modifier that checks if the contract is not paused.
     * Reverts if the contract is paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Contract isn't paused");
        _;
    }

    /**
     * ERRORS
     */

    /**
    * @notice Thrown when the sender's balance is insufficient for a transaction.
    * @param sender The address of the sender attempting the transaction.
    * @param balance The current balance of the sender.
    * @param needed The amount of tokens required for the transaction.
    */
    error InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
    * @notice Thrown when an invalid or incorrect address is provided.
    * @param sender The address that is considered incorrect or invalid.
    */
    error InvalidERC20Sender(address sender);

    /**
    * @notice Thrown when an invalid or incorrect address is provided.
    * @param receiver The address that is considered incorrect or invalid.
    */
    error InvalidERC20Receiver(address receiver);

    /**
    * @notice Thrown when the sender's allowance is insufficient to cover the transaction.
    * @param sender The address of the sender attempting to spend the tokens.
    * @param currentAllowance The current allowance the sender has.
    * @param neededAllowance The required allowance for the transaction.
    */
    error InsufficientAllowance(address sender, uint256 currentAllowance, uint256 neededAllowance);

    /**
     * FUNCTIONALITY
     */

    /**
    * @dev Token name
    */
    function name() public view virtual returns(string memory) {
        return _name;
    }

    /**
    * @dev Symbol of token
    */
    function symbol() public view virtual returns(string memory) {
        return _symbol;
    }

    /**
    * @dev Token decimals
    */
    function decimals() public view virtual returns(uint8) {
        return _decimals;
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view virtual returns(uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param addr The address to query the the balance of.
    * @return balance An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address addr) public view virtual returns(uint256 balance) {
        return _balances[addr];
    }

    /**
    * @dev Transfer token to a specified address from msg.sender.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public virtual returns(bool success) {
        address owner_ = msg.sender;
        _transfer(owner_, to, value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner_ address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return remaining A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner_, address spender) public view virtual returns(uint256 remaining) {
        return _allowances[owner_][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public virtual returns(bool success) {
        address owner_ = msg.sender;
        if (spender == address(0)) {
            revert InvalidERC20Receiver(spender);
        }
        _allowances[owner_][spender] = value;
        emit Approval(owner_, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns(bool success) {
        address spender = msg.sender;
        if (_allowances[from][spender] < value) {
            revert InsufficientAllowance(to, _allowances[from][spender], value);
        }
        _transfer(from, to, value);
        _allowances[from][spender] -= value;
        return true;
    }

    /**
    * @dev Mints `amount` of tokens to the `account`.
    * Can only be called by the owner.
    * Can only be called when the contract is not paused.
    * 
    * Requirements:
    * - `account` cannot be the zero address.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * @param account The address that will receive the minted tokens.
    * @param amount The amount of tokens to mint.
    */
    function mint(address account, uint256 amount) public onlyOwner whenNotPaused {
        if (account == address(0)) {
            revert InvalidERC20Receiver(account);
        }
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev Burns `amount` of tokens from the `account`.
    * Can only be called by the owner.
    * 
    * Requirements:
    * - `account` cannot be the zero address.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * @param account The address from which the tokens will be burned.
    * @param amount The amount of tokens to burn.
    */
    function burn(address account, uint256 amount) public onlyOwner {
        if (account == address(0)) {
            revert InvalidERC20Receiver(account);
        }
        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets the contract to the paused state.
     * Can only be called by the owner and when the contract is not paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
    }

    /**
     * @dev Unpauses the contract.
     * Can only be called by the owner and when the contract is paused.
     */
    function unpause() external onlyOwner whenPaused() {
        _paused = false;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert InvalidERC20Sender(from);
        }
        if (to == address(0)) {
            revert InvalidERC20Receiver(to);
        }
        if (_balances[from] < value) {
            revert InsufficientBalance(from, _balances[from], value); 
        }
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;
        emit Transfer(from, to, value);
    }
}