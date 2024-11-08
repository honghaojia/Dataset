pragma solidity ^0.4.4;
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
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event SuccessfulTransfer(address indexed _from, address indexed _to, uint256 _value);
    event FailedTransfer(address indexed _from, address indexed _to, uint256 _value);

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            emit SuccessfulTransfer(msg.sender, _to, _value);
            return true;
        } else {
            emit FailedTransfer(msg.sender, _to, _value);
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            emit SuccessfulTransfer(_from, _to, _value);
            return true;
        } else {
            emit FailedTransfer(_from, _to, _value);
            return false;
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
}
contract CampaignToken is HumanStandardToken {
    address public tokenController;

    modifier onlyController {
        if (msg.sender != tokenController) throw;
        _;
    }

    event TokenCreated(address beneficiary, uint amount);
    event TokenSealed();

    function CampaignToken() HumanStandardToken(0, 'CharityDAO Token', 18, 'GIVE') {
        tokenController = msg.sender;
    }

    function createTokens(address beneficiary, uint amount) onlyController returns (bool success) {
        if (sealed()) throw;
        balances[beneficiary] += amount;
        totalSupply += amount;
        Transfer(0, beneficiary, amount);
        emit TokenCreated(beneficiary, amount);
        return true;
    }

    function seal() onlyController returns (bool success) {
        tokenController = 0;
        emit TokenSealed();
        return true;
    }

    function sealed() constant returns (bool) {
        return tokenController == 0;
    }
}
contract Campaign {
    uint public startFundingTime;
    uint public endFundingTime;
    uint public maximumFunding;
    uint public totalCollected;
    CampaignToken public tokenContract;
    address public vaultContract;

    event CampaignLaunched(uint _startFundingTime, uint _endFundingTime, uint _maximumFunding, address _vaultContract);
    event PaymentReceived(address indexed _owner, uint amount);
    event CampaignFailed(address indexed _owner);

    function Campaign(
        uint _startFundingTime,
        uint _endFundingTime,
        uint _maximumFunding,
        address _vaultContract
    ) {
        if ((_endFundingTime < now) || (_endFundingTime <= _startFundingTime) || (_maximumFunding > 10000 ether) || (_vaultContract == 0)) {
            throw;
        }
        startFundingTime = _startFundingTime;
        endFundingTime = _endFundingTime;
        maximumFunding = _maximumFunding;
        tokenContract = new CampaignToken();
        vaultContract = _vaultContract;
        emit CampaignLaunched(_startFundingTime, _endFundingTime, _maximumFunding, _vaultContract);
    }

    function () payable {
        doPayment(msg.sender);
    }

    function proxyPayment(address _owner) payable {
        doPayment(_owner);
    }

    function doPayment(address _owner) internal {
        if ((now < startFundingTime) || (now > endFundingTime) || (tokenContract.tokenController() == 0) || (msg.value == 0) || (totalCollected + msg.value > maximumFunding)) {
            emit CampaignFailed(_owner);
            throw;
        }
        totalCollected += msg.value;
        if (!vaultContract.send(msg.value)) {
            throw;
        }
        if (!tokenContract.createTokens(_owner, msg.value)) {
            throw;
        }
        emit PaymentReceived(_owner, msg.value);
        return;
    }

    function seal() {
        if (now < endFundingTime) throw;
        tokenContract.seal();
    }
}
