pragma solidity ^0.4.4;
contract Token {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
}
contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            emit Transfer(msg.sender, _to, 0); // Emit event for failure case
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            emit Transfer(_from, _to, 0); // Emit event for failure case
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
contract ERC20Token is StandardToken {
    event ApprovalAndCall(address indexed _spender, uint256 _value, address indexed _from, bytes _extraData);

    function () {
        throw;
    }

    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'H1.0';

    function ERC20Token() {
        balances[msg.sender] = 10000000000000000;
        totalSupply = 10000000000000000;
        name = 'StakeIt';
        decimals = 8;
        symbol = 'STAKE';
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        emit ApprovalAndCall(_spender, _value, msg.sender, _extraData); // Emit event for approval call

        if(!_spender.call(bytes4(bytes32(sha3('receiveApproval(address,uint256,address,bytes)'))), msg.sender, _value, this, _extraData)) {
            throw;
        }
        return true;
    }
}