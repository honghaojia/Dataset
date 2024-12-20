pragma solidity ^0.4.19;
contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) { revert(); }
        _;
    }

    function changeOwner(address newowner) public onlyOwner {
        owner = newowner;
        emit OwnerChanged(newowner);
    }
    
    event OwnerChanged(address newOwner);
}
interface tokenRecipient {
    function receiveApproval(address from, uint256 value, bytes data) public;
}
interface ContractReceiver {
    function tokenFallback(address from, uint value, bytes data) public;
}
contract HashBux is owned {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) balances_;
    mapping(address => mapping(address => uint256)) allowances_;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
    event Burn(address indexed from, uint256 value);
    
    function HashBux() public {
        balances_[msg.sender] = uint256(80000000);
        totalSupply = uint256(80000000);
        name = 'HashBux';
        decimals = uint8(0);
        symbol = 'HASH';
        emit TokenCreated(msg.sender, totalSupply);
    }

    event TokenCreated(address indexed creator, uint256 totalSupply);

    function mine(uint256 newTokens) public onlyOwner {
        if (newTokens + totalSupply > 4e9) revert();
        totalSupply += newTokens;
        balances_[owner] += newTokens;
        bytes memory empty;
        Transfer(address(this), owner, newTokens, empty);
        emit TokensMined(newTokens);
    }
    
    event TokensMined(uint256 newTokens);

    function() public payable { revert(); }

    function balanceOf(address owner) public constant returns (uint) {
        return balances_[owner];
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowances_[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        emit ApprovalEvent(msg.sender, spender, value);
        return true;
    }
    
    event ApprovalEvent(address indexed owner, address indexed spender, uint256 value);

    function allowance(address owner, address spender) public constant returns (uint256 remaining) {
        return allowances_[owner][spender];
    }

    function transfer(address to, uint256 value) public {
        bytes memory empty;
        _transfer(msg.sender, to, value, empty);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowances_[from][msg.sender]);
        allowances_[from][msg.sender] -= value;
        bytes memory empty;
        _transfer(from, to, value, empty);
        emit TransferFromEvent(from, to, value);
        return true;
    }
    
    event TransferFromEvent(address indexed from, address indexed to, uint256 value);

    function approveAndCall(address spender, uint256 value, bytes context) public returns (bool success) {
        if (approve(spender, value)) {
            tokenRecipient recip = tokenRecipient(spender);
            recip.receiveApproval(msg.sender, value, context);
            emit ApprovalAndCallEvent(spender, value);
            return true;
        }
        return false;
    }
    
    event ApprovalAndCallEvent(address indexed spender, uint256 value);

    function burn(uint256 value) public returns (bool success) {
        require(balances_[msg.sender] >= value);
        balances_[msg.sender] -= value;
        totalSupply -= value;
        Burn(msg.sender, value);
        emit TokensBurned(msg.sender, value);
        return true;
    }
    
    event TokensBurned(address indexed from, uint256 value);

    function burnFrom(address from, uint256 value) public returns (bool success) {
        require(balances_[from] >= value);
        require(value <= allowances_[from][msg.sender]);
        balances_[from] -= value;
        allowances_[from][msg.sender] -= value;
        totalSupply -= value;
        Burn(from, value);
        emit BurnFromEvent(from, value);
        return true;
    }
    
    event BurnFromEvent(address indexed from, uint256 value);

    function _transfer(address from, address to, uint value, bytes data) internal {
        require(to != 0x0);
        require(balances_[from] >= value);
        require(balances_[to] + value > balances_[to]);
        balances_[from] -= value;
        balances_[to] += value;
        Transfer(from, to, value, data);
        emit TransferEvent(from, to, value);
    }
    
    event TransferEvent(address indexed from, address indexed to, uint256 value);

    function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool success) {
        _transfer(msg.sender, to, value, data);
        if (isContract(to)) {
            ContractReceiver rx = ContractReceiver(to);
            require(rx.call.value(0)(bytes4(keccak256(custom_fallback)), msg.sender, value, data));
            emit TransferWithFallbackEvent(to, value, custom_fallback);
        }
        return true;
    }
    
    event TransferWithFallbackEvent(address indexed to, uint256 value, string custom_fallback);

    function transfer(address to, uint value, bytes data) public returns (bool success) {
        if (isContract(to)) {
            return transferToContract(to, value, data);
        }
        _transfer(msg.sender, to, value, data);
        return true;
    }

    function transferToContract(address to, uint value, bytes data) private returns (bool success) {
        _transfer(msg.sender, to, value, data);
        ContractReceiver rx = ContractReceiver(to);
        rx.tokenFallback(msg.sender, value, data);
        emit TransferToContractEvent(to, value);
        return true;
    }
    
    event TransferToContractEvent(address indexed to, uint256 value);

    function isContract(address _addr) private constant returns (bool) {
        uint length;
        assembly { length := extcodesize(_addr) }
        return (length > 0);
    }
}
