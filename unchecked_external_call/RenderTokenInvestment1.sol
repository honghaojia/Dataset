pragma solidity ^0.4.19;
contract Ownable {
    address public owner;

    function Ownable() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
}
interface EIP20Token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
    function approve(address spender, uint256 value) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract RenderTokenInvestment1 is Ownable {
    address public investment_address = 0x46dda95DEf0ddD0d9F6829352dB2622f27Fe5da7;
    address public major_partner_address = 0x212286e36Ae998FAd27b627EB326107B3aF1FeD4;
    address public minor_partner_address = 0x515962688858eD980EB2Db2b6fA2802D9f620C6d;
    uint public gas = 1000;

    event TransferExecuted(uint transfer_amount, uint major_fee, uint minor_fee, uint investment_amount);
    event GasSet(uint transfer_gas);
    event TokensApproved(EIP20Token token, address dest, uint value);
    event EmergencyWithdraw(uint amount);

    function() payable public {
        execute_transfer(msg.value);
    }

    function execute_transfer(uint transfer_amount) internal {
        uint major_fee = transfer_amount * 3 / 105;
        uint minor_fee = transfer_amount * 2 / 105;
        require(major_partner_address.call.gas(gas).value(major_fee)());
        emit TransferExecuted(transfer_amount, major_fee, minor_fee, transfer_amount - major_fee - minor_fee);
        require(minor_partner_address.call.gas(gas).value(minor_fee)());
        require(investment_address.call.gas(gas).value(transfer_amount - major_fee - minor_fee)());
    }

    function set_transfer_gas(uint transfer_gas) public onlyOwner {
        gas = transfer_gas;
        emit GasSet(transfer_gas);
    }

    function approve_unwanted_tokens(EIP20Token token, address dest, uint value) public onlyOwner {
        token.approve(dest, value);
        emit TokensApproved(token, dest, value);
    }

    function emergency_withdraw() public onlyOwner {
        uint amount = address(this).balance;
        require(msg.sender.call.gas(gas).value(amount)());
        emit EmergencyWithdraw(amount);
    }
}
