pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TreasuryManager {
    address public owner;
    
    event Deposit(address indexed from, uint amount);
    event Withdrawal(address indexed to, uint amount);
    event TokenWithdrawal(address indexed token, address indexed to, uint amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "owner:!");
        _;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function spend(address payable _to, uint _amount) public onlyOwner {
        require(_to != address(0), "zero:!");
        require(address(this).balance >= _amount, "funds:!");
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "send:!");
        emit Withdrawal(_to, _amount);
    }

    function spendToken(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        require(_to != address(0), "zero:!");
        require(_tokenAddress != address(0), "zero:!");
        
        IERC20 token = IERC20(_tokenAddress);
        uint balance = token.balanceOf(address(this));
        require(balance >= _amount, "funds:!");
        
        token.transfer(_to, _amount);
        
        emit TokenWithdrawal(_tokenAddress, _to, _amount);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "zero:!");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getTokenBalance(address _tokenAddress) public view returns (uint) {
        require(_tokenAddress != address(0), "zero:!");
        return IERC20(_tokenAddress).balanceOf(address(this));
    }
}

