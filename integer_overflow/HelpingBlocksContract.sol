pragma solidity ^0.4.24;
contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
            emit OwnershipTransferred(newOwner);
        } else {
            emit OwnershipTransferFailed();
        }
    }

    event OwnershipTransferred(address indexed newOwner);
    event OwnershipTransferFailed();
}
contract HelpingBlocksContract is Ownable {
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;
    string public description;
    bool public donationClosed = false;
    mapping (address => uint256) public balanceOf;

    mapping (address => uint256) public myDonation;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event DonationClosed();
    event DonationEnabled();
    event DescriptionSet(string description);

    constructor() public {
        name = 'Helping Blocks Token';
        symbol = 'HBT';
        decimals = 0;
        totalSupply = 10000000;
        description = 'Kerala Flood Relief Fund';
        balanceOf[owner] = totalSupply;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public onlyOwner returns(bool success) {
        _transfer(owner, _to, _value);
        return true;
    }

    function disableDonation() public onlyOwner returns(bool success) {
        donationClosed = true;
        emit DonationClosed();
        return true;
    }

    function enableDonation() public onlyOwner returns(bool success) {
        donationClosed = false;
        emit DonationEnabled();
        return true;
    }

    function setDescription(string str) public onlyOwner returns(bool success) {
        description = str;
        emit DescriptionSet(str);
        return true;
    }

    function () payable public {
        require(!donationClosed);
        myDonation[msg.sender] += msg.value;
        if (balanceOf[msg.sender] < 1) {
            _transfer(owner, msg.sender, 1);
            emit DonationMade(msg.sender, 1);
        }
    }

    event DonationMade(address indexed donor, uint256 value);

    function safeWithdrawal(uint256 _value) payable public onlyOwner {
        owner.transfer(_value);
    }
}
