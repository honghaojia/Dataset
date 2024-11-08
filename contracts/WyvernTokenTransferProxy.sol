pragma solidity ^0.4.13;
contract Ownable {  
    address public owner;  
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
    function balanceOf(address who) public view returns (uint256);  
    function transfer(address to, uint256 value) public returns (bool);  
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {  
    function allowance(address owner, address spender) public view returns (uint256);  
    function transferFrom(address from, address to, uint256 value) public returns (bool);  
    function approve(address spender, uint256 value) public returns (bool);  
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
contract AuthenticatedProxy is TokenRecipient {        
    address public user;        
    ProxyRegistry public registry;        
    bool public revoked;        
    enum HowToCall { Call, DelegateCall }        
    event Revoked(bool revoked);        

    function AuthenticatedProxy(address addrUser, ProxyRegistry addrRegistry) public {        
        user = addrUser;        
        registry = addrRegistry;    
    }        

    function setRevoke(bool revoke) public {        
        require(msg.sender == user);        
        revoked = revoke;        
        emit Revoked(revoke);    
    }        

    function proxy(address dest, HowToCall howToCall, bytes calldata) public returns (bool result) {        
        require(msg.sender == user || (!revoked && registry.contracts(msg.sender)));        
        if (howToCall == HowToCall.Call) {            
            result = dest.call(calldata);            
            emit Revoked(false);        
        } else if (howToCall == HowToCall.DelegateCall) {            
            result = dest.delegatecall(calldata);            
            emit Revoked(false);        
        }        
        return result;    
    }        

    function proxyAssert(address dest, HowToCall howToCall, bytes calldata) public {        
        require(proxy(dest, howToCall, calldata));    
    }
}
contract ProxyRegistry is Ownable {        
    mapping(address => AuthenticatedProxy) public proxies;        
    mapping(address => uint) public pending;        
    mapping(address => bool) public contracts;        
    uint public DELAY_PERIOD = 2 weeks;        

    function startGrantAuthentication(address addr) public onlyOwner {        
        require(!contracts[addr] && pending[addr] == 0);        
        pending[addr] = now;    
    }        

    function endGrantAuthentication(address addr) public onlyOwner {        
        require(!contracts[addr] && pending[addr] != 0 && ((pending[addr] + DELAY_PERIOD) < now));        
        pending[addr] = 0;        
        contracts[addr] = true;    
    }            

    function revokeAuthentication(address addr) public onlyOwner {        
        contracts[addr] = false;    
    }        

    function registerProxy() public returns (AuthenticatedProxy proxy) {        
        require(proxies[msg.sender] == address(0));        
        proxy = new AuthenticatedProxy(msg.sender, this);        
        proxies[msg.sender] = proxy;        
        return proxy;    
    }
}
contract TokenTransferProxy {        
    ProxyRegistry public registry;        

    function transferFrom(address token, address from, address to, uint amount) public returns (bool) {        
        require(registry.contracts(msg.sender));        
        return ERC20(token).transferFrom(from, to, amount);    
    }
}
contract WyvernTokenTransferProxy is TokenTransferProxy {    
    function WyvernTokenTransferProxy(ProxyRegistry registryAddr) public {        
        registry = registryAddr;    
    }
}
