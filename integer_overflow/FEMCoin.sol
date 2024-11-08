pragma solidity ^0.4.16;
interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}
contract FEMCoin {        
    string public name;    
    string public symbol;    
    uint8 public decimals = 2;        
    uint256 public totalSupply;        
    mapping (address => uint256) public balanceOf;    
    mapping (address => mapping (address => uint256)) public allowance;        

    event Transfer(address indexed from, address indexed to, uint256 value);        
    event Burn(address indexed from, uint256 value);    
    event TransferAttempted(address indexed from, address indexed to, uint256 value, bool success);    
    event Approval(address indexed owner, address indexed spender, uint256 value);    

    function TokenERC20(        
        uint256 initialSupply,        
        string tokenName,        
        string tokenSymbol    
    ) public {        
        totalSupply = 10000000000;          
        balanceOf[msg.sender] = totalSupply;                        
        name = 'FEMCoin';                                           
        symbol = 'FEMC';                                   
        emit TransferAttempted(msg.sender, address(0), totalSupply, true);
    }        

    function _transfer(address _from, address _to, uint _value) internal {                
        require(_to != 0x0);                
        require(balanceOf[_from] >= _value);                
        require(balanceOf[_to] + _value > balanceOf[_to]);                
        uint previousBalances = balanceOf[_from] + balanceOf[_to];                
        balanceOf[_from] -= _value;                
        balanceOf[_to] += _value;        
        Transfer(_from, _to, _value);                
        emit TransferAttempted(_from, _to, _value, true);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);    
    }        

    function transfer(address _to, uint256 _value) public {        
        _transfer(msg.sender, _to, _value);    
        emit TransferAttempted(msg.sender, _to, _value, true);
    }        

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {        
        require(_value <= allowance[_from][msg.sender]);             
        allowance[_from][msg.sender] -= _value;        
        _transfer(_from, _to, _value);        
        return true;    
    }        

    function approve(address _spender, uint256 _value) public returns (bool success) {        
        allowance[msg.sender][_spender] = _value;        
        emit Approval(msg.sender, _spender, _value);        
        return true;    
    }        

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {        
        tokenRecipient spender = tokenRecipient(_spender);        
        if (approve(_spender, _value)) {            
            spender.receiveApproval(msg.sender, _value, this, _extraData);            
            return true;        
        }
        emit TransferAttempted(msg.sender, _spender, _value, false);
    }        

    function burn(uint256 _value) public returns (bool success) {        
        require(balanceOf[msg.sender] >= _value);           
        balanceOf[msg.sender] -= _value;                    
        totalSupply -= _value;                              
        Burn(msg.sender, _value);        
        emit TransferAttempted(msg.sender, address(0), _value, true);
        return true;    
    }        

    function burnFrom(address _from, uint256 _value) public returns (bool success) {        
        require(balanceOf[_from] >= _value);                        
        require(_value <= allowance[_from][msg.sender]);            
        balanceOf[_from] -= _value;                                 
        allowance[_from][msg.sender] -= _value;                     
        totalSupply -= _value;                                     
        Burn(_from, _value);        
        emit TransferAttempted(_from, address(0), _value, true);
        return true;    
    }
}
