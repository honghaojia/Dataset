pragma solidity ^0.4.4;
contract SafeMath {
    event SafeMulExecuted(uint a, uint b, uint result);
    event SafeDivExecuted(uint a, uint b, uint result);
    event SafeSubExecuted(uint a, uint b, uint result);
    event SafeAddExecuted(uint a, uint b, uint result);
    event AssertFailed(bool assertion);

    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        emit SafeMulExecuted(a, b, c);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        emit SafeDivExecuted(a, b, c);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        uint result = a - b;
        emit SafeSubExecuted(a, b, result);
        return result;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        emit SafeAddExecuted(a, b, c);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            emit AssertFailed(assertion);
            throw;
        }
    }
}
contract Token is SafeMath {
    event TotalSupplyRetrieved(uint256 supply);
    event BalanceRetrieved(address indexed _owner, uint256 balance);
    event TransferOccurred(address indexed _from, address indexed _to, uint256 _value);
    event ApprovalOccurred(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() constant returns (uint256 supply) {
        emit TotalSupplyRetrieved(supply);
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        emit BalanceRetrieved(_owner, balance);
    }

    function transfer(address _to, uint256 _value) returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    function approve(address _spender, uint256 _value) returns (bool success) {}

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            emit TransferOccurred(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            emit TransferOccurred(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit ApprovalOccurred(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply = 4500000 * 10 ** 12;
    uint256 public initialSupply = 2500000 * 10 ** 12;
}
contract HawalaToken is StandardToken {
    event FallbackCalled();

    function () {
        emit FallbackCalled();
        throw;
    }

    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'HAT';

    function HawalaToken() {
        totalSupply += initialSupply;
        balances[msg.sender] = initialSupply;
        name = 'HawalaToken';
        decimals = 12;
        symbol = 'HAT';
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit ApprovalOccurred(msg.sender, _spender, _value);
        if (!_spender.call(bytes4(bytes32(sha3('receiveApproval(address,uint256,address,bytes)'))), msg.sender, _value, this, _extraData)) {
            throw;
        }
        return true;
    }
}
