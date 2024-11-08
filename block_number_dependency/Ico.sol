pragma solidity ^0.4.24;
contract Owned {
    address public owner = msg.sender;

    event OwnerChanged(address indexed newOwner);
    
    constructor(address _owner) public {
        if (_owner == 0x00) {
            _owner = msg.sender;
        }
        owner = _owner;
    }

    function replaceOwner(address _owner) external returns(bool) {
        require(isOwner());
        owner = _owner;
        emit OwnerChanged(_owner);
        return true;
    }

    function isOwner() internal view returns(bool) {
        return owner == msg.sender;
    }

    modifier forOwner {
        require(isOwner());
        _;
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a - b;
        assert(c <= a);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a * b;
        assert(c == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return a / b;
    }

    function pow(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a ** b;
        assert(c % a == 0);
        return a ** b;
    }
}
contract TokenDB is Owned {
    event TransferExecuted(address indexed from, address indexed to, uint256 amount);
    
    function transfer(address _from, address _to, uint256 _amount) external returns(bool _success) {
        emit TransferExecuted(_from, _to, _amount);
    }

    function bulkTransfer(address _from, address[] _to, uint256[] _amount) external returns(bool _success) {}

    function setAllowance(address _owner, address _spender, uint256 _amount) external returns(bool _success) {}

    function getAllowance(address _owner, address _spender) public view returns(bool _success, uint256 _remaining) {}

    function balanceOf(address _owner) public view returns(bool _success, uint256 _balance) {}
}
contract Token is Owned {
    using SafeMath for uint256;

    string  public name = 'Inlock token';
    string  public symbol = 'ILK';
    uint8   public decimals = 8;
    uint256 public totalSupply = 44e16;
    address public libAddress;
    TokenDB public db;
    Ico public ico;

    event LibAddressChanged(address indexed newLibAddress);
    event DBAddressChanged(address indexed newDBAddress);
    event IcoAddressChanged(address indexed newIcoAddress);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint _value);

    function () public { revert(); }

    function changeLibAddress(address _libAddress) external forOwner {
        libAddress = _libAddress;
        emit LibAddressChanged(_libAddress);
    }

    function changeDBAddress(address _dbAddress) external forOwner {
        db = TokenDB(_dbAddress);
        emit DBAddressChanged(_dbAddress);
    }

    function changeIcoAddress(address _icoAddress) external forOwner {
        ico = Ico(_icoAddress);
        emit IcoAddressChanged(_icoAddress);
    }

    function approve(address _spender, uint256 _value) external returns (bool _success) {}

    function transfer(address _to, uint256 _amount) external returns (bool _success) {}

    function bulkTransfer(address[] _to, uint256[] _amount) external returns (bool _success) {}

    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool _success) {}

    function allowance(address _owner, address _spender) public view returns (uint256 _remaining) {}

    function balanceOf(address _owner) public view returns (uint256 _balance) {}
}
contract Ico is Owned {
    using SafeMath for uint256;

    enum phaseType { pause, privateSale1, privateSale2, sales1, sales2, sales3, sales4, preFinish, finish }
    
    struct vesting_s {
        uint256 amount;
        uint256 startBlock;
        uint256 endBlock;
        uint256 claimedAmount;
    }

    event KYCChanged(address indexed beneficiary, bool indexed status);
    event RateChanged(uint256 newRate);
    
    mapping(address => bool) public KYC;
    mapping(address => bool) public transferRight;
    mapping(address => vesting_s) public vesting;
    phaseType public currentPhase;
    uint256 public currentRate;
    uint256 public currentRateM = 1e3;
    uint256 public privateSale1Hardcap = 4e16;
    uint256 public privateSale2Hardcap = 64e15;
    uint256 public thisBalance = 44e16;
    address public offchainUploaderAddress;
    address public setKYCAddress;
    address public setRateAddress;
    address public libAddress;
    Token public token;

    constructor(address _owner, address _libAddress, address _tokenAddress, address _offchainUploaderAddress,
                address _setKYCAddress, address _setRateAddress) Owned(_owner) public {
        currentPhase = phaseType.pause;
        libAddress = _libAddress;
        token = Token(_tokenAddress);
        offchainUploaderAddress = _offchainUploaderAddress;
        setKYCAddress = _setKYCAddress;
        setRateAddress = _setRateAddress;
    }

    function () public payable {
        buy();
    }

    function changeLibAddress(address _libAddress) external forOwner {
        libAddress = _libAddress;
    }

    function changeOffchainUploaderAddress(address _offchainUploaderAddress) external forOwner {
        offchainUploaderAddress = _offchainUploaderAddress;
    }

    function changeKYCAddress(address _setKYCAddress) external forOwner {
        setKYCAddress = _setKYCAddress;
    }

    function changeSetRateAddress(address _setRateAddress) external forOwner {
        setRateAddress = _setRateAddress;
    }

    function setVesting(address _beneficiary, uint256 _amount, uint256 _startBlock, uint256 _endBlock) external {
        emit VestingDefined(_beneficiary, _amount, _startBlock, _endBlock);
    }

    function claimVesting() external {
        emit VestingClaimed(msg.sender, vesting[msg.sender].amount);
    }

    function setKYC(address[] _on, address[] _off) external {
        for (uint256 i = 0; i < _on.length; i++) {
            KYC[_on[i]] = true;
            emit KYCChanged(_on[i], true);
        }
        for (uint256 j = 0; j < _off.length; j++) {
            KYC[_off[j]] = false;
            emit KYCChanged(_off[j], false);
        }
    }

    function setTransferRight(address[] _allow, address[] _disallow) external {
        for (uint256 i = 0; i < _allow.length; i++) {
            transferRight[_allow[i]] = true;
        }
        for (uint256 j = 0; j < _disallow.length; j++) {
            transferRight[_disallow[j]] = false;
        }
    }

    function setCurrentRate(uint256 _currentRate) external {
        currentRate = _currentRate;
        emit RateChanged(_currentRate);
    }

    function setCurrentPhase(phaseType _phase) external {
        currentPhase = _phase;
    }

    function offchainUpload(address[] _beneficiaries, uint256[] _rewards) external {}

    function buy() public payable {}

    function allowTransfer(address _owner) public view returns (bool _success, bool _allow) {}

    function calculateReward(uint256 _input) public view returns (bool _success, uint256 _reward) {}

    function calcVesting(address _owner) public view returns(bool _success, uint256 _reward) {}
    
    event Brought(address _owner, address _beneficiary, uint256 _input, uint256 _output);
    event VestingDefined(address _beneficiary, uint256 _amount, uint256 _startBlock, uint256 _endBlock);
    event VestingClaimed(address _beneficiary, uint256 _amount);
}
