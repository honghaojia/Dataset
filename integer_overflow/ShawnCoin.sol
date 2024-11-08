pragma solidity ^0.4.24;
contract ERC20Basic {  
    function totalSupply() public view returns (uint256);  
    function balanceOf(address _who) public view returns (uint256);  
    function transfer(address _to, uint256 _value) public returns (bool);  
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {  
    function allowance(address _owner, address _spender) public view returns (uint256);  
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);  
    function approve(address _spender, uint256 _value) public returns (bool);  
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract DetailedERC20 is ERC20 {  
    string public name;  
    string public symbol;  
    uint8 public decimals;  
    
    constructor(string _name, string _symbol, uint8 _decimals) public {    
        name = _name;    
        symbol = _symbol;    
        decimals = _decimals;  
    }
}
library SafeMath {    
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {                
        if (_a == 0) {      
            return 0;    
        }    
        c = _a * _b;    
        assert(c / _a == _b);    
        return c;  
    }    
    
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {                
        return _a / _b;  
    }    
    
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {    
        assert(_b <= _a);    
        return _a - _b;  
    }    
    
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {    
        c = _a + _b;    
        assert(c >= _a);    
        return c;  
    }
}
contract BasicToken is ERC20Basic {  
    using SafeMath for uint256;  
    mapping(address => uint256) internal balances;  
    uint256 internal totalSupply_;    

    function totalSupply() public view returns (uint256) {    
        return totalSupply_;  
    }    

    function transfer(address _to, uint256 _value) public returns (bool) {    
        require(_value <= balances[msg.sender]);    
        require(_to != address(0));    
        balances[msg.sender] = balances[msg.sender].sub(_value);    
        balances[_to] = balances[_to].add(_value);    
        emit Transfer(msg.sender, _to, _value);    
        emit TransferSuccess(msg.sender, _to, _value);
        return true;  
    }    

    function balanceOf(address _owner) public view returns (uint256) {    
        return balances[_owner];  
    }

    event TransferSuccess(address indexed from, address indexed to, uint256 value);
}
contract StandardToken is ERC20, BasicToken {  
    mapping (address => mapping (address => uint256)) internal allowed;    

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {    
        require(_value <= balances[_from]);    
        require(_value <= allowed[_from][msg.sender]);    
        require(_to != address(0));    
        balances[_from] = balances[_from].sub(_value);    
        balances[_to] = balances[_to].add(_value);    
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);    
        emit Transfer(_from, _to, _value);    
        emit TransferFromSuccess(_from, _to, _value);
        return true;  
    }    

    function approve(address _spender, uint256 _value) public returns (bool) {    
        allowed[msg.sender][_spender] = _value;    
        emit Approval(msg.sender, _spender, _value);    
        emit ApprovalSuccess(msg.sender, _spender, _value);
        return true;  
    }    

    function allowance(address _owner, address _spender) public view returns (uint256) {    
        return allowed[_owner][_spender];  
    }    

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {    
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));    
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);    
        emit IncreaseApprovalSuccess(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;  
    }    

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {    
        uint256 oldValue = allowed[msg.sender][_spender];    
        if (_subtractedValue >= oldValue) {      
            allowed[msg.sender][_spender] = 0;    
            emit DecreaseApprovalSuccess(msg.sender, _spender, 0);
        } else {      
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);    
            emit DecreaseApprovalSuccess(msg.sender, _spender, allowed[msg.sender][_spender]);
        }    
        return true;  
    }

    event TransferFromSuccess(address indexed from, address indexed to, uint256 value);
    event ApprovalSuccess(address indexed owner, address indexed spender, uint256 value);
    event IncreaseApprovalSuccess(address indexed owner, address indexed spender, uint256 value);
    event DecreaseApprovalSuccess(address indexed owner, address indexed spender, uint256 value);
}
contract ShawnCoin is DetailedERC20, StandardToken {    
    constructor() public DetailedERC20('Shawn Coin', 'SHAWN', 18) {    
        totalSupply_ = 1000000000000000000000000000;     
        balances[msg.sender] = totalSupply_;  
        emit TokenCreated(msg.sender, totalSupply_);  
    }
    
    event TokenCreated(address indexed creator, uint256 totalSupply);
}
