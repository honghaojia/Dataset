pragma solidity ^0.4.15;
contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            emit Transfer(msg.sender, address(0), _value); // Emit for failed transfer
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            emit Transfer(_from, address(0), _value); // Emit for failed transferFrom
            return false;
        }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}
contract GGoken is StandardToken {
    function () public payable {
        require(msg.value > 0 && receivedWei < targetWei);
        require(now > releaseTime);
        receivedWei += msg.value;
        walletAddress.transfer(msg.value);
        emit NewSale(msg.sender, msg.value);
        assert(receivedWei >= msg.value);
    }

    string public name = 'GG Token';
    uint8 public decimals = 18;
    string public symbol = 'GG';
    string public version = 'v0.1';
    address public founder;
    uint256 public targetWei;
    uint256 public receivedWei;
    uint256 public releaseTime;
    uint256 public allocateEndTime;
    address public walletAddress;
    event NewSale(address indexed _from, uint256 _amount);

    mapping(address => uint256) nonces;

    function GGoken(address _walletAddress) public {
        founder = msg.sender;
        walletAddress = _walletAddress;
        releaseTime = 1511695159;
        allocateEndTime = releaseTime + 1 days;
        targetWei = 2 ether;
    }

    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeGg,
        uint8 _v, bytes32 _r, bytes32 _s) public returns (bool) {
        if(balances[_from] < _feeGg + _value) revert();
        uint256 nonce = nonces[_from];
        bytes32 h = keccak256(_from, _to, _value, _feeGg, nonce);
        if(_from != ecrecover(h, _v, _r, _s)) revert();
        if(balances[_to] + _value < balances[_to] || balances[msg.sender] + _feeGg < balances[msg.sender]) revert();
        
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        balances[msg.sender] += _feeGg;
        emit Transfer(_from, msg.sender, _feeGg);
        balances[_from] -= _value + _feeGg;
        nonces[_from] = nonce + 1;
        return true;
    }

    function approveProxy(address _from, address _spender, uint256 _value,
        uint8 _v, bytes32 _r, bytes32 _s) public returns (bool success) {
        uint256 nonce = nonces[_from];
        bytes32 hash = keccak256(_from, _spender, _value, nonce);
        if(_from != ecrecover(hash, _v, _r, _s)) revert();
        allowed[_from][_spender] = _value;
        emit Approval(_from, _spender, _value);
        nonces[_from] = nonce + 1;
        return true;
    }

    function getNonce(address _addr) public constant returns (uint256) {
        return nonces[_addr];
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(keccak256('receiveApproval(address,uint256,address,bytes)'))), msg.sender, _value, this, _extraData)) {
            revert();
        }
        return true;
    }

    function approveAndCallcode(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        if(!_spender.call(_extraData)) {
            revert();
        }
        return true;
    }

    function allocateTokens(address[] _owners, uint256[] _values) public {
        if(msg.sender != founder) revert();
        if(allocateEndTime < now) revert();
        if(_owners.length != _values.length) revert();
        for(uint256 i = 0; i < _owners.length ; i++){
            address owner = _owners[i];
            uint256 value = _values[i];
            if(totalSupply + value <= totalSupply || balances[owner] + value <= balances[owner]) revert();
            totalSupply += value;
            balances[owner] += value;
        }
    }
}
