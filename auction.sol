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
  address payable public higherBidder;

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
}
