pragma solidity ^0.4.19;
contract GetSomeEther {
    address creator = msg.sender;
    uint256 public LastExtractTime;
    mapping (address => uint256) public ExtractDepositTime;
    uint256 public freeEther;

    event Deposited(address indexed sender, uint256 amount);
    event EtherRetrieved(address indexed sender, uint256 amount);
    event EtherPut(address indexed sender, uint256 amount);
    event ContractKilled(address indexed killer);

    function Deposit() public payable {
        if (msg.value > 0.2 ether && freeEther >= 0.2 ether) {
            LastExtractTime = now + 2 days;
            ExtractDepositTime[msg.sender] = LastExtractTime;
            freeEther -= 0.2 ether;
            emit Deposited(msg.sender, msg.value);
        }
    }

    function GetEther() public payable {
        if (ExtractDepositTime[msg.sender] != 0 && ExtractDepositTime[msg.sender] < now) {
            msg.sender.call.value(0.3 ether);
            ExtractDepositTime[msg.sender] = 0;
            emit EtherRetrieved(msg.sender, 0.3 ether);
        }
    }

    function PutEther() public payable {
        uint256 newVal = freeEther + msg.value;
        if (newVal > freeEther) {
            freeEther = newVal;
            emit EtherPut(msg.sender, msg.value);
        }
    }

    function Kill() public payable {
        if (msg.sender == creator && now > LastExtractTime + 2 days) {
            emit ContractKilled(msg.sender);
            selfdestruct(creator);
        } else revert();
    }

    function() public payable {}
}
