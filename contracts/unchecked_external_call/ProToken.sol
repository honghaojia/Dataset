pragma solidity ^0.4.8;
contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event TransferSuccessful(address indexed _from, address indexed _to, uint256 _value);
    event TransferFailed(address indexed _from, address indexed _to, uint256 _value);
    event TransferFromSuccessful(address indexed _from, address indexed _to, uint256 _value);
    event TransferFromFailed(address indexed _from, address indexed _to, uint256 _value);

    function transfer(address _to, uint256 _value) returns (bool success) {
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

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            emit TransferFromSuccessful(_from, _to, _value);
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
}
contract ProToken is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'PRO1.0';

    event ProTokenInitialized(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol);

    function ProToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        emit ProTokenInitialized(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3('receiveApproval(address,uint256,address,bytes)'))), msg.sender, _value, this, _extraData)) {
            revert();
        }
        
        return true;
    }
}
