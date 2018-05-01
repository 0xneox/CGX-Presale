pragma solidity ^0.4.8;
// import "./StandardToken.sol";
import 'zeppelin-solidity/contracts/token/VestedToken.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract CGXToken is VestedToken {
	using SafeMath for uint;

	//FIELDS
	//CONSTANTS
	uint public constant decimals = 18;  // 18 decimal places, the same as ETH.
	string public constant name = "Cgcx Token";
  	string public constant symbol = "CGX";

	//ASSIGNED IN INITIALIZATION
	address public creator; //address of the account which may mint new tokens

	//May only be called by the owner address
	modifier only_owner() {
		if (msg.sender != creator) throw;
		_;
	}


	// Initialization contract assigns address of crowdfund contract and end time.
	function CGXToken(uint supply) {
		totalSupply = supply;
		creator = msg.sender;

		balances[msg.sender] = supply;

		MAX_GRANTS_PER_ADDRESS = 2;
	}

	// Fallback function throws when called.
	function() {
		throw;
	}

	function vestedBalanceOf(address _owner) constant returns (uint balance) {
	    return transferableTokens(_owner, uint64(now));
    }

        //failsafe drain
	function drain()
		only_owner
	{
		if (!creator.send(this.balance)) throw;
	}
}
