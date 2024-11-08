pragma solidity ^0.4.4;
contract MultiSigWallet {
    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
    event OnlyWalletAccess(address sender);
    event OwnerDoesNotExist(address owner);
    event OwnerExists(address owner);
    event TransactionExists(uint transactionId);
    event ConfirmedTransaction(uint transactionId, address owner);
    event NotConfirmedTransaction(uint transactionId, address owner);
    event NotExecutedTransaction(uint transactionId);
    event NotNullAddress(address _address);
    event ValidRequirement(uint ownerCount, uint _required);
    event ExecutedTransaction(uint transactionId);
    event ExecutionFailed(uint transactionId);
    event TransactionAdded(uint transactionId);
    
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this)) {
            emit OnlyWalletAccess(msg.sender);
            throw;
        }
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner]) {
            emit OwnerDoesNotExist(owner);
            throw;
        }
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner]) {
            emit OwnerExists(owner);
            throw;
        }
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0) {
            emit TransactionExists(transactionId);
            throw;
        }
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner]) {
            emit NotConfirmedTransaction(transactionId, owner);
            throw;
        }
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner]) {
            emit NotConfirmedTransaction(transactionId, owner);
            throw;
        }
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed) {
            emit NotExecutedTransaction(transactionId);
            throw;
        }
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0) {
            emit NotNullAddress(_address);
            throw;
        }
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (ownerCount > MAX_OWNER_COUNT || _required > ownerCount || _required == 0 || ownerCount == 0) {
            emit ValidRequirement(ownerCount, _required);
            throw;
        }
        _;
    }

    function() payable {
        if (msg.value > 0) {
            Deposit(msg.sender, msg.value);
        }
    }

    function MultiSigWallet(address[] _owners, uint _required) public validRequirement(_owners.length, _required) {
        for (uint i = 0; i < _owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0) throw;
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    function addOwner(address owner) public onlyWallet ownerDoesNotExist(owner) notNull(owner) validRequirement(owners.length + 1, required) {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

    function removeOwner(address owner) public onlyWallet ownerExists(owner) {
        isOwner[owner] = false;
        for (uint i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.length -= 1;
        if (required > owners.length) changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

    function replaceOwner(address owner, address newOwner) public onlyWallet ownerExists(owner) ownerDoesNotExist(newOwner) {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

    function changeRequirement(uint _required) public onlyWallet validRequirement(owners.length, _required) {
        required = _required;
        RequirementChange(_required);
    }

    function submitTransaction(address destination, uint value, bytes data) public returns (uint transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    function confirmTransaction(uint transactionId) public ownerExists(msg.sender) transactionExists(transactionId) notConfirmed(transactionId, msg.sender) {
        confirmations[transactionId][msg.sender] = true;
        emit ConfirmedTransaction(transactionId, msg.sender);
        executeTransaction(transactionId);
    }

    function revokeConfirmation(uint transactionId) public ownerExists(msg.sender) confirmed(transactionId, msg.sender) notExecuted(transactionId) {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

    function executeTransaction(uint transactionId) public notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction tx = transactions[transactionId];
            tx.executed = true;
            if (tx.destination.call.value(tx.value)(tx.data)) {
                emit ExecutedTransaction(transactionId);
            } else {
                emit ExecutionFailed(transactionId);
                tx.executed = false;
            }
        }
    }

    function isConfirmed(uint transactionId) public constant returns (bool) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) count += 1;
            if (count == required) return true;
        }
    }

    function addTransaction(address destination, uint value, bytes data) internal notNull(destination) returns (uint transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit TransactionAdded(transactionId);
        Submission(transactionId);
    }

    function getConfirmationCount(uint transactionId) public constant returns (uint count) {
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) count += 1;
        }
    }

    function getTransactionCount(bool pending, bool executed) public constant returns (uint count) {
        for (uint i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) count += 1;
        }
    }

    function getOwners() public constant returns (address[]) {
        return owners;
    }

    function getConfirmations(uint transactionId) public constant returns (address[] _confirmations) {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }

    function getTransactionIds(uint from, uint to, bool pending, bool executed) public constant returns (uint[] _transactionIds) {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
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
contract StarbasePresaleWallet is MultiSigWallet {
    uint256 public maxCap;
    uint256 public totalPaidAmount;

    struct WhitelistAddresses {
        uint256 capForAmountRaised;
        uint256 amountRaised;
        bool bonaFide;
    }

    mapping (address => WhitelistAddresses) public whitelistedAddresses;

    function StarbasePresaleWallet(address[] _owners, uint256 _required, uint256 _maxCap)
        public MultiSigWallet(_owners, _required) {
        maxCap = _maxCap;
    }

    function whitelistAddress(address addressToWhitelist, uint256 capAmount) external ownerExists(msg.sender) {
        assert(!whitelistedAddresses[addressToWhitelist].bonaFide);
        whitelistedAddresses[addressToWhitelist].bonaFide = true;
        whitelistedAddresses[addressToWhitelist].capForAmountRaised = capAmount;
    }

    function unwhitelistAddress(address addressToUnwhitelist) external ownerExists(msg.sender) {
        assert(whitelistedAddresses[addressToUnwhitelist].bonaFide);
        whitelistedAddresses[addressToUnwhitelist].bonaFide = false;
    }

    function changeWhitelistedAddressCapAmount(address whitelistedAddress, uint256 capAmount) external ownerExists(msg.sender) {
        assert(whitelistedAddresses[whitelistedAddress].bonaFide);
        whitelistedAddresses[whitelistedAddress].capForAmountRaised = capAmount;
    }

    function changeMaxCap(uint256 _maxCap) external ownerExists(msg.sender) {
        assert(totalPaidAmount <= _maxCap);
        maxCap = _maxCap;
    }

    function payment() payable {
        require(msg.value > 0 && this.balance <= maxCap);
        require(whitelistedAddresses[msg.sender].bonaFide);
        whitelistedAddresses[msg.sender].amountRaised = SafeMath.add(msg.value, whitelistedAddresses[msg.sender].amountRaised);
        assert(whitelistedAddresses[msg.sender].amountRaised <= whitelistedAddresses[msg.sender].capForAmountRaised);
        totalPaidAmount = SafeMath.add(totalPaidAmount, msg.value);
        Deposit(msg.sender, msg.value);
    }

    function () payable {
        payment();
    }
}
