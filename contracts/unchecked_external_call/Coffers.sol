pragma solidity ^0.4.10;
contract SimpleToken {
    mapping(address => uint) public balances;

    event TokenBought(address indexed buyer, uint amount);
    event TokenSent(address indexed sender, address indexed recipient, uint amount);

    function buyToken() payable {
        balances[msg.sender] += msg.value / 1 ether;
        emit TokenBought(msg.sender, msg.value / 1 ether);
    }

    function sendToken(address _recipient, uint _amount) {
        require(balances[msg.sender] != 0);
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit TokenSent(msg.sender, _recipient, _amount);
    }
}
contract VoteTwoChoices {
    mapping(address => uint) public votingRights;
    mapping(address => uint) public votesCast;
    mapping(bytes32 => uint) public votesReceived;

    event VotingRightsPurchased(address indexed purchaser, uint amount);
    event Voted(address indexed voter, uint nbVotes, bytes32 indexed proposition);

    function buyVotingRights() payable {
        votingRights[msg.sender] += msg.value / (1 ether);
        emit VotingRightsPurchased(msg.sender, msg.value / (1 ether));
    }

    function vote(uint _nbVotes, bytes32 _proposition) {
        require(_nbVotes + votesCast[msg.sender] <= votingRights[msg.sender]);
        votesCast[msg.sender] += _nbVotes;
        votesReceived[_proposition] += _nbVotes;
        emit Voted(msg.sender, _nbVotes, _proposition);
    }
}
contract BuyToken {
    mapping(address => uint) public balances;
    uint public price = 1;
    address public owner = msg.sender;

    event TokenBought(address indexed buyer, uint amount);
    event PriceSet(uint newPrice);

    function buyToken(uint _amount, uint _price) payable {
        require(_price >= price);
        require(_price * _amount * 1 ether <= msg.value);
        balances[msg.sender] += _amount;
        emit TokenBought(msg.sender, _amount);
    }

    function setPrice(uint _price) {
        require(msg.sender == owner);
        price = _price;
        emit PriceSet(_price);
    }
}
contract Store {
    struct Safe {
        address owner;
        uint amount;
    }
    
    Safe[] public safes;

    event Stored(address indexed owner, uint amount);
    event Taken(address indexed owner, uint amount);

    function store() payable {
        safes.push(Safe({owner: msg.sender, amount: msg.value}));
        emit Stored(msg.sender, msg.value);
    }

    function take() {
        for (uint i; i < safes.length; ++i) {
            Safe memory safe = safes[i];
            if (safe.owner == msg.sender && safe.amount != 0) {
                uint amountToTransfer = safe.amount;
                msg.sender.transfer(amountToTransfer);
                emit Taken(msg.sender, amountToTransfer);
                safe.amount = 0;
            }
        }
    }
}
contract CountContribution {
    mapping(address => uint) public contribution;
    uint public totalContributions;
    address owner = msg.sender;

    event ContributionRecorded(address indexed contributor, uint amount);

    function CountContribution() public {
        recordContribution(owner, 1 ether);
    }

    function contribute() public payable {
        recordContribution(msg.sender, msg.value);
    }

    function recordContribution(address _user, uint _amount) {
        contribution[_user] += _amount;
        totalContributions += _amount;
        emit ContributionRecorded(_user, _amount);
    }
}
contract Token {
    mapping(address => uint) public balances;

    event TokenBought(address indexed buyer, uint amount);
    event TokenSent(address indexed sender, address indexed recipient, uint amount);
    event AllTokensSent(address indexed sender, address indexed recipient, uint amount);

    function buyToken() payable {
        balances[msg.sender] += msg.value / 1 ether;
        emit TokenBought(msg.sender, msg.value / 1 ether);
    }

    function sendToken(address _recipient, uint _amount) {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit TokenSent(msg.sender, _recipient, _amount);
    }

    function sendAllTokens(address _recipient) {
        uint amount = balances[msg.sender];
        balances[_recipient] = amount;
        balances[msg.sender] = 0;
        emit AllTokensSent(msg.sender, _recipient, amount);
    }
}
contract DiscountedBuy {
    uint public basePrice = 1 ether;
    mapping(address => uint) public objectBought;

    event Bought(address indexed buyer);
    event PriceCalculated(uint price);

    function buy() payable {
        require(msg.value * (1 + objectBought[msg.sender]) == basePrice);
        objectBought[msg.sender] += 1;
        emit Bought(msg.sender);
    }

    function price() constant returns(uint price) {
        return basePrice / (1 + objectBought[msg.sender]);
    }
}
contract HeadOrTail {
    bool public chosen;
    bool lastChoiceHead;
    address public lastParty;

    event Chosen(address indexed chooser, bool choice);
    event Guessed(address indexed guesser, bool guess, bool result);

    function choose(bool _chooseHead) payable {
        require(!chosen);
        require(msg.value == 1 ether);
        chosen = true;
        lastChoiceHead = _chooseHead;
        lastParty = msg.sender;
        emit Chosen(msg.sender, _chooseHead);
    }

    function guess(bool _guessHead) payable {
        require(chosen);
        require(msg.value == 1 ether);
        if (_guessHead == lastChoiceHead) {
            msg.sender.transfer(2 ether);
            emit Guessed(msg.sender, _guessHead, true);
        } else {
            lastParty.transfer(2 ether);
            emit Guessed(lastParty, _guessHead, false);
        }
        chosen = false;
    }
}
contract Vault {
    mapping(address => uint) public balances;

    event Stored(address indexed owner, uint amount);
    event Redeemed(address indexed owner, uint amount);

    function store() payable {
        balances[msg.sender] += msg.value;
        emit Stored(msg.sender, msg.value);
    }

    function redeem() {
        uint amount = balances[msg.sender];
        msg.sender.call.value(amount)();
        balances[msg.sender] = 0;
        emit Redeemed(msg.sender, amount);
    }
}
contract HeadTail {
    address public partyA;
    address public partyB;
    bytes32 public commitmentA;
    bool public chooseHeadB;
    uint public timeB;

    event GameStarted(address indexed playerA, bytes32 commitment);
    event Guessed(address indexed playerB, bool choice);
    event Resolved(address indexed winner, uint amount);

    function HeadTail(bytes32 _commitmentA) payable {
        require(msg.value == 1 ether);
        commitmentA = _commitmentA;
        partyA = msg.sender;
        emit GameStarted(msg.sender, _commitmentA);
    }

    function guess(bool _chooseHead) payable {
        require(msg.value == 1 ether);
        require(partyB == address(0));
        chooseHeadB = _chooseHead;
        timeB = now;
        partyB = msg.sender;
        emit Guessed(msg.sender, _chooseHead);
    }

    function resolve(bool _chooseHead, uint _randomNumber) {
        require(msg.sender == partyA);
        require(keccak256(_chooseHead, _randomNumber) == commitmentA);
        require(this.balance >= 2 ether);
        if (_chooseHead == chooseHeadB) {
            partyB.transfer(2 ether);
            emit Resolved(partyB, 2 ether);
        } else {
            partyA.transfer(2 ether);
            emit Resolved(partyA, 2 ether);
        }
    }

    function timeOut() {
        require(now > timeB + 1 days);
        require(this.balance >= 2 ether);
        partyB.transfer(2 ether);
        emit Resolved(partyB, 2 ether);
    }
}
contract Coffers {
    struct Coffer {
        address owner;
        uint[] slots;
    }
    
    Coffer[] public coffers;

    event CofferCreated(address indexed creator, uint slots);
    event Deposited(address indexed owner, uint coffer, uint slot, uint amount);
    event Withdrawn(address indexed owner, uint coffer, uint slot, uint amount);

    function createCoffer(uint _slots) external {
        Coffer storage coffer = coffers[coffers.length++];
        coffer.owner = msg.sender;
        coffer.slots.length = _slots;
        emit CofferCreated(msg.sender, _slots);
    }

    function deposit(uint _coffer, uint _slot) payable external {
        Coffer storage coffer = coffers[_coffer];
        coffer.slots[_slot] += msg.value;
        emit Deposited(msg.sender, _coffer, _slot, msg.value);
    }

    function withdraw(uint _coffer, uint _slot) external {
        Coffer storage coffer = coffers[_coffer];
        require(coffer.owner == msg.sender);
        uint amount = coffer.slots[_slot];
        msg.sender.transfer(amount);
        coffer.slots[_slot] = 0;
        emit Withdrawn(msg.sender, _coffer, _slot, amount);
    }
}
