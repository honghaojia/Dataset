pragma solidity ^0.4.24;
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}
contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}
contract token is StandardToken {
    address public owner;
    string public name = 'Black Hole Coin';
    string public symbol = 'BLOC';
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000000;

    mapping(address => bool) public frozenAccount;
    mapping(address => uint256) public frozenTimestamp;
    bool public exchangeFlag = true;

    uint256 public minWei = 1;
    uint256 public maxWei = 2000000000000000000;
    uint256 public maxRaiseAmount = 20000000000000000000;
    uint256 public raisedAmount = 0;
    uint256 public raiseRatio = 20000000;

    event Refund(address indexed sender, uint256 value);
    event ExchangeSuccessful(address indexed buyer, uint256 value);
    event ExchangeFailure(address indexed buyer, uint256 value);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event TokensGenerated(address indexed target, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);
    event AccountFrozen(address indexed target, bool frozen);

    constructor() public {
        totalSupply_ = totalSupply;
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function() public payable {
        require(msg.value > 0);
        if (exchangeFlag) {
            if (msg.value >= minWei && msg.value <= maxWei) {
                if (raisedAmount < maxRaiseAmount) {
                    uint256 valueNeed = msg.value;
                    raisedAmount = raisedAmount.add(msg.value);
                    if (raisedAmount > maxRaiseAmount) {
                        uint256 valueLeft = raisedAmount.sub(maxRaiseAmount);
                        valueNeed = msg.value.sub(valueLeft);
                        msg.sender.transfer(valueLeft);
                        raisedAmount = maxRaiseAmount;
                        emit Refund(msg.sender, valueLeft);
                    }
                    if (raisedAmount >= maxRaiseAmount) {
                        exchangeFlag = false;
                    }
                    
                    uint256 _value = valueNeed.mul(raiseRatio);
                    require(_value <= balances[owner]);
                    balances[owner] = balances[owner].sub(_value);
                    balances[msg.sender] = balances[msg.sender].add(_value);
                    emit Transfer(owner, msg.sender, _value);
                    emit ExchangeSuccessful(msg.sender, _value);
                }
            } else {
                msg.sender.transfer(msg.value);
                emit Refund(msg.sender, msg.value);
            }
        } else {
            msg.sender.transfer(msg.value);
            emit Refund(msg.sender, msg.value);
        }
    }

    function changeowner(address _newowner) public returns (bool) {
        require(msg.sender == owner);
        require(_newowner != address(0));
        emit OwnerChanged(owner, _newowner);
        owner = _newowner;
        return true;
    }

    function generateToken(address _target, uint256 _amount) public returns (bool) {
        require(msg.sender == owner);
        require(_target != address(0));
        balances[_target] = balances[_target].add(_amount);
        totalSupply_ = totalSupply_.add(_amount);
        totalSupply = totalSupply_;
        emit TokensGenerated(_target, _amount);
        return true;
    }

    function withdraw(uint256 _amount) public returns (bool) {
        require(msg.sender == owner);
        msg.sender.transfer(_amount);
        emit Withdrawn(owner, _amount);
        return true;
    }

    function freeze(address _target, bool _freeze) public returns (bool) {
        require(msg.sender == owner);
        require(_target != address(0));
        frozenAccount[_target] = _freeze;
        emit AccountFrozen(_target, _freeze);
        return true;
    }

    function freezeWithTimestamp(address _target, uint256 _timestamp) public returns (bool) {
        require(msg.sender == owner);
        require(_target != address(0));
        frozenTimestamp[_target] = _timestamp;
        return true;
    }

    function multiFreeze(address[] _targets, bool[] _freezes) public returns (bool) {
        require(msg.sender == owner);
        require(_targets.length == _freezes.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i = i.add(1)) {
            address _target = _targets[i];
            require(_target != address(0));
            bool _freeze = _freezes[i];
            frozenAccount[_target] = _freeze;
            emit AccountFrozen(_target, _freeze);
        }
        return true;
    }

    function multiFreezeWithTimestamp(address[] _targets, uint256[] _timestamps) public returns (bool) {
        require(msg.sender == owner);
        require(_targets.length == _timestamps.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i = i.add(1)) {
            address _target = _targets[i];
            require(_target != address(0));
            uint256 _timestamp = _timestamps[i];
            frozenTimestamp[_target] = _timestamp;
        }
        return true;
    }

    function multiTransfer(address[] _tos, uint256[] _values) public returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require(_tos.length == _values.length);
        uint256 len = _tos.length;
        require(len > 0);
        uint256 amount = 0;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            amount = amount.add(_values[i]);
        }
        require(amount <= balances[msg.sender]);
        for (uint256 j = 0; j < len; j = j.add(1)) {
            address _to = _tos[j];
            require(_to != address(0));
            balances[_to] = balances[_to].add(_values[j]);
            balances[msg.sender] = balances[msg.sender].sub(_values[j]);
            emit Transfer(msg.sender, _to, _values[j]);
        }
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!frozenAccount[_from]);
        require(now > frozenTimestamp[msg.sender]);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function getFrozenTimestamp(address _target) public view returns (uint256) {
        require(_target != address(0));
        return frozenTimestamp[_target];
    }

    function getFrozenAccount(address _target) public view returns (bool) {
        require(_target != address(0));
        return frozenAccount[_target];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setName(string _value) public returns (bool) {
        require(msg.sender == owner);
        name = _value;
        return true;
    }

    function setSymbol(string _value) public returns (bool) {
        require(msg.sender == owner);
        symbol = _value;
        return true;
    }

    function setExchangeFlag(bool _flag) public returns (bool) {
        require(msg.sender == owner);
        exchangeFlag = _flag;
        return true;
    }

    function setMinWei(uint256 _value) public returns (bool) {
        require(msg.sender == owner);
        minWei = _value;
        return true;
    }

    function setMaxWei(uint256 _value) public returns (bool) {
        require(msg.sender == owner);
        maxWei = _value;
        return true;
    }

    function setMaxRaiseAmount(uint256 _value) public returns (bool) {
        require(msg.sender == owner);
        maxRaiseAmount = _value;
        return true;
    }

    function setRaisedAmount(uint256 _value) public returns (bool) {
        require(msg.sender == owner);
        raisedAmount = _value;
        return true;
    }

    function setRaiseRatio(uint256 _value) public returns (bool) {
        require(msg.sender == owner);
        raiseRatio = _value;
        return true;
    }

    function kill() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}
