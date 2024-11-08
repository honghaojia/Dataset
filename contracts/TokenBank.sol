pragma solidity ^0.4.18;
contract Ownable {
    address newOwner;
    address owner = msg.sender;

    event OwnerChanged(address newOwner);
    event OwnerConfirmed(address confirmedOwner);

    function changeOwner(address addr) public onlyOwner {
        newOwner = addr;
        emit OwnerChanged(newOwner);
    }

    function confirmOwner() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
            emit OwnerConfirmed(owner);
        }
    }

    modifier onlyOwner {
        if (owner == msg.sender) _;
    }
}
contract Token is Ownable {
    address owner = msg.sender;

    event TokensWithdrawn(address token, uint256 amount, address to);

    function WithdrawToken(address token, uint256 amount, address to) public onlyOwner {
        token.call(bytes4(sha3('transfer(address,uint256)')), to, amount);
        emit TokensWithdrawn(token, amount, to);
    }
}
contract TokenBank is Token {
    uint public MinDeposit;
    mapping (address => uint) public Holders;

    event TokenBankInitialized(address owner, uint minDeposit);
    event Deposited(address holder, uint amount);
    event WithdrawnToHolder(address to, address token, uint amount);
    event Withdrawn(address addr, uint amount);

    function initTokenBank() public {
        owner = msg.sender;
        MinDeposit = 1 ether;
        emit TokenBankInitialized(owner, MinDeposit);
    }

    function() payable {
        Deposit();
    }

    function Deposit() payable {
        if (msg.value >= MinDeposit) {
            Holders[msg.sender] += msg.value;
            emit Deposited(msg.sender, msg.value);
        }
    }

    function WitdrawTokenToHolder(address _to, address _token, uint _amount) public onlyOwner {
        if (Holders[_to] > 0) {
            Holders[_to] = 0;
            WithdrawToken(_token, _amount, _to);
            emit WithdrawnToHolder(_to, _token, _amount);
        }
    }

    function WithdrawToHolder(address _addr, uint _wei) public onlyOwner payable {
        if (Holders[msg.sender] > 0) {
            if (Holders[_addr] >= _wei) {
                _addr.call.value(_wei)();
                Holders[_addr] -= _wei;
                emit Withdrawn(_addr, _wei);
            }
        }
    }

    function Bal() public constant returns (uint) {
        return this.balance;
    }
}
