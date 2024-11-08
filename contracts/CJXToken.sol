pragma solidity ^0.4.15;
contract ERC20 {
    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event TransferSuccess(address indexed _from, address indexed _to, uint256 _value);
    event TransferFromSuccess(address indexed _from, address indexed _to, uint256 _value);
    event ApproveSuccess(address indexed _owner, address indexed _spender, uint256 _value);
}
contract Token is ERC20 {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        TransferSuccess(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        TransferFromSuccess(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        ApproveSuccess(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
contract CJXToken is Token {
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'CJX0.1';

    function CJXToken() {
        balances[msg.sender] = 1000000000000000000000000;
        totalSupply = 1000000000000000000000000;
        name = 'CJX COIN';
        decimals = 18;
        symbol = 'CJX';
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        ApproveSuccess(msg.sender, _spender, _value);
        require(_spender.call(bytes4(bytes32(sha3('receiveApproval(address,uint256,address,bytes)'))), msg.sender, _value, this, _extraData));
        return true;
    }
}