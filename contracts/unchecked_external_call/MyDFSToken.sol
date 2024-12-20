pragma solidity ^0.4.18;
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }
    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }
    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
contract ERC223 {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    function totalSupply() public view returns (uint256 _supply);
    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
    
    event Transfer(address indexed from, address indexed to, uint value);
}
contract ContractReceiver {
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);
    }
}
contract StandardToken is ERC223 {
    using SafeMath for uint;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    event TransferToContract(address indexed from, address indexed to, uint value);
    event TransferToAddress(address indexed from, address indexed to, uint value);

    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
        if (isContract(_to)) {
            if (balanceOf(msg.sender) < _value) revert();
            balances[msg.sender] = balanceOf(msg.sender).sub(_value);
            balances[_to] = balanceOf(_to).add(_value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            Transfer(msg.sender, _to, _value);
            emit TransferToContract(msg.sender, _to, _value);
            return true;
        } else {
            emit TransferToAddress(msg.sender, _to, _value);
            return transferToAddress(_to, _value);
        }
    }

    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            emit TransferToAddress(msg.sender, _to, _value);
            return transferToAddress(_to, _value);
        }
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            emit TransferToAddress(msg.sender, _to, _value);
            return transferToAddress(_to, _value);
        }
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    function transferToAddress(address _to, uint _value) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        Transfer(msg.sender, _to, _value);
        emit TransferToAddress(msg.sender, _to, _value);
        return true;
    }

    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        emit TransferToContract(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) public returns (bool) {
        if (balanceOf(_from) < _value && allowance(_from, msg.sender) < _value) revert();
        bytes memory empty;
        balances[_to] = balanceOf(_to).add(_value);
        balances[_from] = balanceOf(_from).sub(_value);
        allowed[_from][msg.sender] = allowance(_from, msg.sender).sub(_value);
        if (isContract(_to)) {
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function increaseApproval(
        address spender,
        uint value
    ) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(value);
        return true;
    }

    function decreaseApproval(
        address spender,
        uint value
    ) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(value);
        return true;
    }

    function balanceOf(
        address owner
    ) public constant returns (uint) {
        return balances[owner];
    }

    function allowance(
        address owner,
        address spender
    ) public constant returns (uint remaining) {
        return allowed[owner][spender];
    }
}
contract MyDFSToken is StandardToken {
    string public name = 'MyDFS Token';
    uint8 public decimals = 6;
    string public symbol = 'MyDFS';
    string public version = 'H1.0';
    uint256 public totalSupply;

    function () external {
        revert();
    }

    function MyDFSToken() public {
        totalSupply = 125 * 1e12;
        balances[msg.sender] = totalSupply;
    }

    function name() public view returns (string _name) {
        return name;
    }

    function symbol() public view returns (string _symbol) {
        return symbol;
    }

    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }
}
