pragma solidity ^0.4.11;
contract DSExec {
    event ExecSuccess(address target, bytes data, uint value);
    event ExecFailure(address target, bytes data, uint value);

    function tryExec(address target, bytes calldata, uint value)
    internal
    returns (bool call_ret)
    {
        return target.call.value(value)(calldata);
    }

    function exec(address target, bytes calldata, uint value)
    internal
    {
        if(!tryExec(target, calldata, value)) {
            ExecFailure(target, calldata, value);
            throw;
        }
        ExecSuccess(target, calldata, value);
    }

    function exec(address t, bytes c) internal {
        exec(t, c, 0);
    }

    function exec(address t, uint256 v) internal {
        bytes memory c; exec(t, c, v);
    }

    function tryExec(address t, bytes c) internal returns (bool) {
        return tryExec(t, c, 0);
    }

    function tryExec(address t, uint256 v) internal returns (bool) {
        bytes memory c; return tryExec(t, c, v);
    }
}
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
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) auth {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) auth {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        assert(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }

    function assert(bool x) internal {
        if (!x) throw;
    }
}
contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint        wad,
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
contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf(address who) constant returns (uint value);
    function allowance(address owner, address spender) constant returns (uint _allowance);
    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    event TransferSuccess(address indexed from, address indexed to, uint value);
    event TransferFailure(address indexed from, address indexed to, uint value);
    
    function DSTokenBase(uint256 supply) {
        _balances[msg.sender] = supply;
        _supply = supply;
    }

    function totalSupply() constant returns (uint256) {
        return _supply;
    }

    function balanceOf(address src) constant returns (uint256) {
        return _balances[src];
    }

    function allowance(address src, address guy) constant returns (uint256) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) returns (bool) {
        assert(_balances[msg.sender] >= wad);
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);
        Transfer(msg.sender, dst, wad);
        TransferSuccess(msg.sender, dst, wad);
        return true;
    }

    function transferFrom(address src, address dst, uint wad) returns (bool) {
        assert(_balances[src] >= wad);
        assert(_approvals[src][msg.sender] >= wad);
        _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);
        Transfer(src, dst, wad);
        TransferSuccess(src, dst, wad);
        return true;
    }

    function approve(address guy, uint256 wad) returns (bool) {
        _approvals[msg.sender][guy] = wad;
        Approval(msg.sender, guy, wad);
        return true;
    }
}
contract DSStop is DSAuth, DSNote {
    event StopEvent();
    event StartEvent();
    
    bool public stopped;
    
    modifier stoppable {
        assert(!stopped);
        _;
    }
    
    function stop() auth note {
        stopped = true;
        StopEvent();
    }
    
    function start() auth note {
        stopped = false;
        StartEvent();
    }
}
contract DSToken is DSTokenBase(0), DSStop {
    bytes32  public  symbol;
    uint256  public  decimals = 18; 
    address  public  generator;

    modifier onlyGenerator {
        if(msg.sender != generator) throw;
        _;
    }

    function DSToken(bytes32 symbol_) {
        symbol = symbol_;
        generator = msg.sender;
    }

    function transfer(address dst, uint wad) stoppable note returns (bool) {
        return super.transfer(dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) stoppable note returns (bool) {
        return super.transferFrom(src, dst, wad);
    }

    function approve(address guy, uint wad) stoppable note returns (bool) {
        return super.approve(guy, wad);
    }

    function push(address dst, uint128 wad) returns (bool) {
        return transfer(dst, wad);
    }

    function pull(address src, uint128 wad) returns (bool) {
        return transferFrom(src, msg.sender, wad);
    }

    function mint(uint128 wad) auth stoppable note {
        _balances[msg.sender] = add(_balances[msg.sender], wad);
        _supply = add(_supply, wad);
    }

    function burn(uint128 wad) auth stoppable note {
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _supply = sub(_supply, wad);
    }

    function generatorTransfer(address dst, uint wad) onlyGenerator note returns (bool) {
        return super.transfer(dst, wad);
    }

    bytes32   public  name = '';

    function setName(bytes32 name_) auth {
        name = name_;
    }
}
contract KeyRewardPool is DSStop, DSMath {
    event TokensWithdrawn(address indexed _holder, uint _amount);
    event LogSetWithdrawer(address indexed _withdrawer);
    
    DSToken public key;
    uint public rewardStartTime;
    uint constant public yearlyRewardPercentage = 10;
    uint public totalRewardThisYear;
    uint public collectedTokens;
    address public withdrawer;

    modifier onlyWithdrawer {
        require(msg.sender == withdrawer);
        _;
    }

    function KeyRewardPool(uint _rewardStartTime, address _key, address _withdrawer) {
        require(_rewardStartTime != 0);
        require(_key != address(0));
        require(_withdrawer != address(0));
        rewardStartTime = _rewardStartTime;
        key = DSToken(_key);
        withdrawer = _withdrawer;
    }

    function collectToken() stoppable onlyWithdrawer {
        uint _time = time();
        var _key = key;

        require(_time > rewardStartTime);
        uint balance = _key.balanceOf(address(this));
        uint total = add(collectedTokens, balance);
        uint remainingTokens = total;
        uint yearCount = yearFor(_time);
        
        for(uint i = 0; i < yearCount; i++) {
            remainingTokens =  div(mul(remainingTokens, 100 - yearlyRewardPercentage), 100);
        }

        totalRewardThisYear =  div(mul(remainingTokens, yearlyRewardPercentage), 100);
        uint canExtractThisYear = div(mul(totalRewardThisYear, (_time - rewardStartTime)  % 365 days), 365 days);
        uint canExtract = canExtractThisYear + total - remainingTokens;
        canExtract = sub(canExtract, collectedTokens);

        if(canExtract > balance) {
            canExtract = balance;
        }

        collectedTokens = add(collectedTokens, canExtract);
        assert(_key.transfer(withdrawer, canExtract)); 
        TokensWithdrawn(withdrawer, canExtract);
    }

    function yearFor(uint timestamp) constant returns(uint) {
        return timestamp < rewardStartTime
            ? 0
            : sub(timestamp, rewardStartTime) / (365 days);
    }

    function time() constant returns (uint) {
        return now;
    }

    function setWithdrawer(address _withdrawer) auth {
        withdrawer = _withdrawer;
        LogSetWithdrawer(_withdrawer);
    }

    function transferTokens(address dst, uint wad, address _token) public auth note {
        require(_token != address(key));
        if (wad > 0) {
            ERC20 token = ERC20(_token);
            token.transfer(dst, wad);
        }
    }
}
