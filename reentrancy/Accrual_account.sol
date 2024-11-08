pragma solidity ^0.4.24;
contract Accrual_account {
    address admin = msg.sender;
    uint targetAmount = 1 ether;
    mapping(address => uint) public investors;

    event FundsMove(uint amount, bytes32 typeAct, address adr);
    event AdminChanged(address newAdmin);
    event FundTransferred(uint amount, bytes32 operation, address to, address feeToAdr);
    event SuccessfulCall(address to, uint amount);
    event InReceived(address sender, uint amount);
    event OutProcessed(address sender, uint amount);

    function changeAdmin(address _new) public {
        if (_new == 0x0) revert();
        if (msg.sender != admin) revert();
        admin = _new;
        emit AdminChanged(_new);
    }

    function FundTransfer(uint _am, bytes32 _operation, address _to, address _feeToAdr) 
        payable 
    {
        if (msg.sender != address(this)) revert();
        if (_operation == 'In') {
            emit FundsMove(msg.value, 'In', _to);
            investors[_to] += _am;
            emit FundTransferred(msg.value, 'In', _to, _feeToAdr);
        } else {
            uint amTotransfer = 0;
            if (_to == _feeToAdr) {
                amTotransfer = _am;
            } else {
                amTotransfer = _am / 100 * 99;
                investors[_feeToAdr] += _am - amTotransfer;
            }
            if (_to.call.value(_am)() == false) revert();
            investors[_to] -= _am;
            emit SuccessfulCall(_to, _am);
            emit FundsMove(_am, 'Out', _to);
        }
    }

    function() 
        payable 
    {
        emit InReceived(msg.sender, msg.value);
        In(msg.sender);
    }

    function Out(uint amount) 
        payable 
    {
        if (investors[msg.sender] < targetAmount) revert();
        if (investors[msg.sender] < amount) revert();
        this.FundTransfer(amount, '', msg.sender, admin);
        emit OutProcessed(msg.sender, amount);
    }

    function In(address to) 
        payable 
    {
        if (to == 0x0) to = admin;
        if (msg.sender != tx.origin) revert();
        this.FundTransfer(msg.value, 'In', to, admin);
    }
}
