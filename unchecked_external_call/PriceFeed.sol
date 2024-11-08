pragma solidity ^0.4.17;
contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}
contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}
contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    event AuthOwnerSet(address indexed newOwner);
    event AuthAuthoritySet(address indexed newAuthority);

    function DSAuth() public {
        owner = msg.sender;
        LogSetOwner(msg.sender);
        emit AuthOwnerSet(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
        emit AuthOwnerSet(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
        emit AuthAuthoritySet(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            emit AuthOwnerSet(src);
            return true;
        } else if (authority == DSAuthority(0)) {
            emit AuthAuthoritySet(address(0));
            return false;
        } else {
            bool canCall = authority.canCall(src, this, sig);
            emit AuthAuthoritySet(src);
            return canCall;
        }
    }
}
contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }
        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);
        _;
    }
}
contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }
    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
    
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;
        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);
            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}
contract DSThing is DSAuth, DSNote, DSMath {}
contract PriceFeed is DSThing {
    uint128 val;
    uint32 public zzz;

    event Peeked(bytes32 value, bool valid);
    event ReadCalled(bytes32 value);
    event Posted(uint128 value, uint32 expiration, address med);
    event Voided();

    function peek() public view 
        returns (bytes32,bool) 
    {
        emit Peeked(bytes32(val), now < zzz);
        return (bytes32(val), now < zzz);
    }

    function read() public view 
        returns (bytes32) 
    {
        assert(now < zzz);
        bytes32 value = bytes32(val);
        emit ReadCalled(value);
        return value;
    }

    function post(uint128 val_, uint32 zzz_, address med_) public note auth 
    {
        val = val_;
        zzz = zzz_;
        bool ret = med_.call(bytes4(keccak256('poke()')));
        emit Posted(val_, zzz_, med_);
        ret;
    }

    function void() public note auth 
    {
        zzz = 0;
        emit Voided();
    }
}