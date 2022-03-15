pragma solidity >=0.7.0;
contract owned {
  address public owner;
  constructor() {
    owner = msg.sender;
  }
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) external onlyOwner {
    owner = newOwner;
  }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) external; }

contract RTokenBase {
  /* contract info */
  string public standard = 'Token 0.1';
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  /* maintain a balance mapping of R tokens */
  mapping(address => uint256) public balanceMap;
  mapping(address => mapping(address => uint256)) public allowance;

  /* what to do on transfers */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /* Constructor */
  constructor(uint256 initialAmt, string memory tokenName, string memory tokenSymbol, uint8 decimalUnits) payable {
    balanceMap[msg.sender] = initialAmt;
    totalSupply = initialAmt;
    name = tokenName;
    symbol = tokenSymbol;
    decimals = decimalUnits;
  }

  /* send tokens */
  function transfer(address _to, uint256 _value) external virtual payable {
      require((balanceMap[msg.sender] >= _value) &&
              (balanceMap[_to] + _value >= balanceMap[_to])) ;
    balanceMap[msg.sender] -= _value;
    balanceMap[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
  }

  /* allow other contracts to spend tokens */
  function approve(address _spender, uint256 _value) external returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    tokenRecipient spender = tokenRecipient(_spender);
    return true;
  }

  /* approve and notify */
  function approveAndCall(address _spender, uint256 _value, bytes memory _stuff) external  returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);
    if(this.approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, address(this), _stuff);
      return true;
    }
  }

  /* do a transfer */
  function transferFrom(address _from, address _to, uint256 _value) payable external virtual returns (bool success) {
      require((balanceMap[_from] >= _value) &&
        (balanceMap[_to] + _value >= balanceMap[_to]) &&
        (_value <= allowance[_from][msg.sender]));
    balanceMap[_from] -= _value;
    balanceMap[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }


}

contract RTokenMain is owned, RTokenBase {
  uint256 public sellPrice;
  uint256 public buyPrice;

  mapping(address => bool) public frozenAccount;

  event FrozenFunds(address target, bool frozen);

  constructor(uint256 initialAmt, string memory tokenName, string memory tokenSymbol, uint8 decimals, address centralMinter)
    RTokenBase(initialAmt, tokenName, tokenSymbol, decimals) {
      if(centralMinter != address(0))
        owner = centralMinter;
      balanceMap[owner] = initialAmt;
    }

  function transfer(address _to, uint256 _value) external override payable {
      require((balanceMap[msg.sender] >= _value) &&
              (balanceMap[_to] + _value >= balanceMap[_to]) &&
              (!frozenAccount[msg.sender]));
    balanceMap[msg.sender] -= _value;
    balanceMap[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) payable external override returns (bool success) {
      require((!frozenAccount[_from]) &&
        (balanceMap[_from] >= _value) &&
        (balanceMap[_to] + _value >= balanceMap[_to]) &&
        (_value <= allowance[_from][msg.sender]));
    balanceMap[_from] -= _value;
    balanceMap[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function mintToken(address target, uint256 mintedAmount) external onlyOwner {
    balanceMap[target] += mintedAmount;
    totalSupply += mintedAmount;
    emit Transfer(address(0), address(this), mintedAmount);
    emit Transfer(address(this), target, mintedAmount);
  }

  function freezeAccount(address target, bool freeze) external onlyOwner {
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }

  function setPrices(uint256 newSellPrice, uint256 newBuyPrice) external onlyOwner {
    sellPrice = newSellPrice;
    buyPrice = newBuyPrice;
  }

  function buy() external payable {
    uint amount = msg.value/buyPrice;
    require(balanceMap[address(this)] >= amount);
    balanceMap[msg.sender] += amount;
    balanceMap[address(this)] -= amount;
    emit Transfer(address(this), msg.sender, amount);
  }

  function sell(uint256 amount) external {
    require(balanceMap[msg.sender] >= amount);
    balanceMap[msg.sender] -= amount;
    balanceMap[address(this)] += amount;
    require((payable(msg.sender)).send(amount*sellPrice));
    emit Transfer(msg.sender, address(this), amount);
  }
}
