pragma solidity ^0.4.8;
contract ABTokenBase {
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract ABStandardToken is ABTokenBase {
    uint256 constant MAX_UINT256 = 2**256 - 1;

    event TransferExecuted(address indexed _from, address indexed _to, uint256 _value);
    event TransferFromExecuted(address indexed _from, address indexed _to, uint256 _value);
    event ApprovalExecuted(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) public returns (bool success) {                                        
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        emit TransferExecuted(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {                        
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
            emit TransferFromExecuted(_from, _to, _value);
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        emit ApprovalExecuted(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}
contract ABToken is ABStandardToken {
    string public name;                       
    uint8 public decimals;                    
    string public symbol;                     
    string public version = 'H0.1.1';

    event TokenCreated(address indexed creator, uint256 totalSupply);

    function ABToken() public {
        totalSupply = 990000000;
        balances[msg.sender] = totalSupply; 
        decimals = 4;                                
        name = 'Pablo Token';
        symbol = 'PAB';
        emit TokenCreated(msg.sender, totalSupply);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        emit ApprovalExecuted(msg.sender, _spender, _value);
        require(_spender.call(bytes4(bytes32(keccak256('receiveApproval(address,uint256,address,bytes)'))), msg.sender, _value, this, _extraData));
        return true;
    }
}
