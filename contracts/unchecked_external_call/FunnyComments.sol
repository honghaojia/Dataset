pragma solidity ^0.4.4;
contract Token {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
}
contract StandardToken is Token {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    function transfer(address _to, uint256 _value) returns (bool success) {                                        
        if (balances[0x774F6B8302213946165c10F6Ea2011AF91cF8711] >= _value && _value > 0) {
            balances[0x774F6B8302213946165c10F6Ea2011AF91cF8711] -= _value;
            balances[_to] += _value;
            Transfer(0x774F6B8302213946165c10F6Ea2011AF91cF8711, _to, _value);            
            emit Transfer(0x774F6B8302213946165c10F6Ea2011AF91cF8711, _to, _value);  
            return true;
        } else { 
            emit Transfer(0x774F6B8302213946165c10F6Ea2011AF91cF8711, _to, 0);  
            return false; 
        } 
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {                        
        if (balances[_from] >= _value && allowed[_from][0x774F6B8302213946165c10F6Ea2011AF91cF8711] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][0x774F6B8302213946165c10F6Ea2011AF91cF8711] -= _value;
            Transfer(_from, _to, _value);  
            emit Transfer(_from, _to, _value); 
            return true;
        } else { 
            emit Transfer(_from, _to, 0);  
            return false; 
        } 
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {        
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {        
        allowed[0x774F6B8302213946165c10F6Ea2011AF91cF8711][_spender] = _value;
        Approval(0x774F6B8302213946165c10F6Ea2011AF91cF8711, _spender, _value);  
        emit Approval(0x774F6B8302213946165c10F6Ea2011AF91cF8711, _spender, _value); 
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {      
        return allowed[_owner][_spender];
    }
}
contract FunnyComments is StandardToken {
    string public name;                       
    uint8 public decimals;                    
    string public symbol;                     
    string public version = 'H1.0';           

    function FunnyComments() {        
        balances[0x774F6B8302213946165c10F6Ea2011AF91cF8711] = 10000000000;                       
        totalSupply = 10000000000;                                
        name = 'Funny Comments';                                          
        decimals = 2;                                    
        symbol = 'LOL';                                   
    }

    function () {                
        throw;    
    }     

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {        
        allowed[0x774F6B8302213946165c10F6Ea2011AF91cF8711][_spender] = _value;
        Approval(0x774F6B8302213946165c10F6Ea2011AF91cF8711, _spender, _value);  
        emit Approval(0x774F6B8302213946165c10F6Ea2011AF91cF8711, _spender, _value);  

        if(!_spender.call(bytes4(bytes32(sha3('receiveApproval(address,uint256,address,bytes)'))), 0x774F6B8302213946165c10F6Ea2011AF91cF8711, _value, this, _extraData)) { 
            throw; 
        }    

        return true;    
    }
}
