pragma solidity >=0.7.0;

contract TimeLockSend {
    address payable sender;
    address payable recipient;
    uint256 created;
    uint256 deadline;
    
    constructor(address payable _sender, address payable _recipient, uint256 _deadline) payable {
        require (msg.value > 0) ;
        sender = _sender;
        recipient = _recipient;
        created = block.timestamp;
        deadline = _deadline;
    }
    
    function withdraw() external {
        if (msg.sender == recipient) {
            selfdestruct(recipient);
        } else if (msg.sender == sender && block.timestamp > deadline) {
            selfdestruct(sender);
        } else {
            revert();
        }
    }
    
    // no longer required in newer version of solidty
    // function () {
    //     throw;
    // }
    fallback() external {
        revert();
    }    
}

contract SafeSender {
    address payable owner;
    
    event TimeLockSendCreated(
        address indexed sender, 
        address indexed recipient, 
        uint256 deadline,
        address safeSendAddress
    );
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    function safeSend(address recipient, uint256 timeLimit) external payable returns (address) {
        require(msg.value > 0 && (block.timestamp + timeLimit) > block.timestamp);
        uint256 deadline = block.timestamp + timeLimit;
        TimeLockSend newSend = (new TimeLockSend){value: msg.value}(payable(msg.sender), payable(recipient), deadline);
        require (address(newSend) != address(0)) ;
        emit TimeLockSendCreated(
            msg.sender,
            recipient,
            deadline,
            address(newSend)
        );
        return address(newSend);
    }
    
    function withdraw() external{
        require (msg.sender == owner) ;
        if (address(this).balance > 0){
            require(owner.send(address(this).balance));
        }
    }
    
    /* This unnamed function is called whenever someone tries to send ether to it */
    // function () {
    //     throw;     // Prevents accidental sending of ether
    // }
    fallback() external {
        revert();
    }    
}
