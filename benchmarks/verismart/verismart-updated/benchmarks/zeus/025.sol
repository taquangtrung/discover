pragma solidity >=0.7.0;
contract testingToken {
	mapping (address => uint256) public balanceOf;
	address public owner;
	constructor() {
		owner = msg.sender;
		balanceOf[msg.sender] = 1000;
	}
	function send(address _to, uint256 _value) external {
            require(balanceOf[msg.sender]>=_value);
            require(balanceOf[_to]+_value>=balanceOf[_to]);
            require(_value>=0);
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
	}
}
