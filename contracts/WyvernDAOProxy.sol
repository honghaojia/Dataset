pragma solidity ^0.4.13;
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner); // Emit after constructor
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner); // Emit before changing ownership
        owner = newOwner;
    }
}
contract ERC20Basic {
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}
contract ERC20 is ERC20Basic {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}
contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

    function receiveApproval(address from, uint256 value, address token, bytes extraData) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, this, value));
        emit ReceivedTokens(from, value, token, extraData); // Emit after receiving tokens
    }

    function () payable public {
        emit ReceivedEther(msg.sender, msg.value); // Emit on receiving Ether
    }
}
contract DelegateProxy is TokenRecipient, Ownable {
    function delegateProxy(address dest, bytes calldata)
        public
        onlyOwner
        returns (bool result) 
    {
        return dest.delegatecall(calldata);
    }

    function delegateProxyAssert(address dest, bytes calldata)
        public 
    {
        require(delegateProxy(dest, calldata));
    }
}
contract WyvernDAOProxy is DelegateProxy {
    function WyvernDAOProxy()
        public 
    {
        owner = msg.sender; 
        emit OwnershipTransferred(address(0), owner); // Emit after constructor
    }
}
