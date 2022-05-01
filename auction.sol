// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

contract AuctionCreator {
  Auction[] public auctions;

  function createAuction() public {
    Auction auction = new Auction(msg.sender);
    auctions.push(auction);
  }
}

contract Auction {
  address payable public owner;
  uint256 public startBlock;
  uint256 public endBlock;
  string public ipfsHash;
  enum State {
    Started,
    Running,
    Ended,
    Canceled
  }
  State public auctionState;

  uint256 public highestBindingBid;
  address payable public highestBidder;

  mapping(address => uint256) public bids;
  uint256 bidIncrement;

  constructor(address externallyOwnedAccount) {
    // 15 sec per block
    uint256 blocksInWeek = 40320;
    owner = payable(externallyOwnedAccount);
    auctionState = State.Running;
    startBlock = block.number;
    endBlock = startBlock + blocksInWeek;
    ipfsHash = "";

    // Min bid 100 wei
    bidIncrement = 100;
  }

  modifier notOwner() {
    require(msg.sender != owner);
    _;
  }

  modifier afterStart() {
    require(block.number >= startBlock);
    _;
  }

  modifier beforeEnd() {
    require(block.number <= endBlock);
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function cancelAuction() public onlyOwner {
    auctionState = State.Canceled;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a < b ? a : b;
  }

  function placeBid() public payable notOwner afterStart beforeEnd {
    require(auctionState == State.Running);
    require(msg.value >= bidIncrement);

    uint256 currentBid = bids[msg.sender] + msg.value;

    // The currentBid should be greater than the highestBindingBid.
    // Otherwise there's nothing to do.
    require(currentBid > bidIncrement);

    bids[msg.sender] = currentBid;

    // HighestBidder remains unchanged
    if (currentBid <= bids[highestBidder]) {
      highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
    } else {
      // HighestBidder is another bidder
      highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
      highestBidder = payable(msg.sender);
    }
  }

  function finalizeAuction() public {
    require(auctionState == State.Canceled || block.number > endBlock);
    require(msg.sender == owner || bids[msg.sender] > 0);

    address payable recipient;
    uint256 value;

    // Auction was cancelled
    if (auctionState == State.Canceled) {
      recipient = payable(msg.sender);
      value = bids[msg.sender];
    } else {
      // Auction ended (not cancelled)

      // Ended by owner
      if (msg.sender == owner) {
        recipient = owner;
        value = highestBindingBid;
      } else {
        // Ended by a bidder

        // Highest bidder gets back what they bidded, minus the winning bid
        if (msg.sender == highestBidder) {
          recipient = highestBidder;
          value = bids[highestBidder] - highestBindingBid;
        } else {
          recipient = payable(msg.sender);
          value = bids[msg.sender];
        }
      }
    }
    // Resetting the bids of the recipient to zero
    bids[recipient] = 0;

    // Sends the value to the recipient
    recipient.transfer(value);
  }
}
