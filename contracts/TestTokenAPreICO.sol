pragma solidity ^0.4.15;
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
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
}
contract Crowdsale {
    using SafeMath for uint256;

    address public tokenAddr;
    TestTokenA public testTokenA;

    uint256 public startTime;
    uint256 public endTime;

    address public wallet;
    uint256 public rate;
    uint256 public weiRaised;
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokensBought(address indexed purchaser, address indexed beneficiary, uint256 weiAmount, uint256 tokens);

    function Crowdsale(address _tokenAddress, uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != 0x0);
        require(_tokenAddress != 0x0);
        tokenAddr = _tokenAddress;
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
    }

    function () payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());
        uint256 weiAmount = msg.value;

        uint256 tokens = weiAmount.mul(rate);
        weiRaised = weiRaised.add(weiAmount);
        testTokenA = TestTokenA(tokenAddr);
        testTokenA.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        TokensBought(msg.sender, beneficiary, weiAmount, tokens);
        forwardFunds();
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        emit ValidPurchaseChecked(withinPeriod, nonZeroPurchase);
        return withinPeriod && nonZeroPurchase;
    }

    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }

    event ValidPurchaseChecked(bool withinPeriod, bool nonZeroPurchase);
}
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;
    uint256 public cap;

    function CappedCrowdsale(uint256 _cap) {
        require(_cap > 0);
        cap = _cap;
    }

    function validPurchase() internal constant returns (bool) {
        bool withinCap = weiRaised.add(msg.value) <= cap;
        emit CappedPurchaseChecked(withinCap);
        return super.validPurchase() && withinCap;
    }

    event CappedPurchaseChecked(bool withinCap);

    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= cap;
        emit CapReachedChecked(capReached);
        return super.hasEnded() || capReached;
    }

    event CapReachedChecked(bool capReached);
}
contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;
    bool public isFinalized = false;
    event Finalized();

    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());
        finalization();
        Finalized();
        isFinalized = true;
    }

    function finalization() internal {
        emit FinalizationCalled();
    }

    event FinalizationCalled();
}
contract RefundVault is Ownable {
    using SafeMath for uint256;
    enum State { Active, Refunding, Closed }
    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;
    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function RefundVault(address _wallet) {
        require(_wallet != 0x0);
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }

    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }
}
contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

    uint256 public goal;
    RefundVault public vault;

    function RefundableCrowdsale(uint256 _goal) {
        require(_goal > 0);
        vault = new RefundVault(wallet);
        goal = _goal;
    }

    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());
        vault.refund(msg.sender);
    }

    function finalization() internal {
        if (goalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }
        super.finalization();
        emit FinalizationCompleted();
    }

    function goalReached() public constant returns (bool) {
        return weiRaised >= goal;
    }

    event FinalizationCompleted();
}
contract Destructible is Ownable {
    function Destructible() payable { }

    function destroy() onlyOwner public {
        selfdestruct(owner);
    }

    function destroyAndSend(address _recipient) onlyOwner public {
        selfdestruct(_recipient);
    }
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
        Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        emit BasicTokenTransferred(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    event BasicTokenTransferred(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        uint256 _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        emit StandardTokenTransferred(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        emit ApprovalSet(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseApproval (address _spender, uint _addedValue) returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    event StandardTokenTransferred(address indexed from, address indexed to, uint256 value);
    event ApprovalSet(address indexed owner, address indexed spender, uint256 value);
}
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;
    
    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address _to, uint256 _amount) public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}
contract TestTokenA is MintableToken {
    string public constant name = 'Atom Token';
    string public constant symbol = 'ATT';
    uint8 public constant decimals = 18;
    uint256 public constant initialSupply = 65000000 * (10 ** uint256(decimals));

    function TestTokenA() {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
    }
}
contract TestTokenAPreICO is CappedCrowdsale, RefundableCrowdsale, Destructible, Pausable {
    function TestTokenAPreICO(address _tokenAddress, uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _goal, uint256 _cap, address _wallet) 
        CappedCrowdsale(_cap) 
        FinalizableCrowdsale() 
        RefundableCrowdsale(_goal) 
        Crowdsale(_tokenAddress, _startTime, _endTime, _rate, _wallet) 
    {
        require(_goal <= _cap);
        emit PreICOCreated(_tokenAddress, _startTime, _endTime, _rate, _goal, _cap, _wallet);
    }

    event PreICOCreated(address indexed tokenAddress, uint256 startTime, uint256 endTime, uint256 rate, uint256 goal, uint256 cap, address indexed wallet);
}
