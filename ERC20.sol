// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IERC20.sol";
import "./Safemath.sol";

contract MyToken is IERC20 {
    using SafeMath for uint256;

    uint256 timeTillTransactionLock;

    // Mapping hold balances against EOA.
    mapping(address => uint256) private _balances;

    // Mapping to hold approved allowances of token to certain address
    mapping(address => mapping(address => uint256)) private _allowances;

    // Amount of token in existance
    uint256 private _totalSupply;
    // Capped amount limit
    uint256 private _cappedLimit;

    address owner;
    string name;
    string symbol;
    uint8 decimals;

    constructor() {
        name = "MS-Token";
        symbol = "MS";
        decimals = 18;
        owner = msg.sender;

        // 1 millions token to be generated
        _totalSupply = 1000000 * 10**uint256(decimals);

        // setting cap limit to 21 million
        _cappedLimit = 21000000 * 10**uint256(decimals);

        // Setting total supply (1 million) to token owner address
        _balances[owner] = _totalSupply;

        // fire an event on transfer of tokens
        emit Transfer(address(this), owner, _totalSupply);
    }

    modifier onlyOwner(address _owner, uint256 amount) {
        require(msg.sender == _owner, "404, Unauthorize person to mint tokens");
        require(amount + _totalSupply < _cappedLimit, "capped limit reached");
        _;
    }

    // mint token
    function mint(address _owner, uint256 amount)
        public
        onlyOwner(_owner, amount)
        returns (uint256)
    {
        _totalSupply += amount;
        return _totalSupply;
    }

    // timebound function
    function lockTransferUntil(uint256 time) public {
        require(
            time > 0 && time < block.timestamp,
            "Time must be greater than current time. "
        );
        timeTillTransactionLock = time;
    }

    function _beforeTokenTransfer(address to, uint256 amount) public {
        require(
            timeTillTransactionLock < block.timestamp,
            "Sorry, token is locked"
        );
        transfer(to, amount);
    }

    // returning totalsupply remaining in contract
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // returning balanceOf that specific address
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // transfering amount from one account to another
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address sender = msg.sender; // the person who is calling this function
        require(sender != address(0), "Sender address is required"); // null address | burn address
        require(recipient != address(0), "Receipent address is required");
        require(_balances[sender] > amount, "Not suffecient funds");

        _balances[recipient] = _balances[recipient] + amount;
        _balances[sender] = _balances[sender] - amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    // checking remaining amount of tokens that are approved to specific address
    function allowance(address _owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        address sender = msg.sender; // the person who is calling this function
        require(sender != address(0), "Sender address is required"); // null address | burn address
        require(_balances[sender] > amount, "Not suffecient funds");

        _allowances[sender][spender] = amount;

        emit Approval(sender, spender, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        address spender = msg.sender; // the person who is calling this function
        require(
            sender != address(0),
            "Sender address should not be null address"
        );
        require(
            recipient != address(0),
            "Recipient address should not be null address"
        );
        require(_allowances[sender][spender] > amount, "Not allowed");

        // deducting allowance
        _allowances[sender][spender] = _allowances[sender][spender] - amount;
        // deducting sender amount from balance
        _balances[sender] = _balances[sender] - amount;
        // adding amount to recipient address
        _balances[recipient] = _balances[recipient] + amount;
        // firing event for dapp
        emit Transfer(sender, recipient, amount);

        return true;
    }
}
