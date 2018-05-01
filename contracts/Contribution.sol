pragma solidity ^0.4.8;

import "./CGXToken.sol";
// import "./SafeMath.sol";
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract Contribution /*is SafeMath*/ {
	using SafeMath for uint;

	uint public constant decimals = 18;  // 18 decimal places, the same as ETH.

	//CONSTANTS
	//Time limits
	uint public constant STAGE_ONE_TIME_END 	= 1 days;
	uint public constant STAGE_TWO_TIME_END 	= 1 weeks;
	uint public constant STAGE_THREE_TIME_END	= 2 weeks;
	uint public constant STAGE_FOUR_TIME_END 	= 4 weeks;

	//CGXToken Token Limits
	uint public constant CAP 			= 76350 ether; //50 million USD
	uint public constant MAX_SUPPLY 		= decimalMulti(2000000000); //2 billion CGX

	// allocations
	uint public constant ALLOC_FOUNDER_CONTRIB	= decimalMulti(200000000);
	uint public constant ALLOC_ILLIQUID_TEAM 	= decimalMulti(200000000);
	uint public constant ALLOC_MARKETING 		= decimalMulti(278297573);
	uint public constant ALLOC_SAFT 		= decimalMulti(40158576);
	uint public constant ALLOC_COMPANY 		= decimalMulti(321702427);
	uint public constant ALLOC_CROWDSALE 		= decimalMulti(959841424);

	//Prices of CGXToken
	uint public constant PRICE_STAGE_FOUR 	= decimalMulti(8500); // 0% bonus
	uint public constant PRICE_STAGE_THREE 	= decimalMulti(9350); // 10% bonus
	uint public constant PRICE_STAGE_TWO 	= decimalMulti(10200); // 20% bonus
	uint public constant PRICE_STAGE_ONE 	= decimalMulti(11050); // 30% bonus

	//ASSIGNED IN INITIALIZATION
	//Start and end times
	uint public publicStartTime; //Time in seconds public crowd fund starts.
	uint public publicEndTime; //Time in seconds crowdsale ends
	//Special Addresses
	address public multisigAddress; //Receiving ETH address.
	address public cgcxAddress; //Address to which ALLOC_MARKETING, ALLOC_FOUNDER_CONTRIB, ALLOC_NEW_USERS, ALLOC_ILLIQUID_TEAM is sent to.
	address public ownerAddress; //Address of the contract owner. Can halt the crowdsale.
	//Contracts
	CGXToken public cgxToken; //External token contract hollding the CGXToken
	//Running totals
	uint public weiReceived; //Total wei raised.
	uint public cgxSold; //Total CGXToken created

	//booleans
	bool public halted; //halts the crowd sale if true.

	//FUNCTION MODIFIERS

	//Is currently in the period after the private start time and before the public start time.
	modifier is_post_crowdfund_period() {
		if (now < publicEndTime) throw;
		_;
	}

	//Is currently the crowdfund period
	modifier is_crowdfund_period() {
		if (now < publicStartTime || now >= publicEndTime) throw;
		_;
	}

	//May only be called by the owner address
	modifier only_owner() {
		if (msg.sender != ownerAddress) throw;
		_;
	}

	//May only be called if the crowdfund has not been halted
	modifier is_not_halted() {
		if (halted) throw;
		_;
	}

	// EVENTS
	event Buy(address indexed _recipient, uint _amount);


	// FUNCTIONS

	// giving a number of CGX as input will return elevated to the decimal precision
	function decimalMulti(uint input) private returns (uint) {
		return input * 10 ** decimals;
	}

	//Initialization function. Deploys CGXToken contract assigns values, to all remaining fields, creates first entitlements in the cgx Token contract.
	function Contribution(
		address _multisig,
		address _cgcx,
		uint _publicStartTime
	) {
		ownerAddress = msg.sender;
		publicStartTime = _publicStartTime;
		publicEndTime = _publicStartTime + STAGE_FOUR_TIME_END; // end of Contribution
		multisigAddress = _multisig;
		cgcxAddress = _cgcx;

		cgxToken = new CGXToken(MAX_SUPPLY); // all tokens initially assigned to this contract

		// team
		allocateTokensWithVestingToTeam(publicEndTime);
		cgxToken.transfer(cgcxAddress, ALLOC_FOUNDER_CONTRIB);

		// marketing and bonus , bounties
		cgxToken.transfer(cgcxAddress, ALLOC_MARKETING);

		// saft token allocations
		cgxToken.transfer(cgcxAddress, ALLOC_SAFT);

		// Future R&D & operations
		cgxToken.grantVestedTokens(cgcxAddress,
				ALLOC_COMPANY,
				uint64(publicEndTime),
				uint64(publicEndTime + (52 weeks)), // cliff of 1 year
				uint64(publicEndTime + (52 weeks)), // no vesting after cliff
				true,
				false
			); 

		/
	}

	function allocateTokensWithVestingToTeam(uint time) private {
		cgxToken.grantVestedTokens(0x9c160d7450400b59AA3e7D1a8cc4Bf664859aB4B,
				decimalMulti(40000000),
				uint64(time),
				uint64(publicEndTime + (26 weeks)), // cliff of 6 months
				uint64(publicEndTime + (52 weeks)), // vesting of 1 year
				true,
				false
			); // team 1
		cgxToken.grantVestedTokens(0x97251AA8f0a71b10E90077AebabEd0c1e2626455,
				decimalMulti(40000000),
				uint64(time),
				uint64(publicEndTime + (26 weeks)), // cliff of 6 months
				uint64(publicEndTime + (52 weeks)), // vesting of 1 year
				true,
				false
			); // team 2
		cgxToken.grantVestedTokens(0xBA361d8b9A6D7CE1603Cf526604ce5431ecc0E76,
				decimalMulti(40000000),
				uint64(time),
				uint64(publicEndTime + (26 weeks)), // cliff of 6 months
				uint64(publicEndTime + (52 weeks)), // vesting of 1 year
				true,
				false
			); // team 3
		cgxToken.grantVestedTokens(0x0C60180e5F1dEf7Daa947F88bF840dCeF8A27f53,
				decimalMulti(40000000),
				uint64(time),
				uint64(publicEndTime + (26 weeks)), // cliff of 6 months
				uint64(publicEndTime + (52 weeks)), // vesting of 1 year
				true,
				false
			); // team 4
		cgxToken.grantVestedTokens(0x3f0C1028d5F55CaA11208173D8AE09d42c3ff5B0,
				decimalMulti(40000000),
				uint64(time),
				uint64(publicEndTime + (52 weeks)), // cliff of 1 year
				uint64(publicEndTime + (104 weeks)), // vesting of 2 year
				true,
				false
			); // team 5
	}

	//May be used by owner of contract to halt crowdsale and no longer except ether.
	function toggleHalt(bool _halted)
		only_owner
	{
		halted = _halted;
	}

	//constant function returns the current cgx price.
	function getPriceRate()
		constant
		returns (uint o_rate)
	{
		if (now <= publicStartTime + STAGE_ONE_TIME_END) return PRICE_STAGE_ONE;
		if (now <= publicStartTime + STAGE_TWO_TIME_END) return PRICE_STAGE_TWO;
		if (now <= publicStartTime + STAGE_THREE_TIME_END) return PRICE_STAGE_THREE;
		if (now <= publicStartTime + STAGE_FOUR_TIME_END) return PRICE_STAGE_FOUR;
		else return 0;
	}

	// Given the rate of a purchase and the remaining tokens in this tranche, it
	// will throw if the sale would take it past the limit of the tranche.
	// It executes the purchase for the appropriate amount of tokens, which
	// involves adding it to the total, minting cgx tokens and stashing the
	// ether.
	// Returns `amount` in scope as the number of cgx tokens that it will
	// purchase.
	function processPurchase(address _to, uint _rate)
		internal
		returns (uint o_amount)
	{

		o_amount = msg.value.mul(_rate).div(1 ether);

		if (weiReceived.add(msg.value) > CAP || cgxSold.add(o_amount) > ALLOC_CROWDSALE) throw;

		if (!multisigAddress.send(msg.value)) throw;
		cgxToken.transfer(_to, o_amount); // will throw if not completed.

		weiReceived = weiReceived.add(msg.value);
		cgxSold = cgxSold.add(o_amount);
	}

	//Default function called by sending Ether to this address with no arguments.
	//Results in creation of new cgx Tokens if transaction would not exceed hard limit of cgx Token.
	function()
		payable
		is_crowdfund_period
		is_not_halted
	{
		uint amount = processPurchase(msg.sender, getPriceRate());
		Buy(msg.sender, amount);
	}

	function emptyContribuitionPool(address _to)
		only_owner
		is_post_crowdfund_period
	{
		cgxToken.transfer(_to, (ALLOC_CROWDSALE.sub(cgxSold)));
	}

	//failsafe drain
	function drain()
		only_owner
	{
		if (!ownerAddress.send(this.balance)) throw;
	}
}
