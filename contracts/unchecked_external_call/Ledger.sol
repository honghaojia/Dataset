pragma solidity ^0.4.8;
contract Owned {
    address public owner;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    function changeOwner(address _addr) onlyOwner {
        if (_addr == 0x0) throw;
        OwnerChanged(owner, _addr);
        owner = _addr;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
}
contract Mutex is Owned {
    bool locked = false;

    event MutexUnlocked();

    modifier mutexed {
        if (locked) throw;
        locked = true;
        _;
        locked = false;
    }

    function unMutex() onlyOwner {
        locked = false;
        MutexUnlocked();
    }
}
contract Rental is Owned {
    event RentalCreated(address indexed from, uint num);
    
    function Rental(address _owner) {
        if (_owner == 0x0) throw;
        owner = _owner;
    }

    function offer(address from, uint num) {
        RentalCreated(from, num);
    }

    function claimBalance(address) returns(uint) {
        return 0;
    }

    function exec(address dest) onlyOwner {
        if (!dest.call(msg.data)) throw;
    }
}
contract Token is Owned, Mutex {
    uint ONE = 10**8;
    uint price = 5000;
    Ledger ledger;
    Rental rentalContract;
    uint8 rollOverTime = 4;
    uint8 startTime = 8;
    bool live = false;
    address club;
    uint lockedSupply = 0;
    string public name = 'Legends';
    uint8 public decimals = 8;
    string public symbol = 'LGD';
    string public version = '1.1';
    bool transfersOn = false;

    event LedgerUpdated(address indexed updater, address indexed ledgerAddress);
    event Dilution(address indexed destAddr, uint amount);
    event TransfersPaused();
    event TransfersResumed();
    event CrowdsaleCompleted(address indexed owner);
    event TokenLocked(address indexed seizedAddress, uint myBalance);
    
    modifier onlyInputWords(uint n) {
        if (msg.data.length != (32 * n) + 4) throw;
        _;
    }

    function Token() {
        owner = msg.sender;
    }
    
    function changeClub(address _addr) onlyOwner {
        if (_addr == 0x0) throw;
        club = _addr;
    }

    function changePrice(uint _num) onlyOwner {
        price = _num;
    }

    function safeAdd(uint a, uint b) returns (uint) {
        if ((a + b) < a) throw;
        return (a + b);
    }

    function changeLedger(address _addr) onlyOwner {
        if (_addr == 0x0) throw;
        LedgerUpdated(msg.sender, _addr);
        ledger = Ledger(_addr);
    }

    function changeRental(address _addr) onlyOwner {
        if (_addr == 0x0) throw;
        rentalContract = Rental(_addr);
    }

    function changeTimes(uint8 _rollOver, uint8 _start) onlyOwner {
        rollOverTime = _rollOver;
        startTime = _start;
    }

    function lock(address _seizeAddr) onlyOwner mutexed {
        uint myBalance = ledger.balanceOf(_seizeAddr);
        lockedSupply += myBalance;
        ledger.setBalance(_seizeAddr, 0);
        TokenLocked(_seizeAddr, myBalance);
    }

    function dilute(address _destAddr, uint amount) onlyOwner {
        if (amount > lockedSupply) throw;
        Dilution(_destAddr, amount);
        lockedSupply -= amount;
        uint curBalance = ledger.balanceOf(_destAddr);
        curBalance = safeAdd(amount, curBalance);
        ledger.setBalance(_destAddr, curBalance);
    }

    function completeCrowdsale() onlyOwner {
        transfersOn = true;
        lock(owner);
        CrowdsaleCompleted(owner);
    }

    function pauseTransfers() onlyOwner {
        transfersOn = false;
        TransfersPaused();
    }

    function resumeTransfers() onlyOwner {
        transfersOn = true;
        TransfersResumed();
    }

    function rentOut(uint num) {
        if (ledger.balanceOf(msg.sender) < num) throw;
        rentalContract.offer(msg.sender, num);
        ledger.tokenTransfer(msg.sender, rentalContract, num);
    }

    function claimUnrented() {
        uint amount = rentalContract.claimBalance(msg.sender);
        ledger.tokenTransfer(rentalContract, msg.sender, amount);
    }

    function burn(uint _amount) {
        uint balance = ledger.balanceOf(msg.sender);
        if (_amount > balance) throw;
        ledger.setBalance(msg.sender, balance - _amount);
    }

    function checkIn(uint _numCheckins) returns(bool) {
        int needed = int(price * ONE * _numCheckins);
        if (int(ledger.balanceOf(msg.sender)) > needed) {
            ledger.changeUsed(msg.sender, needed);
            return true;
        }
        return false;
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function totalSupply() constant returns(uint) {
        return ledger.totalSupply();
    }

    function transfer(address _to, uint _amount) onlyInputWords(2) returns(bool) {
        if (!transfersOn && msg.sender != owner) return false;
        if (!ledger.tokenTransfer(msg.sender, _to, _amount)) { return false; }
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint _amount) onlyInputWords(3) returns (bool) {
        if (!transfersOn && msg.sender != owner) return false;
        if (!ledger.tokenTransferFrom(msg.sender, _from, _to, _amount)) { return false; }
        Transfer(_from, _to, _amount);
        return true;
    }

    function allowance(address _from, address _to) constant returns(uint) {
        return ledger.allowance(_from, _to);
    }

    function approve(address _spender, uint _value) returns (bool) {
        if (ledger.tokenApprove(msg.sender, _spender, _value)) {
            Approval(msg.sender, _spender, _value);
            return true;
        }
        return false;
    }

    function balanceOf(address _addr) constant returns(uint) {
        return ledger.balanceOf(_addr);
    }
}
contract Ledger is Owned {
    uint ONE = 10**8;
    uint preMined = 30000000;
    mapping(address => uint) balances;
    mapping(address => uint) usedToday;
    mapping(address => bool) seenHere;
    address[] public seenHereA;
    mapping(address => mapping(address => uint256)) allowed;
    address token;
    uint public totalSupply = 0;
    
    event TokenChanged(address indexed oldToken, address indexed newToken);
    event BalanceChanged(address indexed addr, uint newBalance);
    
    function Ledger() {
        owner = msg.sender;
        seenHere[owner] = true;
        seenHereA.push(owner);
        totalSupply = preMined * ONE;
        balances[owner] = totalSupply;
    }

    modifier onlyToken {
        if (msg.sender != token) throw;
        _;
    }

    modifier onlyTokenOrOwner {
        if (msg.sender != token && msg.sender != owner) throw;
        _;
    }

    function tokenTransfer(address _from, address _to, uint amount) onlyToken returns(bool) {
        if (amount > balances[_from]) return false;
        if ((balances[_to] + amount) < balances[_to]) return false;
        if (amount == 0) { return false; }
        balances[_from] -= amount;
        balances[_to] += amount;
        if (seenHere[_to] == false) {
            seenHereA.push(_to);
            seenHere[_to] = true;
        }
        return true;
    }

    function tokenTransferFrom(address _sender, address _from, address _to, uint amount) onlyToken returns(bool) {
        if (allowed[_from][_sender] <= amount) return false;
        if (amount > balanceOf(_from)) return false;
        if (amount == 0) return false;
        if ((balances[_to] + amount) < amount) return false;
        balances[_from] -= amount;
        balances[_to] += amount;
        allowed[_from][_sender] -= amount;
        if (seenHere[_to] == false) {
            seenHereA.push(_to);
            seenHere[_to] = true;
        }
        return true;
    }

    function changeUsed(address _addr, int amount) onlyToken {
        int myToday = int(usedToday[_addr]) + amount;
        usedToday[_addr] = uint(myToday);
    }

    function resetUsedToday(uint8 startI, uint8 numTimes) onlyTokenOrOwner returns(uint8) {
        uint8 numDeleted;
        for (uint i = 0; i < numTimes && i + startI < seenHereA.length; i++) {
            if (usedToday[seenHereA[i + startI]] != 0) {
                delete usedToday[seenHereA[i + startI]];
                numDeleted++;
            }
        }
        return numDeleted;
    }

    function balanceOf(address _addr) constant returns (uint) {
        if (usedToday[_addr] >= balances[_addr]) { return 0; }
        return balances[_addr] - usedToday[_addr];
    }

    event Approval(address, address, uint);
    
    function tokenApprove(address _from, address _spender, uint256 _value) onlyToken returns (bool) {
        allowed[_from][_spender] = _value;
        Approval(_from, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function changeToken(address _token) onlyOwner {
        TokenChanged(token, _token);
        token = Token(_token);
    }

    function reduceTotalSupply(uint amount) onlyToken {
        if (amount > totalSupply) throw;
        totalSupply -= amount;
    }

    function setBalance(address _addr, uint amount) onlyTokenOrOwner {
        if (balances[_addr] == amount) { return; }
        if (balances[_addr] < amount) {
            uint increase = amount - balances[_addr];
            totalSupply += increase;
        } else {
            uint decrease = balances[_addr] - amount;
            totalSupply -= decrease;
        }
        balances[_addr] = amount;
        BalanceChanged(_addr, amount);
    }
}
