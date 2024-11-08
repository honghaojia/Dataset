pragma solidity ^0.4.11;
library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint a, uint b) internal returns (uint) {
        uint c = a / b;
        return c;
    }
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
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
        require(assertion);
    }
}
contract Token {
    uint256 public totalSupply;

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
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
contract ERC223Basic is StandardToken {
    uint public totalSupply;

    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
contract ERC223BasicToken is ERC223Basic {
    using SafeMath for uint;
    
    mapping(address => uint) balances;

    function transfer(address to, uint value, bytes data) {
        uint codeLength;
        assembly {
            codeLength := extcodesize(to)
        }
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        
        if(codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
            receiver.tokenFallback(msg.sender, value, data);
            emit Transfer(msg.sender, to, value, data);
        } else {
            emit Transfer(msg.sender, to, value, data);
        }
    }

    function transfer(address to, uint value) {
        uint codeLength;
        bytes memory empty;
        assembly {
            codeLength := extcodesize(to)
        }
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        
        if(codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
            receiver.tokenFallback(msg.sender, value, empty);
            emit Transfer(msg.sender, to, value, empty);
        } else {
            emit Transfer(msg.sender, to, value, empty);
        }
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
}
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data);
}
contract HumanERC223Token is ERC223BasicToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'H0.1';

    function HumanERC223Token (
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
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        require(_spender.call(bytes4(bytes32(sha3('receiveApproval(address,uint256,address,bytes)'))), msg.sender, _value, this, _extraData));
        return true;
    }
}
contract HedgeminerToken is HumanERC223Token(20000000000000000000000000, 'Hedgeminer Token', 18, 'HMT') {}
