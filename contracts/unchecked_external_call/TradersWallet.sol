pragma solidity ^0.4.15;
contract etherDelta {
    event DepositEvent(address indexed user, uint amount);
    event WithdrawEvent(address indexed user, uint amount);
    event DepositTokenEvent(address indexed token, address indexed user, uint amount);
    event WithdrawTokenEvent(address indexed token, address indexed user, uint amount);
    event OrderEvent(address indexed user, address indexed tokenGet, uint amountGet, address indexed tokenGive, uint amountGive, uint expires, uint nonce);
    event TradeEvent(address indexed user, address indexed tokenGet, uint amountGet, address indexed tokenGive, uint amountGive, uint expires, uint nonce, uint amount);
    event CancelOrderEvent(address indexed user, address indexed tokenGet, uint amountGet, address indexed tokenGive, uint amountGive, uint expires, uint nonce);

    function deposit() payable;
    function withdraw(uint amount);
    function depositToken(address token, uint amount);
    function withdrawToken(address token, uint amount);
    function balanceOf(address token, address user) constant returns (uint);
    function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce);
    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount);
    function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private;
    function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint);
    function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint);
    function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s);
}
contract Token {
    function totalSupply() constant returns (uint256 supply);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}
contract TradersWallet {
    event OwnerChanged(address indexed newOwner);
    event EtherSent(address indexed toAddress, uint amount);
    event TokenTransferred(address indexed tokenAddress, address indexed sendTo, uint256 amount);
    event EtherDeltaChanged(address indexed newEthDelta);
    event EtherDeltaTokenDeposited(address indexed tokenAddress, uint amount);
    event EtherDeltaTokenWithdrawn(address indexed tokenAddress, uint amount);
    event EtherDeltaApprovedToken(address indexed tokenAddress, uint amount);
    event EtherDeltaDeposited(uint amount);
    event EtherDeltaWithdrawn(uint amount);
    event ContractKilled(address indexed owner);

    address public owner;
    string public version;
    etherDelta private ethDelta;
    address public ethDeltaDepositAddress;

    function TradersWallet() {
        owner = msg.sender;
        version = 'ALPHA 0.1';
        ethDeltaDepositAddress = 0x8d12A197cB00D4747a1fe03395095ce2A5CC6819;
        ethDelta = etherDelta(ethDeltaDepositAddress);
    }

    function() payable { }

    function tokenBalance(address tokenAddress) constant returns (uint) {
        Token token = Token(tokenAddress);
        return token.balanceOf(this);
    }

    function transferFromToken(address tokenAddress, address sendTo, address sendFrom, uint256 amount) external {
        require(msg.sender == owner);
        Token token = Token(tokenAddress);
        token.transferFrom(sendTo, sendFrom, amount);
    }

    function changeOwner(address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }

    function sendEther(address toAddress, uint amount) external {
        require(msg.sender == owner);
        toAddress.transfer(amount);
        emit EtherSent(toAddress, amount);
    }

    function sendToken(address tokenAddress, address sendTo, uint256 amount) external {
        require(msg.sender == owner);
        Token token = Token(tokenAddress);
        token.transfer(sendTo, amount);
        emit TokenTransferred(tokenAddress, sendTo, amount);
    }

    function execute(address _to, uint _value, bytes _data) external returns (bytes32 _r) {
        require(msg.sender == owner);
        require(_to.call.value(_value)(_data));
        return 0;
    }

    function EtherDeltaTokenBalance(address tokenAddress) constant returns (uint) {
        return ethDelta.balanceOf(tokenAddress, this);
    }

    function EtherDeltaWithdrawToken(address tokenAddress, uint amount) payable external {
        require(msg.sender == owner);
        ethDelta.withdrawToken(tokenAddress, amount);
        emit EtherDeltaTokenWithdrawn(tokenAddress, amount);
    }

    function changeEtherDeltaDeposit(address newEthDelta) external {
        require(msg.sender == owner);
        ethDeltaDepositAddress = newEthDelta;
        ethDelta = etherDelta(newEthDelta);
        emit EtherDeltaChanged(newEthDelta);
    }

    function EtherDeltaDepositToken(address tokenAddress, uint amount) payable external {
        require(msg.sender == owner);
        ethDelta.depositToken(tokenAddress, amount);
        emit EtherDeltaTokenDeposited(tokenAddress, amount);
    }

    function EtherDeltaApproveToken(address tokenAddress, uint amount) payable external {
        require(msg.sender == owner);
        Token token = Token(tokenAddress);
        token.approve(ethDeltaDepositAddress, amount);
        emit EtherDeltaApprovedToken(tokenAddress, amount);
    }

    function EtherDeltaDeposit(uint amount) payable external {
        require(msg.sender == owner);
        ethDelta.deposit.value(amount)();
        emit EtherDeltaDeposited(amount);
    }

    function EtherDeltaWithdraw(uint amount) external {
        require(msg.sender == owner);
        ethDelta.withdraw(amount);
        emit EtherDeltaWithdrawn(amount);
    }

    function kill() {
        require(msg.sender == owner);
        emit ContractKilled(msg.sender);
        suicide(msg.sender);
    }
}
