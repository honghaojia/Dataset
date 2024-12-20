pragma solidity ^0.4.15;
contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) constant returns (bool);
}
contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}
contract DSAuth is DSAuthEvents {
    event AuthoritySet(address indexed authority);
    event OwnerSet(address indexed owner);

    DSAuthority public authority;
    address public owner;

    function DSAuth() {
        owner = msg.sender;
        LogSetOwner(msg.sender);
        emit OwnerSet(msg.sender);
    }

    function setOwner(address owner_) auth {
        owner = owner_;
        LogSetOwner(owner);
        emit OwnerSet(owner);
    }

    function setAuthority(DSAuthority authority_) auth {
        authority = authority_;
        LogSetAuthority(authority);
        emit AuthoritySet(authority);
    }

    modifier auth {
        assert(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal returns (bool) {
        if (src == address(this)) {
            emit AuthoritySet(address(this));
            return true;
        } else if (src == owner) {
            emit AuthoritySet(owner);
            return true;
        } else if (authority == DSAuthority(0)) {
            emit AuthoritySet(DSAuthority(0));
            return false;
        } else {
            bool result = authority.canCall(src, this, sig);
            emit AuthoritySet(result ? authority : DSAuthority(0));
            return result;
        }
    }
}
contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 indexed bar,
        uint wad,
        bytes fax
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
    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x * y;
        assert(x == 0 || z / x == y);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }

    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x * y;
        assert(x == 0 || z / x == y);
    }

    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }

    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }

    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
        z = n % 2 != 0 ? x : RAY;
        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);
            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }

    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }
}
contract DSThing is DSAuth, DSNote, DSMath {}
contract DSPrice is DSThing {
    event PricePeeked(bytes32 val, bool available);
    event PriceRead(bytes32 val);
    event PricePosted(uint128 val, uint32 zzz);
    event PriceVoided();

    uint128 public val;
    uint32 public zzz;

    function peek() constant returns (bytes32, bool) {
        emit PricePeeked(bytes32(val), now < zzz);
        return (bytes32(val), now < zzz);
    }

    function read() constant returns (bytes32) {
        assert(now < zzz);
        emit PriceRead(bytes32(val));
        return bytes32(val);
    }

    function post(uint128 val_, uint32 zzz_, address med_) note auth {
        val = val_;
        zzz = zzz_;
        med_.call(bytes4(sha3('poke()')));
        emit PricePosted(val_, zzz_);
    }

    function void() note auth {
        zzz = 0;
        emit PriceVoided();
    }
}
