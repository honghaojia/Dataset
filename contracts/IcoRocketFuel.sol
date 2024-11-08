pragma solidity ^0.4.24;
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
library SafeMath {
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        require(c / _a == _b);
        return c;
    }
    
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);
        uint256 c = _a / _b;
        return c;
    }
    
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;
        return c;
    }
    
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
contract Ownable {
    address public owner;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
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
contract IcoRocketFuel is Ownable {
    using SafeMath for uint256;
    
    enum States {Active, Refunding, Closed}
    struct Crowdsale {
        address owner;
        address refundWallet;
        uint256 cap;
        uint256 goal;
        uint256 raised;
        uint256 rate;
        uint256 minInvest;
        uint256 closingTime;
        bool earlyClosure;
        uint8 commission;
        States state;
    }
    
    address public commissionWallet;
    
    mapping(address => Crowdsale) public crowdsales;
    mapping (address => mapping(address => uint256)) public deposits;
    
    modifier onlyCrowdsaleOwner(address _token) {
        require(msg.sender == crowdsales[_token].owner, 'Failed to call function due to permission denied.');
        _;
    }
    
    modifier inState(address _token, States _state) {
        require(crowdsales[_token].state == _state, 'Failed to call function due to crowdsale is not in right state.');
        _;
    }
    
    modifier nonZeroAddress(address _token) {
        require(_token != address(0), 'Failed to call function due to address is 0x0.');
        _;
    }
    
    event CommissionWalletUpdated(
        address indexed _previoudWallet,
        address indexed _newWallet
    );
    event CrowdsaleCreated(
        address indexed _owner,
        address indexed _token,
        address _refundWallet,
        uint256 _cap,
        uint256 _goal,
        uint256 _rate,
        uint256 closingTime,
        bool earlyClosure,
        uint8 _commission
    );
    event TokenBought(
        address indexed _buyer,
        address indexed _token,
        uint256 _value
    );
    event CrowdsaleClosed(
        address indexed _setter,
        address indexed _token
    );
    event SurplusTokensRefunded(
        address _token,
        address _beneficiary,
        uint256 _surplus
    );
    event CommissionPaid(
        address indexed _payer,
        address indexed _token,
        address indexed _beneficiary,
        uint256 _value
    );
    event RefundsEnabled(
        address indexed _setter,
        address indexed _token
    );
    event CrowdsaleTokensRefunded(
        address indexed _token,
        address indexed _refundWallet,
        uint256 _value
    );
    event RaisedWeiClaimed(
        address indexed _beneficiary,
        address indexed _token,
        uint256 _value
    );
    event TokenClaimed(
        address indexed _beneficiary,
        address indexed _token,
        uint256 _value
    );
    event CrowdsalePaused(
        address indexed _owner,
        address indexed _token
    );
    event WeiRefunded(
        address indexed _beneficiary,
        address indexed _token,
        uint256 _value
    );

    function setCommissionWallet(
        address _newWallet
    )
        external
        onlyOwner
        nonZeroAddress(_newWallet)
    {
        emit CommissionWalletUpdated(commissionWallet, _newWallet);
        commissionWallet = _newWallet;
    }

    function createCrowdsale(
        address _token,
        address _refundWallet,
        uint256 _cap,
        uint256 _goal,
        uint256 _rate,
        uint256 _minInvest,
        uint256 _closingTime,
        bool _earlyClosure,
        uint8 _commission
    )
        external
        nonZeroAddress(_token)
        nonZeroAddress(_refundWallet)
    {
        require(crowdsales[_token].owner == address(0), 'Failed to create crowdsale due to the crowdsale is existed.');
        emit CrowdsaleCreated(msg.sender, _token, _refundWallet, _cap, _goal, _rate, _closingTime, _earlyClosure, _commission);
        require(_goal <= _cap, 'Failed to create crowdsale due to goal is larger than cap.');
        require(_minInvest > 0, 'Failed to create crowdsale due to minimum investment is 0.');
        require(_commission <= 100, 'Failed to create crowdsale due to commission is larger than 100.');
        
        _cap.mul(_rate);
        crowdsales[_token] = Crowdsale({
            owner: msg.sender,
            refundWallet: _refundWallet,
            cap: _cap,
            goal: _goal,
            raised: 0,
            rate: _rate,
            minInvest: _minInvest,
            closingTime: _closingTime,
            earlyClosure: _earlyClosure,
            state: States.Active,
            commission: _commission
        });
    }

    function buyToken(
        address _token
    )
        external
        inState(_token, States.Active)
        nonZeroAddress(_token)
        payable
    {
        require(msg.value >= crowdsales[_token].minInvest, 'Failed to buy token due to less than minimum investment.');
        emit TokenBought(msg.sender, _token, msg.value);
        require(crowdsales[_token].raised.add(msg.value) <= (crowdsales[_token].cap), 'Failed to buy token due to exceed cap.');
        require(block.timestamp < crowdsales[_token].closingTime, 'Failed to buy token due to crowdsale is closed.');

        deposits[msg.sender][_token] = (deposits[msg.sender][_token].add(msg.value));
        crowdsales[_token].raised = crowdsales[_token].raised.add(msg.value);
    }

    function _goalReached(
        ERC20 _token
    )
        private
        nonZeroAddress(_token)
        view
        returns(bool)
    {
        return (crowdsales[_token].raised >= crowdsales[_token].goal) && (    
            _token.balanceOf(address(this)) >=
            crowdsales[_token].raised.mul(crowdsales[_token].rate)
        );
    }

    function _refundSurplusTokens(
        ERC20 _token,
        address _beneficiary
    )
        private
        nonZeroAddress(_token)
        inState(_token, States.Closed)
    {
        uint256 _balance = _token.balanceOf(address(this));
        uint256 _surplus = _balance.sub(crowdsales[_token].raised.mul(crowdsales[_token].rate));
        emit SurplusTokensRefunded(_token, _beneficiary, _surplus);
        if (_surplus > 0) {
            _token.transfer(_beneficiary, _surplus);
            emit SurplusTokensRefunded(_token, _beneficiary, _surplus);
        }
    }

    function _payCommission(
        address _token
    )
        private
        nonZeroAddress(_token)
        inState(_token, States.Closed)
        onlyCrowdsaleOwner(_token)
    {
        uint256 _commission = crowdsales[_token].raised
            .mul(uint256(crowdsales[_token].commission))
            .div(100);
        crowdsales[_token].raised = crowdsales[_token].raised.sub(_commission);
        emit CommissionPaid(msg.sender, _token, commissionWallet, _commission);
        commissionWallet.transfer(_commission);
    }

    function _refundCrowdsaleTokens(
        ERC20 _token,
        address _beneficiary
    )
        private
        nonZeroAddress(_token)
        inState(_token, States.Refunding)
    {
        crowdsales[_token].raised = 0;
        uint256 _value = _token.balanceOf(address(this));
        emit CrowdsaleTokensRefunded(_token, _beneficiary, _value);
        if (_value > 0) {
            _token.transfer(_beneficiary, _token.balanceOf(address(this)));
            emit CrowdsaleTokensRefunded(_token, _beneficiary, _value);
        }
    }

    function _enableRefunds(
        address _token
    )
        private
        nonZeroAddress(_token)
        inState(_token, States.Active)
    {
        crowdsales[_token].state = States.Refunding;
        emit RefundsEnabled(msg.sender, _token);
    }

    function finalize(
        address _token
    )
        external
        nonZeroAddress(_token)
        inState(_token, States.Active)
        onlyCrowdsaleOwner(_token)
    {
        require(crowdsales[_token].earlyClosure || (block.timestamp >= crowdsales[_token].closingTime), 'Failed to finalize due to crowdsale is opening.');
        if (_goalReached(ERC20(_token))) {
            crowdsales[_token].state = States.Closed;
            emit CrowdsaleClosed(msg.sender, _token);
            _refundSurplusTokens(ERC20(_token), crowdsales[_token].refundWallet);
            _payCommission(_token);
        } else {
            _enableRefunds(_token);
            _refundCrowdsaleTokens(ERC20(_token), crowdsales[_token].refundWallet);
        }
    }

    function pauseCrowdsale(
        address _token
    )
        external
        nonZeroAddress(_token)
        onlyOwner
        inState(_token, States.Active)
    {
        emit CrowdsalePaused(msg.sender, _token);
        _enableRefunds(_token);
        _refundCrowdsaleTokens(ERC20(_token), crowdsales[_token].refundWallet);
    }

    function claimRaisedWei(
        address _token,
        address _beneficiary
    )
        external
        nonZeroAddress(_token)
        nonZeroAddress(_beneficiary)
        inState(_token, States.Closed)
        onlyCrowdsaleOwner(_token)
    {
        require(crowdsales[_token].raised > 0, 'Failed to claim raised Wei due to raised Wei is 0.');
        uint256 _raisedWei = crowdsales[_token].raised;
        crowdsales[_token].raised = 0;
        emit RaisedWeiClaimed(msg.sender, _token, _raisedWei);
        _beneficiary.transfer(_raisedWei);
    }

    function claimToken(
        address _token
    )
        external
        nonZeroAddress(_token)
        inState(_token, States.Closed)
    {
        require(deposits[msg.sender][_token] > 0, 'Failed to claim token due to deposit is 0.');
        uint256 _value = (deposits[msg.sender][_token].mul(crowdsales[_token].rate));
        deposits[msg.sender][_token] = 0;
        emit TokenClaimed(msg.sender, _token, _value);
        ERC20(_token).transfer(msg.sender, _value);
    }

    function claimRefund(
        address _token
    )
        public
        nonZeroAddress(_token)
        inState(_token, States.Refunding)
    {
        require(deposits[msg.sender][_token] > 0, 'Failed to claim refund due to deposit is 0.');
        uint256 _value = deposits[msg.sender][_token];
        deposits[msg.sender][_token] = 0;
        emit WeiRefunded(msg.sender, _token, _value);
        msg.sender.transfer(_value);
    }
}