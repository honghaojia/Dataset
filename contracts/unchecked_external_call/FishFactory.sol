pragma solidity ^0.4.11;
contract Ownable {
    address owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
contract SharkProxy is Ownable {
    event Deposit(address indexed sender, uint256 value);
    event Withdrawal(address indexed to, uint256 value, bytes data);
    
    function SharkProxy() {
        owner = msg.sender;
    }

    function getOwner() constant returns (address) {
        return owner;
    }

    function forward(address _destination, uint256 _value, bytes _data) onlyOwner {
        require(_destination != address(0));
        assert(_destination.call.value(_value)(_data));
        
        if (_value > 0) {
            emit Withdrawal(_destination, _value, _data);
        } else {
            emit Withdrawal(_destination, 0, _data);
        }
    }

    function() payable {
        emit Deposit(msg.sender, msg.value);
    }

    function tokenFallback(address _from, uint _value, bytes _data) {
    }
}
contract FishProxy is SharkProxy {
    address lockAddr;

    event Unlock(address indexed newOwner);

    function FishProxy(address _owner, address _lockAddr) {
        owner = _owner;
        lockAddr = _lockAddr;
    }

    function isLocked() constant returns (bool) {
        return lockAddr != 0x0;
    }

    function unlock(bytes32 _r, bytes32 _s, bytes32 _pl) {
        assert(lockAddr != 0x0);

        uint8 v;
        uint88 target;
        address newOwner;

        assembly {
            v := calldataload(37)
            target := calldataload(48)
            newOwner := calldataload(68)
        }

        assert(target == uint88(address(this)));
        assert(newOwner == msg.sender);
        assert(newOwner != owner);
        assert(ecrecover(sha3(uint8(0), target, newOwner), v, _r, _s) == lockAddr);
        
        owner = newOwner;
        lockAddr = 0x0;
        emit Unlock(newOwner);
    }

    function() payable {
        assert(lockAddr == address(0) || this.balance <= 1e17);
        emit Deposit(msg.sender, msg.value);
    }
}
contract FishFactory {
    event AccountCreated(address proxy);

    function create(address _owner, address _lockAddr) {
        address proxy = new FishProxy(_owner, _lockAddr);
        emit AccountCreated(proxy);
    }
}
