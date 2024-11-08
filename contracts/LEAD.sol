pragma solidity ^0.4.24;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;
    
    modifier onlyPayloadSize(uint256 numwords) {
        assert(msg.data.length >= numwords * 32 + 4);
        _;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        emit TransferCompleted(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    event TransferCompleted(address indexed from, address indexed to, uint256 value);
}
contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        
        emit Transfer(_from, _to, _value);
        emit TransferFromCompleted(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        emit ApproveCompleted(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) onlyPayloadSize(2) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        emit IncreaseApprovalCompleted(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) onlyPayloadSize(2) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        emit DecreaseApprovalCompleted(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    event TransferFromCompleted(address indexed from, address indexed to, uint256 value);
    event ApproveCompleted(address indexed owner, address indexed spender, uint256 value);
    event IncreaseApprovalCompleted(address indexed owner, address indexed spender, uint256 newValue);
    event DecreaseApprovalCompleted(address indexed owner, address indexed spender, uint256 newValue);
}
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        emit OwnershipTransferredCompleted(owner, newOwner);
    }
    
    event OwnershipTransferredCompleted(address indexed previousOwner, address indexed newOwner);
}
contract Pausable is Ownable {
    event Pause();
    event Unpause();
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
        emit PausedCompleted();
    }
    
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
        emit UnpausedCompleted();
    }
    
    event PausedCompleted();
    event UnpausedCompleted();
}
contract PausableToken is StandardToken, Pausable {
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }
    
    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}
contract Claimable is Ownable {
    address public pendingOwner;
    
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
        emit PendingOwnershipTransferred(owner, pendingOwner);
    }
    
    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnershipClaimed(owner);
    }
    
    event PendingOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipClaimed(address indexed newOwner);
}
contract MintableToken is PausableToken {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;
    
    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    
    address public saleAgent = address(0);
    address public saleAgent2 = address(0);
    
    function setSaleAgent(address newSaleAgent) onlyOwner public {
        saleAgent = newSaleAgent;
        emit SaleAgentSet(newSaleAgent);
    }
    
    function setSaleAgent2(address newSaleAgent) onlyOwner public {
        saleAgent2 = newSaleAgent;
        emit SaleAgent2Set(newSaleAgent);
    }
    
    function mint(address _to, uint256 _amount) canMint public returns (bool) {
        require(msg.sender == saleAgent || msg.sender == saleAgent2 || msg.sender == owner);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(this), _to, _amount);
        emit MintCompleted(_to, _amount);
        return true;
    }
    
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        emit MintingFinished();
        return true;
    }
    
    event SaleAgentSet(address indexed newSaleAgent);
    event SaleAgent2Set(address indexed newSaleAgent);
    event MintCompleted(address indexed to, uint256 amount);
    event MintingFinished();
}
contract LEAD is MintableToken, Claimable {
    string public constant name = 'LEADEX';
    string public constant symbol = 'LEAD';
    uint public constant decimals = 8;
}
