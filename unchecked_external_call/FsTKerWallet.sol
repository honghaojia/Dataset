pragma solidity ^0.4.24;
contract ERC {
    function balanceOf(address) public view returns (uint256);
    function allowance(address, address) public view returns (uint256);
    function transfer(address, uint256) public returns (bool);
    function transferFrom(address, address, uint256) public returns (bool);
    function transferAndCall(address, uint256, bytes) public payable returns (bool);
    function approve(address, uint256) public returns (bool);
}
contract FsTKerWallet {
    string constant public walletVersion = 'v1.0.0';
    ERC public FST;
    address public owner;
    bytes32 public secretHash;
    uint256 public sn;

    event ETHTransferred(address indexed to, uint256 value);
    event MoreETHTransferred(address indexed to, uint256 value);
    event FSTTransferred(address indexed to, uint256 value);
    event ERCTransferred(address indexed erc, address indexed to, uint256 value);
    event FSTTransferredFrom(address indexed from, address indexed to, uint256 value);
    event ERCTransferredFrom(address indexed erc, address indexed from, address indexed to, uint256 value);
    event FSTTransferAndCall(address indexed to, uint256 value, bytes data);
    event ERCTransferAndCall(address indexed erc, address indexed to, uint256 value, bytes data);
    event FSTApproved(address indexed spender, uint256 value);
    event ERCApproved(address indexed erc, address indexed spender, uint256 value);
    event SecretHashRecovered(address indexed owner, bytes32 newSecretHash);
    event FSTSet(address indexed newFST);
    event ContractCalled(address indexed to, bytes data);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(ERC _FST, bytes32 _secretHash, uint256 _sn) public {
        FST = _FST;
        secretHash = _secretHash;
        sn = _sn;
    }

    function getFSTBalance() public view returns (uint256) {
        return FST.balanceOf(address(this));
    }

    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getERCBalance(ERC erc) public view returns (uint256) {
        return erc.balanceOf(address(this));
    }

    function transferETH(address _to, uint256 _value) onlyOwner public returns (bool) {
        _to.transfer(_value);
        emit ETHTransferred(_to, _value);
        return true;
    }

    function transferMoreETH(address _to, uint256 _value) onlyOwner payable public returns (bool) {
        _to.transfer(_value);
        emit MoreETHTransferred(_to, _value);
        return true;
    }

    function transferFST(address _to, uint256 _value) onlyOwner public returns (bool) {
        bool success = FST.transfer(_to, _value);
        emit FSTTransferred(_to, _value);
        return success;
    }

    function transferERC(ERC erc, address _to, uint256 _value) onlyOwner public returns (bool) {
        bool success = erc.transfer(_to, _value);
        emit ERCTransferred(address(erc), _to, _value);
        return success;
    }

    function transferFromFST(address _from, address _to, uint256 _value) onlyOwner public returns (bool) {
        bool success = FST.transferFrom(_from, _to, _value);
        emit FSTTransferredFrom(_from, _to, _value);
        return success;
    }

    function transferFromERC(ERC erc, address _from, address _to, uint256 _value) onlyOwner public returns (bool) {
        bool success = erc.transferFrom(_from, _to, _value);
        emit ERCTransferredFrom(address(erc), _from, _to, _value);
        return success;
    }

    function transferAndCallFST(address _to, uint256 _value, bytes _data) onlyOwner payable public returns (bool) {
        require(FST.transferAndCall.value(msg.value)(_to, _value, _data));
        emit FSTTransferAndCall(_to, _value, _data);
        return true;
    }

    function transferAndCallERC(ERC erc, address _to, uint256 _value, bytes _data) onlyOwner payable public returns (bool) {
        require(erc.transferAndCall.value(msg.value)(_to, _value, _data));
        emit ERCTransferAndCall(address(erc), _to, _value, _data);
        return true;
    }

    function approveFST(address _spender, uint256 _value) onlyOwner public returns (bool) {
        bool success = FST.approve(_spender, _value);
        emit FSTApproved(_spender, _value);
        return success;
    }

    function approveERC(ERC erc, address _spender, uint256 _value) onlyOwner public returns (bool) {
        bool success = erc.approve(_spender, _value);
        emit ERCApproved(address(erc), _spender, _value);
        return success;
    }

    function recoverAndSetSecretHash(string _secret, bytes32 _newSecretHash) public returns (bool) {
        require(_newSecretHash != bytes32(0));
        require(keccak256(abi.encodePacked(_secret)) == secretHash);
        owner = msg.sender;
        secretHash = _newSecretHash;
        emit SecretHashRecovered(owner, _newSecretHash);
        return true;
    }

    function setFST(ERC _FST) onlyOwner public returns (bool) {
        require(address(_FST) != address(this) && address(_FST) != address(0x0));
        FST = _FST;
        emit FSTSet(address(_FST));
        return true;
    }

    function callContract(address to, bytes data) onlyOwner public payable returns (bool) {
        require(to.call.value(msg.value)(data));
        emit ContractCalled(to, data);
        return true;
    }

    function () external payable {}
}
