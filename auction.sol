// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

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
  address payable public highestsBidder;

  mapping(address => uint256) public bids;
  uint256 bidIncrement;

  constructor() {
    // 15 sec per block
    uint256 blocksInWeek = 40320;
    owner = payable(msg.sender);
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
    require(currentBid > bidIncrement);

    bids[msg.sender] = currentBid;

    if (currentBid <= bids[highestsBidder]) {
      highestBindingBid = min(currentBid + bidIncrement, bids[highestsBidder]);
    } else {
      highestBindingBid = min(currentBid, bids[highestsBidder] + bidIncrement);
      highestsBidder = payable(msg.sender);
    }
  }
}
