pragma solidity ^0.4.4;
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
    event TransferSuccess(address indexed _from, address indexed _to, uint256 _value);
    event TransferFail(address indexed _from, address indexed _to, uint256 _value);
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            emit TransferSuccess(msg.sender, _to, _value);
            return true;
        } else {
            emit TransferFail(msg.sender, _to, _value);
            return false;
        }
    }

    event TransferFromSuccess(address indexed _from, address indexed _to, uint256 _value);
    event TransferFromFail(address indexed _from, address indexed _to, uint256 _value);

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            emit TransferFromSuccess(_from, _to, _value);
            return true;
        } else {
            emit TransferFromFail(_from, _to, _value);
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    event ApprovalSuccess(address indexed _owner, address indexed _spender, uint256 _value);

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        emit ApprovalSuccess(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}
contract BitFinTechToken is StandardToken {
    function () {
        throw;
    }
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'H1.0';

    event TokenCreated(address indexed creator, uint256 totalSupply);
    
    function BitFinTechToken() {
        balances[msg.sender] = 26888888000000000000000000;
        totalSupply = 26888888000000000000000000;
        name = 'BitFinTech';
        decimals = 18;
        symbol = 'BFI';
        emit TokenCreated(msg.sender, totalSupply);
    }

    event ApproveAndCallSuccess(address indexed _spender, uint256 _value);
    event ApproveAndCallFail(address indexed _spender, uint256 _value);

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        emit ApproveAndCallSuccess(_spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3('receiveApproval(address,uint256,address,bytes)'))), msg.sender, _value, this, _extraData)) {
            emit ApproveAndCallFail(_spender, _value);
            throw;
        }
        return true;
    }
}