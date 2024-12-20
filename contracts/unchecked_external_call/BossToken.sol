pragma solidity ^0.4.18;
contract Token {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {
    event TransferExecuted(address indexed _from, address indexed _to, uint256 _value);
    event TransferFailed(address indexed _from, address indexed _to, uint256 _value);
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            emit TransferExecuted(msg.sender, _to, _value);
            return true;
        } else {
            emit TransferFailed(msg.sender, _to, _value);
            return false;
        }
    }

    event TransferFromExecuted(address indexed _from, address indexed _to, uint256 _value);
    event TransferFromFailed(address indexed _from, address indexed _to, uint256 _value);
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            emit TransferFromExecuted(_from, _to, _value);
            return true;
        } else {
            emit TransferFromFailed(_from, _to, _value);
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}
contract BossToken is StandardToken {
    function () { throw; }

    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'H1.0';

    event ContractCreated(address indexed creator, uint256 totalSupply);

    function BossToken() {
        balances[msg.sender] = 30000000000000000000000000;
        totalSupply = 30000000000000000000000000;
        name = 'BossToken';
        decimals = 18;
        symbol = 'BOSS';
        emit ContractCreated(msg.sender, totalSupply);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if (!_spender.call(bytes4(bytes32(sha3('receiveApproval(address,uint256,address,bytes)'))), msg.sender, _value, this, _extraData)) {
            throw;
        }
        return true;
    }
}
