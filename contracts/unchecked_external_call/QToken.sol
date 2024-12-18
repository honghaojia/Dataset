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
    uint256 constant MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;

        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            Transfer(_from, _to, _value);
            return true;
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
contract HumanStandardToken is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'H0.1';

    function HumanStandardToken(
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
contract QToken is HumanStandardToken {
    mapping (address => bool) authorisers;
    address creator;
    bool canPay = true;

    event Authorise(bytes16 _message, address indexed _actioner, address indexed _actionee);

    function QToken() HumanStandardToken(0, 'Q', 18, 'QTQ') public {
        creator = msg.sender;
    }

    modifier ifCreator() {
        if (creator != msg.sender) {
            revert();
        }
        _;
    }

    modifier ifAuthorised() {
        if (authorisers[msg.sender] || creator == msg.sender) {
            _;
        } else {
            revert();
        }
    }

    modifier ifCanPay() {
        if (!canPay) {
            revert();
        }
        _;
    }

    function authorise(address _address) public ifAuthorised {
        authorisers[_address] = true;
        Authorise('Added', msg.sender, _address);
    }

    function unauthorise(address _address) public ifAuthorised {
        delete authorisers[_address];
        Authorise('Removed', msg.sender, _address);
    }

    function replaceAuthorised(address _toReplace, address _new) public ifAuthorised {
        delete authorisers[_toReplace];
        Authorise('Removed', msg.sender, _toReplace);
        authorisers[_new] = true;
        Authorise('Added', msg.sender, _new);
    }

    function isAuthorised(address _address) public constant returns (bool) {
        return authorisers[_address] || (creator == _address);
    }

    function pay(address _address, uint256 _value) public ifCanPay ifAuthorised {
        balances[_address] += _value;
        totalSupply += _value;
        Transfer(address(this), _address, _value);
    }

    function killPay() public ifCreator {
        canPay = false;
    }
}
