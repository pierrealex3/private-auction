// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract PrivateAuction {

    mapping (uint256 => Sellable) public sellableById;
    address[] public authorizedAuctioneers;

    event AuctioneerPaymentSuccess(address indexed auctioneerAddress, uint256 indexed auctioneerPartyCut);
    event BidRaised(uint256 indexed itemId, address indexed bidderAdress, uint256 indexed bidPrice);
    event AuctionClosedOnItemSold(uint256 indexed itemId, uint256 indexed bidPrice);

    error PrivateAuction__NotEnoughEthToPay3rdPartyFee();
    error PrivateAuction__AuctioneerPaymentDidNotSucceed();
    error PrivateAuction__NotEnoughEthForBid();
    error PrivateAuction__ItemDoesNotExist();
    error PrivateAuction__BidNotHighEnough();
    error PrivateAuction__BidLoserPaybackDidNotSucceed();
    error PrivateAuction__OnlySellerCanAcceptBid();
    error PrivateAuction__AcceptBidSellerPaymentDidNotSucceed();

    struct Sellable {
        uint256 id;
        // bytes32 imgHash;
        string description;
        uint256 askPrice;
        uint256 bidPrice;
        address sellerAddress;
        address buyerAddress;
        address auctioneerAddress;
        uint256 startOfAuctionDate;
        uint256 auctionDurationSeconds;
        bool exists;                
    }

    /**
     * TODO: This method signature must be changed because we want the item conditions to be accepted by an authorized auctioneer.
     * Technically, those params are probably going to be replaced by a signed json structure which we can decode with the public key of an authorized auctioneer (char[] tag) specified as a param.
     */
    function createItem(uint256 id, string memory description, uint256 askPrice, uint256 bidPrice, address sellerAddress, address buyerAddress, address auctioneerAddress, uint256 startOfAuctionDate, uint256 auctionDurationSeconds, uint256 operatorPartyCut, uint256 auctioneerPartyCut) external payable {
    
        if (msg.value < operatorPartyCut + auctioneerPartyCut) {
            revert PrivateAuction__NotEnoughEthToPay3rdPartyFee();
        }

        Sellable memory sellable = Sellable(id,  description,  askPrice,  bidPrice,  sellerAddress,  buyerAddress,  auctioneerAddress,  startOfAuctionDate,  auctionDurationSeconds, true);
        sellableById[id] = sellable;

        (bool success, ) = auctioneerAddress.call{value: auctioneerPartyCut}("");
        if (!success) {
            revert PrivateAuction__AuctioneerPaymentDidNotSucceed();
        }
        emit AuctioneerPaymentSuccess(auctioneerAddress, auctioneerPartyCut);

    }

    /**
     * TODO: This method will actually be called from the DAO - upon community approval.
     *   The public key of the auctioneer will be required so it can be used accordingly for verification.
     */
    function addAuthorizedAuctioneer(address auctioneer) external {
        authorizedAuctioneers.push(auctioneer);
    }

    /**
     * TODO: Evaluate whether to refund OR refuse a bid for which the transferred ETH is superior to the specified bidPrice
     */
    function bid(uint256 id, uint256 bidPrice) external payable {

        if (msg.value < bidPrice) {
            revert PrivateAuction__NotEnoughEthForBid();
        }

        Sellable memory item = sellableById[id];
        if (!item.exists) {
            revert PrivateAuction__ItemDoesNotExist();
        }

        if (item.bidPrice <= bidPrice) {  // TODO: consider a minimum bid gap !
            uint256 formerBidPrice = item.bidPrice;
            address formerBuyerAddress = item.buyerAddress;
            item.bidPrice = bidPrice;
            item.buyerAddress = msg.sender;

            (bool success, ) = formerBuyerAddress.call{value: formerBidPrice}("");

            if (!success) {
                revert PrivateAuction__BidLoserPaybackDidNotSucceed();
            }

            emit BidRaised(id, msg.sender, bidPrice);
                  
        } else {
            revert PrivateAuction__BidNotHighEnough();
        }      
    }
    
    function acceptBid(uint256 id) external payable {
        
        Sellable memory item = sellableById[id];
        if (!item.exists) {
            revert PrivateAuction__ItemDoesNotExist();
        }

        if (msg.sender != item.sellerAddress) {
            revert PrivateAuction__OnlySellerCanAcceptBid();
        }

        delete sellableById[id];
        (bool success, ) = msg.sender.call{value: item.bidPrice}("");

        if (!success) {
            revert PrivateAuction__AcceptBidSellerPaymentDidNotSucceed();
        }

        emit AuctionClosedOnItemSold(id, item.bidPrice);
    }

    /**
     * TODO: CL Automation hook to initiate the end of an auction
     */
}
