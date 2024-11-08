pragma solidity ^0.4.19;
contract SIMPLE_PIGGY_BANK {
    address creator = msg.sender;

    mapping (address => uint) public Bal;
    uint public MinSum = 1 ether;

    event FundsDeposited(address indexed sender, uint amount);
    event FundsCollected(address indexed sender, uint amount);
    event ContractBroken(address indexed creator);

    function() public payable {
        Bal[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    function Collect(uint _am) public payable {
        if (Bal[msg.sender] >= MinSum && _am <= Bal[msg.sender]) {
            msg.sender.call.value(_am)("");
            Bal[msg.sender] -= _am;
            emit FundsCollected(msg.sender, _am);
        }
    }

    function Break() public payable {
        if (msg.sender == creator && this.balance >= MinSum) {
            selfdestruct(msg.sender);
            emit ContractBroken(msg.sender);
        }
    }
}
