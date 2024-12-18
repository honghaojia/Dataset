pragma solidity ^0.4.4;
contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
contract Token {
    function totalSupply() public constant returns (uint256 supply) {}
    function balanceOf(address _owner) public constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) public returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
    function approve(address _spender, uint256 _value) public returns (bool success) {}
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is owned, Token {
    event TransferSuccessful(address indexed _from, address indexed _to, uint256 _value);
    event TransferFailed(address indexed _from, address indexed _to, uint256 _value);
    
    function transfer(address _to, uint256 _value) onlyOwner public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            emit TransferSuccessful(msg.sender, _to, _value);
            return true;
        } else {
            emit TransferFailed(msg.sender, _to, _value);
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            emit TransferSuccessful(_from, _to, _value);
            return true;
        } else {
            emit TransferFailed(_from, _to, _value);
            return false;
        }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}
contract Eclipse is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'H1.0';
    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;
    address public fundsWallet;
    uint256 public total_supply;

    event EtherReceived(address indexed from, uint256 amount);

    function Eclipse() public {
        total_supply = 1000000000 * 10 ** uint256(18);
        balances[msg.sender] = total_supply;
        totalSupply = total_supply;
        name = 'Eclipse';
        decimals = 18;
        symbol = 'ECP';
        unitsOneEthCanBuy = 1893;
        fundsWallet = msg.sender;
    }

    function changeOwnerWithTokens(address newOwner) onlyOwner public {
        owner = newOwner;
        balances[owner] += balances[fundsWallet];
        balances[fundsWallet] = 0;
        fundsWallet = owner;
    }

    function changePrice(uint256 _newAmount) onlyOwner public {
        unitsOneEthCanBuy = _newAmount;
    }

    function() public payable {
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);
        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        Transfer(fundsWallet, msg.sender, amount);
        emit EtherReceived(msg.sender, msg.value);
        fundsWallet.transfer(msg.value);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}
