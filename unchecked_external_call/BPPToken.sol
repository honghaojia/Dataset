pragma solidity ^0.4.24;
contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event SuccessfulTransfer(address indexed _from, address indexed _to, uint256 _value);
    event FailedTransfer(address indexed _from, address indexed _to, uint256 _value);
    event SuccessfulTransferFrom(address indexed _from, address indexed _to, uint256 _value);
    event FailedTransferFrom(address indexed _from, address indexed _to, uint256 _value);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            emit SuccessfulTransfer(msg.sender, _to, _value);
            return true;
        } else {
            emit FailedTransfer(msg.sender, _to, _value);
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            emit SuccessfulTransferFrom(_from, _to, _value);
            return true;
        } else {
            emit FailedTransferFrom(_from, _to, _value);
            return false;
        }
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
contract BPPToken is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = '1.0';

    constructor() public {
        name = 'Bpp';
        decimals = 18;
        symbol = 'BPP';
        totalSupply = 21000000000 * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }

    event ReceiveApproval(address indexed _spender, uint256 _value, bytes _extraData);

    function () public {
        revert();
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        emit ReceiveApproval(_spender, _value, _extraData);
        if(!_spender.call(bytes4(bytes32(keccak256('receiveApproval(address,uint256,address,bytes)'))), msg.sender, _value, this, _extraData)) { 
            revert(); 
        }
        return true;
    }
}
