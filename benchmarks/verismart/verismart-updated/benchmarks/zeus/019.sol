/**
 * The Edgeless token contract complies with the ERC20 standard (see https://github.com/ethereum/EIPs/issues/20).
 * Additionally tokens can be locked for a defined time interval by token holders.
 * The owner's share of tokens is locked for the first year and all tokens not
 * being sold during the crowdsale but 60.000.000 (owner's share + bounty program) are burned.
 * Author: Julia Altenried
 * 
 * WARN: replace year to 365 days, just to make compilation pass
 * */


pragma solidity >=0.7.0;
contract SafeMath {
  //internals

  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

contract EdgelessToken is SafeMath {
    /* Public variables of the token */
    string public standard = 'ERC20';
    string public name = 'Edgeless';
    string public symbol = 'EDG';
    uint8 public decimals = 0;
    uint256 public totalSupply;
    address public owner;
    /* from this time on tokens may be transfered (after ICO)*/
    uint256 public startTime = 1490112000;
    /* tells if tokens have been burned already */
    bool burned;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
	event Burned(uint amount);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() {
        owner = address(0x003230BBE64eccD66f62913679C8966Cf9F41166);
        balanceOf[owner] = 500000000;              // Give the owner all initial tokens
        totalSupply = 500000000;                   // Update total supply
    }

    /* Send some of your tokens to a given address */
    function transfer(address _to, uint256 _value) external returns (bool success){
        require(block.timestamp >= startTime) ; //check if the crowdsale is already over
        //prevent the owner of spending his share of tokens within the first year
        require(msg.sender != owner || block.timestamp >= startTime + 365 days || safeSub(balanceOf[msg.sender],_value) > 50000000);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender],_value);                     // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    /* Allow another contract or person to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    /* A contract or  person attempts to get the tokens of somebody else.
    *  This is only allowed if the token holder approved. */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        if (_from!=owner){
            require(block.timestamp >= startTime, "the crowdsale is already over" ); //check if the crowdsale is already over            
        }
        //prevent the owner of spending his share of tokens within the first year
        require(_from != owner || block.timestamp >= startTime + 365 days || safeSub(balanceOf[_from],_value) >= 50000000);
        uint256 _allowance = allowance[_from][msg.sender];
        balanceOf[_from] = safeSub(balanceOf[_from],_value); // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);     // Add the same to the recipient
        allowance[_from][msg.sender] = safeSub(_allowance,_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


    /* to be called when ICO is closed, burns the remaining tokens but the owners share (50 000 000) and the ones reserved
    *  for the bounty program (10 000 000).
    *  anybody may burn the tokens after ICO ended, but only once (in case the owner holds more tokens in the future).
    *  this ensures that the owner will not posses a majority of the tokens. */
    function burn() external {
    	//if tokens have not been burned already and the ICO ended
    	if(!burned && block.timestamp>startTime){
    		uint difference = safeSub(balanceOf[owner], 60000000);//checked for overflow above
    		balanceOf[owner] = 60000000;
    		totalSupply = safeSub(totalSupply, difference);
    		burned = true;
    		emit Burned(difference);
    	}
    }

}
