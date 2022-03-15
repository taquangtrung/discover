pragma solidity >=0.7.0;
contract MyToken {
    /* Public variables of the token */
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor () {
        totalSupply = 10000;
        balanceOf[msg.sender] = totalSupply;              // Give the creator all initial tokens
        name = "megabank";                                   // Set the name for display purposes
        symbol = "xUSD";                               // Set the symbol for display purposes
        decimals = 0;                            // Amount of decimals for display purposes
    }

    /* Send coins */ 
    
    function transfer(address _to, uint256 _value) public {
        require (balanceOf[msg.sender] >= _value) ;           // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        //Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }


    /* This unnamed function is called whenever someone tries to send ether to it */
    // no longer required in newer version of solidty
    // function () {
    //     throw;     // Prevents accidental sending of ether
    // }

    fallback() external {
        revert();
    }

}
