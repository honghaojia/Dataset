pragma solidity ^0.4.24;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
contract Ownable {
    address public owner;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
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
contract Crowdsale {
    using SafeMath for uint256;

    ERC20 public token;
    address public wallet;
    uint256 public rate;
    uint256 public weiRaised;
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor(uint256 _rate, address _wallet, ERC20 _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));
        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        uint256 tokens = _getTokenAmount(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        _updatePurchasingState(_beneficiary, weiAmount);
        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate);
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;
    uint256 public openingTime;
    uint256 public closingTime;

    modifier onlyWhileOpen {
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        _;
    }

    constructor(uint256 _openingTime, uint256 _closingTime) public {
        require(_openingTime >= block.timestamp);
        require(_closingTime >= _openingTime);
        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    function hasClosed() public view returns (bool) {
        return block.timestamp > closingTime;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
    using SafeMath for uint256;
    bool public isFinalized = false;
    event Finalized();

    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasClosed());
        finalization();
        emit Finalized();
        isFinalized = true;
    }

    function finalization() internal {
    }
}
contract StageCrowdsale is FinalizableCrowdsale {
    bool public previousStageIsFinalized = false;
    StageCrowdsale public previousStage;

    constructor(
        uint256 _rate,
        address _wallet,
        ERC20 _token,
        uint256 _openingTime,
        uint256 _closingTime,
        StageCrowdsale _previousStage
    )
        public
        Crowdsale(_rate, _wallet, _token)
        TimedCrowdsale(_openingTime, _closingTime)
    {
        previousStage = _previousStage;
        if (_previousStage == address(0)) {
            previousStageIsFinalized = true;
            emit PreviousStageFinalized(previousStageIsFinalized);
        }
    }

    modifier isNotFinalized() {
        require(!isFinalized, 'Call on finalized.');
        _;
    }

    modifier previousIsFinalized() {
        require(isPreviousStageFinalized(), 'Call on previous stage finalized.');
        _;
    }

    event PreviousStageFinalized(bool isFinalized);

    function finalizeStage() public onlyOwner isNotFinalized {
        _finalizeStage();
        emit FinalizedStage();
    }
    
    function proxyBuyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        uint256 tokens = _getTokenAmount(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(tx.origin, _beneficiary, weiAmount, tokens);
        _updatePurchasingState(_beneficiary, weiAmount);
        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    function isPreviousStageFinalized() public returns (bool) {
        if (previousStageIsFinalized) {
            return true;
        }
        if (previousStage.isFinalized()) {
            previousStageIsFinalized = true;
            emit PreviousStageFinalized(previousStageIsFinalized);
        }
        return previousStageIsFinalized;
    }

    function _finalizeStage() internal isNotFinalized {
        finalization();
        emit FinalizedStage();
        isFinalized = true;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isNotFinalized previousIsFinalized {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    event FinalizedStage();
}
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;
    uint256 public cap;

    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
        emit CapSet(_cap);
    }

    event CapSet(uint256 cap);

    function capReached() public view returns (bool) {
        return weiRaised >= cap;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(weiRaised.add(_weiAmount) <= cap);
    }
}
contract CappedStageCrowdsale is CappedCrowdsale, StageCrowdsale {
    using SafeMath for uint256;

    function weiToCap() public view returns (uint256) {
        return cap.sub(weiRaised);
    }

    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._postValidatePurchase(_beneficiary, _weiAmount);
        if (weiRaised >= cap) {
            _finalizeStage();
            emit CapReached();
        }
    }

    event CapReached();
}
contract LimitedMinPurchaseCrowdsale is Crowdsale {
    using SafeMath for uint256;
    uint256 public minPurchase;

    constructor(uint256 _minPurchase) public {
        require(
            _minPurchase > 0,
            'Call with insufficient _minPurchase.'
        );
        minPurchase = _minPurchase;
        emit MinimumPurchaseSet(_minPurchase);
    }

    event MinimumPurchaseSet(uint256 minPurchase);

    modifier overMinPurchaseLimit(uint256 _weiAmount) {
        require(
            _weiAmount >= minPurchase,
            'Call with insufficient _weiAmount.'
        );
        _;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal overMinPurchaseLimit(_weiAmount) {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}
contract TokensSoldCountingCrowdsale is Crowdsale {
    using SafeMath for uint256;
    uint256 public tokensSoldCount;

    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
        uint256 tokens = _getTokenAmount(_weiAmount);
        tokensSoldCount = tokensSoldCount.add(tokens);
        emit TokensSoldUpdated(tokensSoldCount);
    }

    event TokensSoldUpdated(uint256 totalTokensSold);
}
contract ManualTokenDistributionCrowdsale is Crowdsale, Ownable, TokensSoldCountingCrowdsale {
    using SafeMath for uint256;

    event TokenAssignment(address indexed beneficiary, uint256 amount);

    function manualSendTokens(address _beneficiary, uint256 _tokensAmount) public onlyOwner {
        require(_beneficiary != address(0));
        require(_tokensAmount > 0);
        super._deliverTokens(_beneficiary, _tokensAmount);
        tokensSoldCount = tokensSoldCount.add(_tokensAmount);
        emit TokenAssignment(_beneficiary, _tokensAmount);
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
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}
contract PausableCrowdsale is Crowdsale, Pausable {
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
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

    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
        emit Deposited(investor, msg.value);
    }

    event Deposited(address indexed investor, uint256 amount);

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
        wallet.transfer(address(this).balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
}
contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

    uint256 public goal;
    RefundVault public vault;

    constructor(uint256 _goal) public {
        require(_goal > 0);
        vault = new RefundVault(wallet);
        goal = _goal;
    }

    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());
        vault.refund(msg.sender);
    }

    function goalReached() public view returns (bool) {
        return weiRaised >= goal;
    }

    function finalization() internal {
        if (goalReached()) {
            vault.close();
            emit RefundVaultClosed();
        } else {
            vault.enableRefunds();
            emit RefundVaultEnabled();
        }
        super.finalization();
    }

    event RefundVaultClosed();
    event RefundVaultEnabled();

    function _forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }
}
contract RefundableStageCrowdsale is RefundableCrowdsale {
    function _forwardFunds() internal {
        vault.deposit.value(msg.value)(tx.origin);
    }
}
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address addr) internal {
        role.bearer[addr] = true;
    }

    function remove(Role storage role, address addr) internal {
        role.bearer[addr] = false;
    }

    function check(Role storage role, address addr) view internal {
        require(has(role, addr));
    }

    function has(Role storage role, address addr) view internal returns (bool) {
        return role.bearer[addr];
    }
}
contract RBAC {
    using Roles for Roles.Role;
    mapping (string => Roles.Role) private roles;
    event RoleAdded(address addr, string roleName);
    event RoleRemoved(address addr, string roleName);

    function checkRole(address addr, string roleName) view public {
        roles[roleName].check(addr);
    }

    function hasRole(address addr, string roleName) view public returns (bool) {
        return roles[roleName].has(addr);
    }

    function addRole(address addr, string roleName) internal {
        roles[roleName].add(addr);
        emit RoleAdded(addr, roleName);
    }

    function removeRole(address addr, string roleName) internal {
        roles[roleName].remove(addr);
        emit RoleRemoved(addr, roleName);
    }

    modifier onlyRole(string roleName) {
        checkRole(msg.sender, roleName);
        _;
    }
}
contract Whitelist is Ownable, RBAC {
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);
    string public constant ROLE_WHITELISTED = 'whitelist';

    modifier onlyWhitelisted() {
        checkRole(msg.sender, ROLE_WHITELISTED);
        _;
    }

    function addAddressToWhitelist(address addr) onlyOwner public {
        addRole(addr, ROLE_WHITELISTED);
        emit WhitelistedAddressAdded(addr);
    }

    function whitelist(address addr) public view returns (bool) {
        return hasRole(addr, ROLE_WHITELISTED);
    }

    function addAddressesToWhitelist(address[] addrs) onlyOwner public {
        for (uint256 i = 0; i < addrs.length; i++) {
            addAddressToWhitelist(addrs[i]);
        }
    }

    function removeAddressFromWhitelist(address addr) onlyOwner public {
        removeRole(addr, ROLE_WHITELISTED);
        emit WhitelistedAddressRemoved(addr);
    }

    function removeAddressesFromWhitelist(address[] addrs) onlyOwner public {
        for (uint256 i = 0; i < addrs.length; i++) {
            removeAddressFromWhitelist(addrs[i]);
        }
    }
}
contract WhitelistedCrowdsale is Crowdsale, Ownable {
    Whitelist public whitelist;

    constructor(Whitelist _whitelist) public {
        require(_whitelist != address(0));
        whitelist = _whitelist;
    }

    modifier onlyWhitelisted(address _beneficiary) {
        require(whitelist.whitelist(_beneficiary));
        _;
    }

    function isWhitelisted(address _beneficiary) public view returns (bool) {
        return whitelist.whitelist(_beneficiary);
    }

    function changeWhitelist(Whitelist _whitelist) public onlyOwner {
        whitelist = _whitelist;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhitelisted(_beneficiary) {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}
contract BurnableToken is BasicToken {
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}
contract BlockFollowMainStageCrowdsale is StageCrowdsale, CappedStageCrowdsale, LimitedMinPurchaseCrowdsale, ManualTokenDistributionCrowdsale, PausableCrowdsale, RefundableStageCrowdsale, WhitelistedCrowdsale {
    using SafeMath for uint256;
    mapping(address => bool) public claimedBonus;
    uint256 public ratePerEth;
    uint256 public bonusTokensPool;
    uint256 public burnPercentage;
    uint256 public totalTokensSold;
    uint256 purchasableTokenSupply;

    constructor(
        address _wallet,
        ERC20 _token,
        uint256 _openingTime,
        StageCrowdsale _previousStage,
        uint256 _ratePerEth,
        uint256 _minPurchase,
        uint256 _minCap,
        uint256 _maxCap,
        uint256 _burnPercentage,
        uint256 _purchasableTokenSupply,
        Whitelist _whitelist
    )
        public
        CappedCrowdsale(_maxCap)
        LimitedMinPurchaseCrowdsale(_minPurchase)
        StageCrowdsale(_ratePerEth, _wallet, _token, _openingTime, _openingTime + 4 weeks, _previousStage)
        RefundableCrowdsale(_minCap)
        WhitelistedCrowdsale(_whitelist)
    {
        require(_ratePerEth > 0, 'Rate per ETH cannot be null');
        require(_burnPercentage > 0, 'Burn percentage cannot be null');
        require(_purchasableTokenSupply > 0, 'Purchasable token supply cannot be null');
        ratePerEth = _ratePerEth;
        burnPercentage = _burnPercentage;
        purchasableTokenSupply = _purchasableTokenSupply;
    }

    modifier canClaimBonus() {
        require(isFinalized, 'Cannot claim bonus when stage is not yet finalized');
        require(now < openingTime + 6 weeks, 'Cannot claim bonus tokens too soon');
        require(!claimedBonus[msg.sender], 'Cannot claim bonus tokens repeatedly');
        require(totalTokensSold > 0, 'Cannot claim bonus tokens when no purchases have been made');
        _;
    }

    function claimBonusTokens() public canClaimBonus {
        uint256 senderBalance = token.balanceOf(msg.sender);
        uint256 purchasedProportion = senderBalance.mul(1e18).div(totalTokensSold);
        uint256 bonusForSender = bonusTokensPool.mul(purchasedProportion).div(1e18);
        token.transfer(msg.sender, bonusForSender);
        claimedBonus[msg.sender] = true;
        emit BonusClaimed(msg.sender, bonusForSender);
    }

    event BonusClaimed(address indexed beneficiary, uint256 amount);

    function claimRemainingTokens() public onlyOwner {
        uint256 balance = token.balanceOf(this);
        manualSendTokens(msg.sender, balance);
    }

    function finalization() internal {
        super.finalization();
        uint256 balance = token.balanceOf(address(this));
        totalTokensSold = purchasableTokenSupply.sub(balance);
        uint256 balanceToBurn = balance.mul(burnPercentage).div(100);
        BurnableToken(address(token)).burn(balanceToBurn);
        uint256 bonusPercentage = 100 - burnPercentage;
        bonusTokensPool = balance.mul(100).mul(bonusPercentage).div(1e4);
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.div(1e10).mul(ratePerEth);
    }
}