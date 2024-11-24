pragma solidity ^0.4.18;
contract OrganizeFunds {
    struct ActivityAccount {
        uint credited;
        uint balance;
        uint pctx10;
        address addr;
        string name;
    }
    
    uint constant TENHUNDWEI = 1000;
    uint constant MAX_ACCOUNTS = 10;
    
    event MessageEvent(string message);
    event MessageEventI(string message, uint val);
    
    bool public isLocked;
    string public name;
    address public owner;
    
    mapping (uint => ActivityAccount) activityAccounts;
    uint public activityCount;
    uint public totalFundsReceived;
    uint public totalFundsDistributed;
    uint public totalFundsWithdrawn;
    uint public withdrawGas = 100000;
    
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }
    
    modifier unlockedOnly {
        require(!isLocked);
        _;
    }
    
    function OrganizeFunds() public {
        owner = msg.sender;
    }
    
    function lock() public ownerOnly {
        isLocked = true;
        emit MessageEvent('Locked the contract');
    }
    
    function setName(string _name) public ownerOnly {
        name = _name;
        emit MessageEvent('Name set');
    }
    
    function reset() public ownerOnly unlockedOnly {
        totalFundsReceived = this.balance;
        totalFundsDistributed = 0;
        totalFundsWithdrawn = 0;
        activityCount = 0;
        emit MessageEvent('ok: all accts reset');
    }
    
    function setWitdrawGas(uint256 _withdrawGas) public ownerOnly unlockedOnly {
        withdrawGas = _withdrawGas;
        emit MessageEventI('ok: withdraw gas set', withdrawGas);
    }
    
    function addActivityAccount(address _addr, uint256 _pctx10, string _name) public ownerOnly unlockedOnly {
        if (activityCount >= MAX_ACCOUNTS) {
            emit MessageEvent('err: max accounts');
            return;
        }
        activityAccounts[activityCount].addr = _addr;
        activityAccounts[activityCount].pctx10 = _pctx10;
        activityAccounts[activityCount].credited = 0;
        activityAccounts[activityCount].balance = 0;
        activityAccounts[activityCount].name = _name;
        ++activityCount;
        emit MessageEvent('ok: acct added');
    }
    
    function getActivityAccountInfo(address _addr) public constant returns(uint _idx, uint _pctx10, string _name, uint _credited, uint _balance) {
        for (uint i = 0; i < activityCount; i++ ) {
            address addr = activityAccounts[i].addr;
            if (addr == _addr) {
                _idx = i;
                _pctx10 = activityAccounts[i].pctx10;
                _name = activityAccounts[i].name;
                _credited = activityAccounts[i].credited;
                _balance = activityAccounts[i].balance;
                emit MessageEvent('Account info retrieved');
                return;
            }
        }
        emit MessageEvent('Account not found');
    }
    
    function getTotalPctx10() public constant returns(uint _totalPctx10) {
        _totalPctx10 = 0;
        for (uint i = 0; i < activityCount; i++ ) {
            _totalPctx10 += activityAccounts[i].pctx10;
        }
        emit MessageEvent('Total Pctx10 calculated');
    }
    
    function () public payable {
        totalFundsReceived += msg.value;
        emit MessageEventI('ok: received', msg.value);
    }
    
    function distribute() public {
        if (this.balance < TENHUNDWEI) {
            emit MessageEvent('err: not enough balance to distribute');
            return;
        }
        uint i;
        uint pctx10;
        uint acctDist;
        for (i = 0; i < activityCount; i++ ) {
            pctx10 = activityAccounts[i].pctx10;
            acctDist = totalFundsReceived * pctx10 / TENHUNDWEI;
            
            if (activityAccounts[i].credited >= acctDist) {
                acctDist = 0;
            } else {
                acctDist = acctDist - activityAccounts[i].credited;
            }
            activityAccounts[i].credited += acctDist;
            activityAccounts[i].balance += acctDist;
            totalFundsDistributed += acctDist;
        }
        emit MessageEvent('ok: distributed funds');
    }
    
    function withdraw() public {
        for (uint i = 0; i < activityCount; i++ ) {
            address addr = activityAccounts[i].addr;
            if (addr == msg.sender || msg.sender == owner) {
                uint amount = activityAccounts[i].balance;
                if (amount > 0) {
                    activityAccounts[i].balance = 0;
                    totalFundsWithdrawn += amount;
                    if (!addr.call.gas(withdrawGas).value(amount)()) {
                        activityAccounts[i].balance = amount;
                        totalFundsWithdrawn -= amount;
                        emit MessageEvent('err: error sending funds');
                        return;
                    }
                }
            }
        }
        emit MessageEvent('Withdraw executed');
    }
    
    function hariKari() public ownerOnly unlockedOnly {
        selfdestruct(owner);
        emit MessageEvent('Contract destroyed');
    }
}
