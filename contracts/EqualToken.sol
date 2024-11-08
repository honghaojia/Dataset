pragma solidity ^0.4.13;
contract Token {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event TransferSuccess(address indexed _from, address indexed _to, uint256 _value);
    event TransferFailure(address indexed _from, address indexed _to, uint256 _value);
    event FeeCalculated(uint256 fee);
    event FeeApplied(address indexed _from, uint256 fee);
    event BurnSuccess(address indexed _from, uint256 value);
    event BurnFailure(address indexed _from, uint256 value);
    
    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function onePercent(uint256 a) internal constant returns (uint256) {
        return div(a, uint256(100));
    }
    function power(uint256 a, uint256 b) internal constant returns (uint256) {
        return mul(a, 10**b);
    }
}
contract StandardToken is Token {
    using SafeMath for uint256;
    uint8 public decimals;
    mapping(address => bool) internal withoutFee;
    uint256 internal maxFee;

    function transfer(address _to, uint256 _value) returns (bool success) {
        uint256 fee = getFee(_value);
        if (balances[msg.sender].add(fee) >= _value && _value > 0) {
            doTransfer(msg.sender, _to, _value, fee);
            emit TransferSuccess(msg.sender, _to, _value);
            return true;
        } else {
            emit TransferFailure(msg.sender, _to, _value);
            return false;
        }
    }

    function getFee(uint256 _value) private returns (uint256) {
        uint256 onePercentOfValue = _value.onePercent();
        uint256 fee = uint256(maxFee).power(decimals);
        emit FeeCalculated(fee);
        if (_value.add(onePercentOfValue) >= fee) {
            return fee;
        }
        if (_value.add(onePercentOfValue) < fee) {
            return onePercentOfValue;
        }
    }

    function doTransfer(address _from, address _to, uint256 _value, uint256 fee) internal {
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        if (!withoutFee[_from]) {
            if (doBurn(msg.sender, fee)) {
                emit FeeApplied(_from, fee);
            }
        }
    }

    function doBurn(address _from, uint256 _value) private returns (bool success) {
        require(balanceOf(_from) >= _value);
        balances[_from] = balances[_from].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        Burn(_from, _value);
        emit BurnSuccess(_from, _value);
        return true;
    }

    function burn(address _from, uint256 _value) public returns (bool success) {
        return doBurn(_from, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        uint256 fee = getFee(_value);
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && balances[msg.sender] > fee) {
            doTransfer(_from, _to, _value, getFee(_value));
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value.add(fee));
            Transfer(_from, _to, _value);
            emit TransferSuccess(_from, _to, _value);
            return true;
        } else {
            emit TransferFailure(_from, _to, _value);
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

    function totalSupply() constant returns (uint totalSupply) {
        return _totalSupply;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 public _totalSupply;
}
contract EqualToken is StandardToken {
    function () {
        revert();
    }

    string public name;
    string public symbol;
    string public version = 'H1.0';
    string public feeInfo = 'Each operation costs 1% of the transaction amount, but not more than 250 tokens.';

    function EqualToken() {
        _totalSupply = 800000000000000000000000000;
        balances[msg.sender] = _totalSupply;
        allocate(0x1c1bE8B53Bd8b7Dc9d0CE46C335532A43b414372, 55);
        allocate(0x55819E6F3C4E72ed63c7C465d4FA6C4dd7681cA9, 20);
        allocate(0x92Ab7CaB1fD2a4581350a94Acf0e5594319db6Ee, 20);
        allocate(0xE165aadFD17CfF20357A301785B968b4FeB9B8b7, 5);
        maxFee = 250;
        name = 'Equal Token';
        decimals = 18;
        symbol = 'EQL';
    }

    function allocate(address _address, uint256 percent) private {
        uint256 bal = _totalSupply.onePercent().mul(percent);
        withoutFee[_address] = true;
        doTransfer(msg.sender, _address, bal, 0);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if (!_spender.call(bytes4(bytes32(sha3('receiveApproval(address,uint256,address,bytes)'))), msg.sender, _value, this, _extraData)) {
            revert();
        }
        return true;
    }
}
