/* 
http://platform.dao.casino 
For questions contact noxon i448539@gmail.com
*/

pragma solidity >=0.7.0;
//ide http://dapps.oraclize.it/browser-solidity/

// <ORACLIZE_API>
/*
Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016 Oraclize LTD



Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:



The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.



THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

interface OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string memory _datasource, string memory _arg) external payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string memory _datasource, string memory _arg, uint _gaslimit)external  payable returns (bytes32 _id);
    function query2(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2)external  payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _gaslimit)external  payable returns (bytes32 _id);
    function getPrice(string memory _datasource)external  returns (uint _dsprice);
    function getPrice(string memory _datasource, uint gaslimit)external  returns (uint _dsprice);
    function useCoupon(string memory _coupon)external ;
    function setProofType(bytes1 _proofType)external ;
    function setConfig(bytes32 _config)external ;
    function setCustomGasPrice(uint _gasPrice)external ;
}
interface OraclizeAddrResolverI {
    function getAddress() external returns (address _addr);
}
contract usingOraclize {
    uint constant day = 60*60*24;
    uint constant week = 60*60*24*7;
    uint constant month = 60*60*24*30;
    bytes1 constant proofType_NONE = 0x00;
    bytes1 constant proofType_TLSNotary = 0x10;
    bytes1 constant proofStorage_IPFS = 0x01;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_consensys = 161;

    OraclizeAddrResolverI OAR;
    
    OraclizeI oraclize;
    modifier oraclizeAPI {
        if(address(OAR)==address(0)) oraclize_setNetwork(networkID_auto);
        oraclize = OraclizeI(OAR.getAddress());
        _;
    }
    modifier coupon(string memory code){
        oraclize = OraclizeI(OAR.getAddress());
        oraclize.useCoupon(code);
        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
        if (getCodeSize(address(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed))>0){ //mainnet
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            return true;
        }
        if (getCodeSize(address(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1))>0){ //ropsten testnet
            OAR = OraclizeAddrResolverI(address(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1));
            return true;
        }
        if (getCodeSize(address(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF))>0){ //ether.camp ide
            OAR = OraclizeAddrResolverI(address(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF));
            return true;
        }
        if (getCodeSize(address(0x93BBBe5ce77034E3095F0479919962a903f898Ad))>0){ //norsborg testnet
            OAR = OraclizeAddrResolverI(address(0x93BBBe5ce77034E3095F0479919962a903f898Ad));
            return true;
        }
        if (getCodeSize(address(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA))>0){ //browser-solidity
            OAR = OraclizeAddrResolverI(address(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA));
            return true;
        }
        return false;
    }
    
    function __callback(bytes32 myid, string memory result) internal virtual{
        __callback(myid, result, new bytes(0));
    }
    function __callback(bytes32 myid, string memory result, bytes memory proof) internal{
    }
    
    function oraclize_getPrice(string memory datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }
    function oraclize_getPrice(string memory datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }
    
    function oraclize_query(string memory datasource, string memory arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query{value: price}(0, datasource, arg);
    }
    function oraclize_query(uint timestamp, string memory datasource, string memory arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query{value: price}(timestamp, datasource, arg);
    }
    function oraclize_query(uint timestamp, string memory datasource, string memory arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit{value:price}(timestamp, datasource, arg, gaslimit);
    }
    function oraclize_query(string memory datasource, string memory arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit{value: price}(0, datasource, arg, gaslimit);
    }
    function oraclize_query(string memory datasource, string memory arg1, string memory arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2{value: price}(0, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string memory datasource, string memory arg1, string memory arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2{value: price}(timestamp, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string memory datasource, string memory arg1, string memory arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit{value:price}(timestamp, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string memory datasource, string memory arg1, string memory arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit{value:price}(0, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }
    function oraclize_setProof(bytes1 proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }
    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }    
    function oraclize_setConfig(bytes32 config) oraclizeAPI internal {
        return oraclize.setConfig(config);
    }

    function getCodeSize(address _addr) view internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }


    function parseAddr(string memory _a) internal returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i+1]));
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }


    function strCompare(string memory _a, string memory _b) internal returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
   } 

    function indexOf(string memory _haystack, string memory _needle) internal returns (int)
    {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
            return -1;
        else if(h.length > (2**128 -1))
            return -1;                                  
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }   
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }   
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    // parseInt
    function parseInt(string memory _a) internal returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string memory _a, uint _b) internal returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((uint8(bresult[i]) >= 48)&&(uint8(bresult[i]) <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            } else if (uint8(bresult[i]) == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }
    
    function uint2str(uint i) internal returns (string memory){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = bytes1(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }
    
    

}
// </ORACLIZE_API>



contract HackDao is usingOraclize{
  
   struct Game {
	    address player;
	    bool results;
	    uint betsvalue;
	    uint betslevel;
	}
	
  mapping (bytes32 => address) bets;
  mapping (bytes32 => bool) public results; 
  mapping (bytes32 => uint) betsvalue;
  mapping (bytes32 => uint) betslevel;
  address public owner;
  
  
    
  constructor() {
      
      require(owner==address(0));
    owner = msg.sender;
    //oraclize_setNetwork(networkID_consensys);
    }
  
  modifier onlyOwner {
      require(msg.sender == owner);
        _;
    }
	
  event LogB(bytes32 h);
  event LogS(string s);
  event LogI(uint s);
    
	  function game (uint level) payable external returns (bytes32)  {
	   
              require(msg.value > 0);
              require(level <= 10);
              require(level >= 1);
	   
	   
	   //temprorary  disabled
	   /* 
	   if (level == 1 && msg.value < 0.99 ether) throw;
	   if (level == 2 && msg.value < 0.99 ether*1.09) throw;
	   if (level == 3 && msg.value < 0.99 ether*1.3298) throw;
	   if (level == 4 && msg.value < 0.99 ether*1.86172) throw;
	   if (level == 5 && msg.value < 0.99 ether*3.0346036) throw;
	   if (level == 6 && msg.value < 0.99 ether*5.947823056) throw;
	   if (level == 7 && msg.value < 0.99 ether*14.5721664872) throw;
	   if (level == 8 && msg.value < 0.99 ether*47.505262748272) throw;
	   if (level == 9 && msg.value < 0.99 ether*232.7757874665328) throw;
	   */
	  
	   
              require(msg.value <= 10 ether);
	   
  	   uint random_number;
           bytes32 myid;
  	   
	   if (msg.value < 5 ether) {
               myid = bytes32(keccak256(abi.encodePacked(msg.sender, block.blockhash(block.number - 1))));
    	    random_number = uint(block.blockhash(block.number-1))%10 + 1;
	   } else {
	        myid = oraclize_query("WolframAlpha", "random integer number between 1 and 10");
	   }
  	   
  	   bets[myid] = payable(msg.sender);
  	   betsvalue[myid] = msg.value; //-10000000000000000 ставка за вычитом расходов на оракула ~0.01 eth
  	   betslevel[myid] = level;
  	   
  	   if (random_number > 0) __callback(myid, uint2str(random_number),true);
  	  
  	   LogB(myid);
  	   
  	   
  	   return myid;
	  }
	 
	  function get_return_by_level(uint level) internal{
	      
	  }
	  

	  function __callback(bytes32 myid, string memory result) internal override{
	      __callback(myid, result, false);
	  }
	   
	  function __callback(bytes32 myid, string memory result, bool ishashranodm) internal {
        LogS('callback');
        require(msg.sender == oraclize_cbAddress() || ishashranodm);
       
        //log0(result);
      
        //TODO alex bash

        
        LogB(myid);
        
        if (parseInt(result) > betslevel[myid]) {
            LogS("win");
            LogI(betslevel[myid]);
            uint koef;
            if (betslevel[myid] == 1) koef = 109; //90
            if (betslevel[myid] == 2) koef = 122; //80
            if (betslevel[myid] == 3) koef = 140; //70
            if (betslevel[myid] == 4) koef = 163; //
            if (betslevel[myid] == 5) koef = 196;
            if (betslevel[myid] == 6) koef = 245;
            if (betslevel[myid] == 7) koef = 326;
            if (betslevel[myid] == 8) koef = 490;
            if (betslevel[myid] == 9) koef = 980;
            
            if (!(payable(bets[myid])).send(betsvalue[myid]*koef/100)) {LogS("bug! bet to winner was not sent!");} else {
                //LogI();
              }
            results[myid] = true;
        } else {
                
            LogS("lose");
            results[myid] = false;
        }
        
      }
      
      
      function ownerDeposit() external payable onlyOwner  {
        
      }
      
      function ownerWithdrawl() external onlyOwner  {
        owner.send(this.balance);
      }
    
}
