pragma solidity >0.7.0;

interface ERC20Constant {
    function totalSupply() external view returns (uint supply);
    function balanceOf( address who ) external view returns (uint value);
    function allowance(address owner, address spender) external view returns (uint _allowance);
}
interface ERC20Stateful {
    function transfer( address to, uint value) external returns (bool ok);
    function transferFrom( address from, address to, uint value) external returns (bool ok);
    function approve(address spender, uint value) external returns (bool ok);
}
interface ERC20Events {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

abstract contract ERC20 is ERC20Constant, ERC20Stateful, ERC20Events {}

contract ERC20Base is ERC20
{
    mapping( address => uint ) _balances;
    mapping( address => mapping( address => uint ) ) _approvals;
    uint _supply;
    constructor( uint initial_balance ) {
        _balances[msg.sender] = initial_balance;
        _supply = initial_balance;
    }
    function totalSupply() external view returns (uint supply) {
        return _supply;
    }
    function balanceOf( address who ) external view returns (uint value) {
        return _balances[who];
    }
    function transfer( address to, uint value) external override returns (bool ok) {
        require(_balances[msg.sender] >= value);
        require(safeToAdd(_balances[to], value));
        _balances[msg.sender] -= value;
        _balances[to] += value;
        emit Transfer( msg.sender, to, value );
        return true;
    }
    function transferFrom( address from, address to, uint value) external override returns (bool ok) {
        // if you don't have enough balance, throw
        require(_balances[from] >= value);
        // if you don't have approval, throw
        require(_approvals[from][msg.sender] >= value);
        require(safeToAdd(_balances[to], value));
        // transfer and return true
        _approvals[from][msg.sender] -= value;
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer( from, to, value );
        return true;
    }
    function approve(address spender, uint value) external override returns (bool ok) {
        _approvals[msg.sender][spender] = value;
        emit Approval( msg.sender, spender, value );
        return true;
    }
    function allowance(address owner, address spender) external override view returns (uint _allowance) {
        return _approvals[owner][spender];
    }
    function safeToAdd(uint a, uint b) internal pure returns (bool) {
        return (a + b >= a);
    }
}

contract Token is ERC20Base(1000000000) {
    
    string public name = "SNGLS Test Token";
    string public symbol = "SNGLS";
    uint public decimals = 0;

}
