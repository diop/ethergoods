pragma solidity ^0.4.15;

import './Ownable.sol';
import './BasicNFT.sol';

contract BasicNFTTokenMarket is Ownable  {

  address owner;
  BasicNFT public tokenContract;
  //uint256 public ownerCut;

  bool public isNFTMarket = true;

  bool public hasTokenContract = false;
  bool public lockTokenContract = false;

  mapping (address => uint) public pendingWithdrawals;

  event TransferSupply(uint256 indexed typeId,address indexed from, address indexed to, uint amount);

  //event SupplyOffered(uint256 indexed typeId, uint minValue, address indexed toAddress);
  event SupplyBidEntered(uint256 indexed typeId, uint value, address indexed fromAddress);
  //event SupplyBought(uint256 indexed typeId,  uint value, address fromAddress, address indexed toAddress);
  event SupplySold(uint256 indexed typeId, uint value, address indexed fromAddress, address toAddress);

  //event SupplyNoLongerForSale(uint256 indexed typeId);
  event SupplyBidWithdrawn(uint256 indexed typeId, uint value, address indexed fromAddress);




  function setTokenContractAddress(address _address) external onlyOwner {
      if(lockTokenContract) revert();
      BasicNFT goodTokenContract = BasicNFT(_address);

      // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
      //require(goodTokenContract.isGoodToken);

      // Set the new contract address
      tokenContract = goodTokenContract;
      hasTokenContract = true;
  }

  function lockTokenContractAddress() external onlyOwner {
      if(!hasTokenContract) revert();
      lockTokenContract = true;
  }


/*
  struct Offer {
      bool isForSale;
      uint256 tokenId;
      address seller;
      uint256 minValue;
      address onlySellTo;     // specify to sell only to a specific person
  }
*/

  struct Bid {
      bool hasBid;
      uint256 tokenId;
      address bidder;
      uint256 value;
  }


  mapping(address => Bid[]) public bids;

  // A record of supplies that are offered for sale at a specific minimum value, and perhaps to a specific person
  //mapping (uint256 => Offer) public supplyOfferedForSale;

  // A record of the highest  bid
  mapping (uint256 => Bid) public supplyBids;




  /*function tokenContractExists() public view returns (bool){
    return hasTokenContract;
  }*/


  //tokenId is the keccak of the typeId and instanceId
  function tokenExists(uint tokenId) public view returns (bool) {
     return tokenContract.tokenOwner(tokenId) != 0x0;
   }

/*  Not compatible with BasicNFT contract - requires specific approval

  function offerSupplyForSale(uint256 tokenId, uint minSalePriceInWei) public {
      if(!tokenExists(tokenId)) revert(); //if the good isnt registered
      if(tokenContract.ownerOf(tokenId) != msg.sender ) revert(); //must have balance of the token

      supplyOfferedForSale[tokenId] = Offer(true, tokenId, msg.sender, minSalePriceInWei, 0x0);
      SupplyOffered(tokenId, minSalePriceInWei, 0x0);
  }
  */

/*
  function offerSupplyForSaleToAddress(uint256 tokenId, uint minSalePriceInWei, address toAddress) public {
    if(!tokenExists(tokenId)) revert(); //if the good isnt registered
    if(tokenContract.ownerOf(tokenId) != msg.sender ) revert(); //must have balance of the token

    supplyOfferedForSale[tokenId] = Offer(true, tokenId, msg.sender, minSalePriceInWei, toAddress);
    SupplyOffered(tokenId, minSalePriceInWei, toAddress);

    tokenContract.transfer(msg.sender,tokenId);
  }
*/

/*

  function supplyNoLongerForSale(uint256 tokenId) public {
    if(!tokenExists(tokenId)) revert(); //if the good isnt registered
    if(tokenContract.ownerOf(tokenId) != msg.sender ) revert();
    if(supplyOfferedForSale[tokenId].seller != msg.sender) revert(); //must be the owner of this supply

     supplyOfferedForSale[tokenId] = Offer(false, tokenId, msg.sender, 0, 0x0);
     SupplyNoLongerForSale(tokenId);
  }

*/

/*
  function buySupply(uint256 tokenId) public payable {
      if(!tokenExists(tokenId)) revert();
      Offer memory offer = supplyOfferedForSale[tokenId];

    //  if(supplyIndex >= goods[uniqueHash].totalSupply) revert();

      if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) revert();  //  not supposed to be sold to this user
      if (msg.value < offer.minValue) revert();      // Didn't send enough ETH
      if (offer.minValue < 0) revert();
      if (msg.value < 0) revert();

      //prevent re-entrancy
      supplyOfferedForSale[tokenId] = Offer(false, tokenId, msg.sender, 0, 0x0);
      SupplyNoLongerForSale(tokenId);
      if (!offer.isForSale) revert();


      address seller = offer.seller;

      tokenContract.transfer(msg.sender,tokenId);
      TransferSupply(tokenId, seller, msg.sender, 1);

      uint256 amount = msg.value;
      uint256 market_fee = safediv(amount,50);

      pendingWithdrawals[owner] += market_fee;
      pendingWithdrawals[seller] += safesub(amount, market_fee);

      SupplyBought(tokenId, amount, seller, msg.sender);
      SupplySold(tokenId, amount, seller, msg.sender);

      // Check for the case where there is a bid from the new owner and refund it.
      // Any other bid can stay in place.
      Bid memory bid =  supplyBids[tokenId];
      if (bid.bidder == msg.sender) {
          //prevent re-entrancy
          supplyBids[tokenId] = Bid(false, tokenId, 0x0, 0);
          SupplyBidWithdrawn(tokenId, bid.value, bid.bidder);
          // Kill bid and refund value
          pendingWithdrawals[bid.bidder] += bid.value;

      }
  }
*/


  function enterBidForSupply(uint256 tokenId) public payable {
    if(!tokenExists(tokenId)) revert();

      if (msg.value == 0) revert();
      Bid memory existing =  supplyBids[tokenId];
      if (msg.value <= existing.value) revert(); //need to bid higher
      if (existing.value > 0 && existing.hasBid) {  ///if there is another active bid
          // Refund the failing bid
          //prevent re-entrancy
          supplyBids[tokenId] = Bid(false, tokenId, 0x0, 0);
          pendingWithdrawals[existing.bidder] += existing.value;
      }

       supplyBids[tokenId] = Bid(true, tokenId, msg.sender, msg.value);
       SupplyBidEntered(tokenId, msg.value, msg.sender);
  }

  function acceptBidForSupply(uint256 tokenId, uint256 minPrice) public {

      if(!tokenExists(tokenId)) revert();

       address seller = msg.sender;
       Bid memory bid = supplyBids[tokenId];
      if(bid.bidder == msg.sender) revert(); //cant accept own bid
      if(tokenContract.ownerOf(tokenId) != seller ) revert(); //must have balance of the token
      if (bid.value < minPrice) revert();

      //prevent re-entrancy
      supplyBids[tokenId] = Bid(false, tokenId, 0x0, 0);
      SupplyBidWithdrawn(tokenId, bid.value, msg.sender);
      if (bid.value == 0) revert();

      tokenContract.approve(bid.bidder,tokenId);
      tokenContract.transferFrom(seller,bid.bidder,tokenId);
      TransferSupply(tokenId, seller, bid.bidder, 1);

      //supplyOfferedForSale[tokenId] = Offer(false, tokenId, bid.bidder, 0, 0x0);
      //SupplyNoLongerForSale(tokenId);

      uint256 amount = bid.value;

      uint256 market_fee = safediv(amount,50);

      pendingWithdrawals[owner] += market_fee;
      pendingWithdrawals[seller] += safesub(amount, market_fee);

      //SupplyBought(tokenId, bid.value, seller, bid.bidder);
      SupplySold(tokenId, bid.value, seller, bid.bidder);
  }

  function withdrawBidForSupply(uint256 tokenId) public {
      if(!tokenExists(tokenId)) revert();

      Bid memory bid = supplyBids[tokenId];

      //prevent re-entrancy
      supplyBids[tokenId] = Bid(false, tokenId, 0x0, 0);
      if (bid.hasBid == false) revert();
      if (bid.bidder != msg.sender) revert();

      // Refund the bid money
      pendingWithdrawals[msg.sender] +=  bid.value;
      SupplyBidWithdrawn(tokenId, bid.value, msg.sender);
  }


  function withdrawPendingBalance() public
  {

    uint256 amountToWithdraw = pendingWithdrawals[msg.sender];

    //prevent re-entrancy
    pendingWithdrawals[msg.sender] = 0;
    if( amountToWithdraw <= 0 ) revert();

    msg.sender.transfer( amountToWithdraw );

  }



    function safemul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
        return 0;
      }
      uint256 c = a * b;
      assert(c / a == b);
      return c;
    }

    function safediv(uint256 a, uint256 b) internal pure returns (uint256) {
      // assert(b > 0); // Solidity automatically throws when dividing by 0
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold
      return c;
    }

    function safesub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function safeadd(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }



}
