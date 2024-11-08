pragma solidity ^0.4.24;
contract ERC165 {
    bytes4 constant INTERFACE_ERC165 = 0x01ffc9a7;

    function supportsInterface(bytes4 _interfaceID) public pure returns (bool) {
        return _interfaceID == INTERFACE_ERC165;
    }
}
contract ERC721Basic {
    bytes4 constant INTERFACE_ERC721 = 0x80ac58cd;
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool indexed _approved);
    event BalanceOfChecked(address indexed _owner, uint256 _balance);
    event OwnerOfChecked(uint256 _tokenId, address indexed _owner);
    event ExistsChecked(uint256 _tokenId, bool _exists);
    event Approved(address indexed _to, uint256 _tokenId);
    event GetApprovedChecked(uint256 _tokenId, address indexed _operator);
    event ApprovalForAllSet(address indexed _operator, bool indexed _approved);
    event IsApprovedForAllChecked(address indexed _owner, address indexed _operator, bool _isApproved);
    event TransferFromExecuted(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event SafeTransferFromExecuted(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    function balanceOf(address _owner) public view returns (uint256 _balance) {
        // ... Logic for getting balance
        emit BalanceOfChecked(_owner, _balance);
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        // ... Logic for getting owner
        emit OwnerOfChecked(_tokenId, _owner);
    }

    function exists(uint256 _tokenId) public view returns (bool _exists) {
        // ... Logic for checking existence
        emit ExistsChecked(_tokenId, _exists);
    }

    function approve(address _to, uint256 _tokenId) public {
        // ... Logic for approval
        emit Approved(_to, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address _operator) {
        // ... Logic for getting approved
        emit GetApprovedChecked(_tokenId, _operator);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        // ... Logic for setting approval for all
        emit ApprovalForAllSet(_operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        // ... Logic for checking approval for all
        emit IsApprovedForAllChecked(_owner, _operator, true); // replace true with actual check
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        // ... Logic for transferring
        emit TransferFromExecuted(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        // ... Logic for safe transferring
        emit SafeTransferFromExecuted(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public {}
}
contract ERC721Enumerable is ERC721Basic {
    bytes4 constant INTERFACE_ERC721_ENUMERABLE = 0x780e9d63;

    function totalSupply() public view returns (uint256) {
        // ... Logic for total supply
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId) {
        // ... Logic for getting token by owner index
    }

    function tokenByIndex(uint256 _index) public view returns (uint256) {
        // ... Logic for getting token by index
    }
}
contract ERC721Metadata is ERC721Basic {
    bytes4 constant INTERFACE_ERC721_METADATA = 0x5b5e139f;

    function name() public view returns (string _name) {
        // ... Logic for getting name
    }

    function symbol() public view returns (string _symbol) {
        // ... Logic for getting symbol
    }

    function tokenURI(uint256 _tokenId) public view returns (string) {
        // ... Logic for getting token URI
    }
}
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {}
contract ProxyOwnable {
    address public proxyOwner;
    event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        proxyOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == proxyOwner);
        _;
    }

    function transferProxyOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit ProxyOwnershipTransferred(proxyOwner, _newOwner);
        proxyOwner = _newOwner;
    }
}
contract CodexRecordProxy is ProxyOwnable {
    event Upgraded(string version, address indexed implementation);
    string public version;
    address public implementation;

    constructor(address _implementation) public {
        upgradeTo('1', _implementation);
    }

    function () payable public {
        address _implementation = implementation;

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _implementation, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function name() external view returns (string) {
        ERC721Metadata tokenMetadata = ERC721Metadata(implementation);
        return tokenMetadata.name();
    }

    function symbol() external view returns (string) {
        ERC721Metadata tokenMetadata = ERC721Metadata(implementation);
        return tokenMetadata.symbol();
    }

    function upgradeTo(string _version, address _implementation) public onlyOwner {
        require(
            keccak256(abi.encodePacked(_version)) != keccak256(abi.encodePacked(version)),
            'The version cannot be the same'
        );
        require(
            _implementation != implementation,
            'The implementation cannot be the same'
        );
        require(
            _implementation != address(0),
            'The implementation cannot be the 0 address'
        );
        version = _version;
        implementation = _implementation;
        emit Upgraded(version, implementation);
    }
}
