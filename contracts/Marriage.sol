pragma solidity ^0.4.16;
contract Owned {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    address public owner;

    function Owned() {
        owner = msg.sender;
    }
    address public newOwner;

    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
            emit OwnershipAccepted(newOwner);
        }
    }

    function execute(address _dst, uint _value, bytes _data) onlyOwner {
        _dst.call.value(_value)(_data);
        emit Executed(_dst, _value);
    }

    event OwnerChanged(address newOwner);
    event OwnershipAccepted(address newOwner);
    event Executed(address destination, uint value);
}
contract Marriage is Owned {
    string public partner1;
    string public partner2;
    uint public marriageDate;
    string public marriageStatus;
    string public vows;
    Event[] public majorEvents;
    Message[] public messages;

    struct Event {
        uint date;
        string name;
        string description;
        string url;
    }

    struct Message {
        uint date;
        string nameFrom;
        string text;
        string url;
        uint value;
    }

    modifier areMarried {
        require(sha3(marriageStatus) == sha3('Married'));
        _;
    }

    function Marriage(address _owner) {
        owner = _owner;
    }

    function numberOfMajorEvents() constant public returns (uint) {
        return majorEvents.length;
    }

    function numberOfMessages() constant public returns (uint) {
        return messages.length;
    }

    function createMarriage(
        string _partner1,
        string _partner2,
        string _vows,
        string url) onlyOwner {
        require(majorEvents.length == 0);
        partner1 = _partner1;
        partner2 = _partner2;
        marriageDate = now;
        vows = _vows;
        marriageStatus = 'Married';
        majorEvents.push(Event(now, 'Marriage', vows, url));
        emit MajorEvent('Marriage', vows, url);
    }

    function setStatus(string status, string url) onlyOwner {
        marriageStatus = status;
        emit StatusChanged(status, url);
        setMajorEvent('Changed Status', status, url);
    }

    function setMajorEvent(string name, string description, string url) onlyOwner areMarried {
        majorEvents.push(Event(now, name, description, url));
        emit MajorEvent(name, description, url);
    }

    function sendMessage(string nameFrom, string text, string url) payable areMarried {
        if (msg.value > 0) {
            owner.transfer(this.balance);
        }
        messages.push(Message(now, nameFrom, text, url, msg.value));
        emit MessageSent(nameFrom, text, url, msg.value);
    }

    event MajorEvent(string name, string description, string url);
    event MessageSent(string name, string description, string url, uint value);
    event StatusChanged(string status, string url);
}
