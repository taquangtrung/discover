pragma solidity >=0.7.0;
// ----------------------------------------------------------------------------------------------
// A collaboration between Incent and Bok :)
// Enjoy. (c) Incent Loyalty Pty Ltd, and Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------------------------

//config contract
contract TokenConfig {

    string public constant name = "Incent Coffee Token";
    string public constant symbol = "INCOF";
    uint8 public constant decimals = 0;  // 0 decimal places, the same as tokens on Wave
    uint256 _totalSupply = 824;

}


// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
interface ERC20Interface {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract IncentCoffeeToken is ERC20Interface, TokenConfig {

    // Owner of this contract
    address public owner;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    // Constructor
    constructor() {

        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) external override view returns (uint256 balance) {
        return balances[_owner];
    }

    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount) public override returns (bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
           return false;
        }
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external override returns (bool success) {

        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {

            balances[_to] += _amount;
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) external override returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


}

contract WavesEthereumSwap is IncentCoffeeToken {

 event WavesTransfer(address indexed _from, string wavesAddress, uint256 amount);

 function moveToWaves(string memory wavesAddress, uint256 amount) external {

     require (transfer(owner, amount)) ;
     emit WavesTransfer(msg.sender, wavesAddress, amount);

 }

}
