pragma solidity ^0.4.13;
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferAttempted(address indexed attemptedOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
contract ERC20Basic {
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferAttempted(address indexed from, address indexed to, uint256 value);

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}
contract ERC20 is ERC20Basic {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ApprovalAttempted(address indexed owner, address indexed spender, uint256 value);

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
        emit ReceivedTokens(from, value, token, extraData);
    }

    function () payable public {
        emit ReceivedEther(msg.sender, msg.value);
    }
}
contract DelegateProxy is TokenRecipient, Ownable {
    event DelegateCallSuccess(address indexed dest);
    event DelegateCallFailure(address indexed dest);

    function delegateProxy(address dest, bytes calldata) public onlyOwner returns (bool result) {
        bool success = dest.delegatecall(calldata);
        if (success) {
            emit DelegateCallSuccess(dest);
        } else {
            emit DelegateCallFailure(dest);
        }
        return success;
    }

    function delegateProxyAssert(address dest, bytes calldata) public {
        require(delegateProxy(dest, calldata));
    }
}
contract WyvernDAOProxy is DelegateProxy {
    function WyvernDAOProxy () public {
        owner = msg.sender;
    }
}
