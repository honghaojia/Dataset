contract with `emit` events added after each logical branch, along with the declarations for the corresponding events. I've updated the Solidity version to be compatible with the newer syntax:

```solidity
pragma solidity ^0.6.0; // Updated to a more recent version

contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event TransferSuccess(address indexed _from, address indexed _to, uint256 _value);
    event TransferFailure(address indexed _from, address indexed _to, uint256 _value, string reason);
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        emit TransferSuccess(msg.sender, _to, _value);
        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "Transfer not allowed");
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        emit TransferSuccess(_from, _to, _value);
        
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
contract LolaCoin is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'L0.1';
    uint256 public constant TOTAL = 1000000000000000000000000000;

    event Mint(address indexed to, uint256 amount);
    
    constructor() public {
        balances[msg.sender] = TOTAL;
        totalSupply = TOTAL;
        name = 'Lola Coin';
        decimals = 18;
        symbol = 'LLC';
        
        emit Mint(msg.sender, TOTAL);
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        // Ensuring that this call succeeds
        require(_spender.call(abi.encodeWithSignature("receiveApproval(address,uint256,address,bytes)", msg.sender, _value, address(this), _extraData)), "Call failed");
        
        return true;
    }
}
