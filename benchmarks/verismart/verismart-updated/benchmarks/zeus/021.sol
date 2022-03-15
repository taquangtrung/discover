contract owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner external {
        owner = newOwner;
    }
}

interface tokenRecipient { function sendApproval(address _from, uint256 _value, address _token) external; }

contract MyToken is owned { 
    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;
	uint8 public disableconstruction;
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyTokenLoad(uint256 initialSupply, string memory tokenName, uint8 decimalUnits, string memory tokenSymbol, address centralMinter) internal {
		if(disableconstruction != 2){
                    if(centralMinter != address(0) ) owner = msg.sender;         // Sets the minter
            balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens                    
            name = tokenName;                                   // Set the name for display purposes     
            symbol = tokenSymbol;                               // Set the symbol for display purposes    
            decimals = decimalUnits;                            // Amount of decimals for display purposes        
		}
    }
    constructor(){
        MyTokenLoad(10000000000000,'Kraze',8,'KRZ',address(0));
		disableconstruction=2;
    }
    /* Send coins */
    function transfer(address _to, uint256 _value) external {
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough   
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient            
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    // function () {
    //     throw;     // Prevents accidental sending of ether
    // }
    fallback() external {
        revert();
    }
}
