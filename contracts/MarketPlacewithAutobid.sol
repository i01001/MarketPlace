//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @title Market Place Contract for NFT minting, listing and auctions (including auto bid)
/// @author Ikhlas
/// @notice The contract does not have the NFT Contract hardcorded and can be used with other NFT Contracts
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract MarketPlacewithAutobid is Ownable, ReentrancyGuard, ERC1155Holder {
    using Counters for Counters.Counter;

    /// @notice Allows users to create NFT,list them or auction them.
    /// @dev Additional features can be added such as batch minting
    /// @notice Counters are used for couting the listed items, sold, auction items and sold respectively.
    Counters.Counter public _counterListSale;
    Counters.Counter public _counterListSold;
    Counters.Counter public _counterListAuction;
    Counters.Counter public _counterAuctionSold;

    /// @dev Variables for the contract
    /// @notice NFT721Contract - to set up the NFT721 contract
    /// @notice NFT1155Contract - to set up the NFT1155 contract
    /// @notice ListingPrice - fees to create a listing
    /// @notice AuctionListingPrice - fees to create an auction
    /// @notice listsalecomissionpercent - comission percentage on listing selling price
    /// @notice Auctioncomissionpercent - comission percentage on auction selling price
    /// @notice Treasury - to calculate the comission balance for the Market Place
    address public NFT721Contract;
    address public NFT1155Contract;
    uint256 public ListingPrice = 10**15;
    uint256 public AuctionListingPrice = 10**15;
    uint256 public listsalecomissionpercent = 5;
    uint256 public Auctioncomissionpercent = 10;
    uint256 public treasury;

    /// @dev Struct for Listing created
    /// @notice First 3 are address of seller, NFT contract and buyer
    /// @notice NFTTYPE - False for NFT721; True for NFT1155
    /// @dev Currency - Not implemented feature - False for Ethereum; True for Market Place Token
    /// @notice Listing ID - Market Place counter tracking listings
    /// @notice Token ID - As per the respective NFT Contract
    /// @notice amountNFT1155 - Number of NFT1155 to be listed / not applicable for NFT721
    /// @notice data - applicable only for NFT1155; generally to be kept empty. In Remix use "[]"; in Hardhat use "
    struct ItemforSale {
        address payable seller;
        address nftContract;
        address payable buyer;
        bool nftType;
        bool currencyType;
        uint256 price;
        uint256 listingID;
        uint256 tokenID;
        uint256 amountNFT1155;
        bytes data;
    }

    /// @dev Struct for Auction Listing created
    /// @notice First 5 are address of seller, NFT contract and buyer, last bidder, Auto bidder
    /// @notice NFTTYPE - False for NFT721; True for NFT1155
    /// @dev Currency - Not implemented feature - False for Ethereum; True for Market Place Token
    /// @notice Auction Status - True for Auction Open; False for Auction Closed
    /// @notice Starting Price - bids need to be higher than this
    /// @notice Auction ID - Market Place counter for auction tracking listings
    /// @notice Token ID - As per the respective NFT Contract
    /// @notice startTime - Time setting up the auction
    /// @notice Autobidderlimit - maximum limit by the Autobidder set up for the Auto Bid
    /// @notice lastbid - last bid value
    /// @notice numberofbids - count of bids
    /// @notice amountNFT1155 - Number of NFT1155 to be listed / not applicable for NFT721
    /// @notice data - applicable only for NFT1155; generally to be kept empty. In Remix use "[]"; in Hardhat use ""
    struct AuctionListing {
        address payable seller;
        address nftContract;
        address payable buyer;
        address payable lastBidder;
        address payable Autobidder;
        bool nftType;
        bool currencyType;
        bool AuctionStatus;
        uint256 startingprice;
        uint256 AuctionID;
        uint256 tokenID;
        uint256 startTime;
        uint256 autobidderlimit;
        uint256 lastBid;
        uint256 numberofbids;
        uint256 amountNFT1155;
        bytes data;
    }

    constructor() {}

    /// @notice Mapping of Listing ID with Listing Struct
    /// @notice Mapping of Auction ID witth Auction Struct
    mapping(uint256 => ItemforSale) private listingIDtoItems;
    mapping(uint256 => AuctionListing) private auctionIDtoItems;

    /// @notice events for Fall back and receive function
    event Log(string _function, address _sender, uint256 _value, bytes _data);
    event Rec(string _function, address _sender, uint256 _value);

    /// @notice inputting the NFT721 contract
    function setNFT721ContractAddress(address _input) public onlyOwner {
        NFT721Contract = _input;
    }

    /// @notice inputting the NFT1155 contract
    function setNFT1155ContractAddress(address _input) public onlyOwner {
        NFT1155Contract = _input;
    }

    /// @notice inputting the Listing Price (fees for setting up a listing)
    function setListingPrice(uint256 _listingPrice) public onlyOwner {
        ListingPrice = _listingPrice;
    }

    /// @notice inputting the Auction Listing Price (fees for setting up a Auction listing)
    function setAuctionListingPrice(uint256 _listingPrice) public onlyOwner {
        AuctionListingPrice = _listingPrice;
    }

    /// @notice Function to create NFTs - both NFT types
    /// @param _nftType explained in struct above
    /// @param _tokenURI explained in struct above
    /// @dev _amountNFT1155 not applicable for NFT721 (can put in random number)
    /// @return tokenID of the created NFT
    function createItem(
        bool _nftType,
        string memory _tokenURI,
        uint256 _amountNFT1155
    ) public returns (bytes memory) {
        if (_nftType == false) {
            require(
                NFT721Contract != address(0),
                "Set the NFT721Contract Address via the function!"
            );
            (bool success, bytes memory _tokenID) = NFT721Contract.call(
                abi.encodeWithSignature(
                    "mint(address,string)",
                    msg.sender,
                    _tokenURI
                )
            );
            require(success);
            return _tokenID;
        } else {
            require(
                NFT1155Contract != address(0),
                "Set the NFT1155Contract Address via the function!"
            );
            (bool success, bytes memory _tokenID) = NFT1155Contract.call(
                abi.encodeWithSignature(
                    "mint(address,string,uint256)",
                    msg.sender,
                    _tokenURI,
                    _amountNFT1155
                )
            );
            require(success);
            return _tokenID;
        }
    }

    /// @notice Function to list items for sale (fixed price)
    function listItem(
        address _nftContract,
        uint256 _tokenID,
        bool _nftType,
        uint256 _amountNFT1155,
        bytes memory _data,
        bool _currency,
        uint256 _price
    ) public payable returns (uint256) {
        require(
            ListingPrice > 0,
            "The listing price needs to be setup; must be atleast 1 wei!"
        );
        require(
            msg.value == ListingPrice,
            "The amount needs to be exactly as listing price!"
        );
        require(_price > 0, "Price must be at least 1 wei");
        if (_nftType == false) {
            (bool success, ) = _nftContract.call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    payable(msg.sender),
                    payable(address(this)),
                    _tokenID
                )
            );
            require(
                success,
                "Error transferring, ensure that this contract has been approved!"
            );
        } else {
            (bool success, ) = _nftContract.call(
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    msg.sender,
                    address(this),
                    _tokenID,
                    _amountNFT1155,
                    _data
                )
            );
            require(success);
        }
        _counterListSale.increment();
        uint256 _currentItem = _counterListSale.current();

        listingIDtoItems[_currentItem] = ItemforSale(
            payable(msg.sender),
            _nftContract,
            payable(address(0)),
            _nftType,
            _currency,
            _price,
            _currentItem,
            _tokenID,
            _amountNFT1155,
            _data
        );
        treasury += ListingPrice;
        return _currentItem;
    }

    /// @notice Function to buy items for sale (fixed price)
    function buyItem(uint256 _listingID) public payable returns (bool) {
        require(
            listingIDtoItems[_listingID].buyer == address(0),
            "The listing needs to be open for sale (not sold / cancelled)!"
        );
        require(
            msg.value == listingIDtoItems[_listingID].price,
            "The amount needs to be exactly as selling price!"
        );
        require(
            _listingID <= _counterListSale.current(),
            "Invalid Listing ID!"
        );
        if (listingIDtoItems[_listingID].nftType == false) {
            (bool success, ) = (listingIDtoItems[_listingID].nftContract).call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    payable(address(this)),
                    payable(msg.sender),
                    (listingIDtoItems[_listingID].tokenID)
                )
            );
            require(success);
        } else {
            (bool success, ) = (listingIDtoItems[_listingID].nftContract).call(
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    address(this),
                    msg.sender,
                    (listingIDtoItems[_listingID].tokenID),
                    (listingIDtoItems[_listingID].amountNFT1155),
                    (listingIDtoItems[_listingID].data)
                )
            );
            require(success);
        }
        address payable _newadd = payable(address(msg.sender));
        uint256 _comm = ((listingIDtoItems[_listingID].price) *
            listsalecomissionpercent) / 100;
        treasury += _comm;
        payable(_newadd).transfer((listingIDtoItems[_listingID].price) - _comm);
        listingIDtoItems[_listingID].buyer = payable(msg.sender);
        _counterListSold.increment();
        return true;
    }

    /// @notice Function to set up listing sale comission percent
    function listingSaleComission(uint256 _comission) public onlyOwner {
        listsalecomissionpercent = _comission;
    }

    /// @notice Function to set up Auction listing sale comission percent
    function AuctionSaleComission(uint256 _comission) public onlyOwner {
        Auctioncomissionpercent = _comission;
    }

    /// @notice Function to cancel the listing sale
    function cancel(uint256 _listingID) public returns (bool) {
        require(
            listingIDtoItems[_listingID].buyer == address(0),
            "The listing needs to be open for sale (not sold / cancelled)!"
        );
        require(
            listingIDtoItems[_listingID].seller == msg.sender,
            "The listing can only be cancelled by seller)!"
        );
        require(
            _listingID <= _counterListSale.current(),
            "Invalid Listing ID!"
        );
        if (listingIDtoItems[_listingID].nftType == false) {
            (bool success, ) = (listingIDtoItems[_listingID].nftContract).call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    payable(address(this)),
                    payable(msg.sender),
                    (listingIDtoItems[_listingID].tokenID)
                )
            );
            require(success);
        } else {
            (bool success, ) = (listingIDtoItems[_listingID].nftContract).call(
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    address(this),
                    msg.sender,
                    (listingIDtoItems[_listingID].tokenID),
                    (listingIDtoItems[_listingID].amountNFT1155),
                    (listingIDtoItems[_listingID].data)
                )
            );
            require(success);
        }
        listingIDtoItems[_listingID].buyer = payable(msg.sender);
        return true;
    }

    /// @notice Function to set up Listing items on Auctions
    function listItemOnAuction(
        address _nftContract,
        uint256 _tokenID,
        bool _nftType,
        bool _currency,
        uint256 _startprice,
        uint256 _amountNFT1155,
        bytes memory _data
    ) public payable returns (uint256) {
        require(
            AuctionListingPrice > 0,
            "The Auction listing price needs to be setup; must be atleast 1 wei!"
        );
        require(
            msg.value == AuctionListingPrice,
            "The amount needs to be exactly as Auction listing price!"
        );
        require(
            _startprice > 0,
            "Starting Bidding Price needs to be at least 1 wei"
        );
        if (_nftType == false) {
            (bool success, ) = _nftContract.call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    payable(msg.sender),
                    payable(address(this)),
                    _tokenID
                )
            );
            require(success);
        } else {
            (bool success, ) = _nftContract.call(
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    msg.sender,
                    address(this),
                    _tokenID,
                    _amountNFT1155,
                    _data
                )
            );
            require(success);
        }
        _counterListAuction.increment();
        uint256 _currentItem = _counterListAuction.current();

        auctionIDtoItems[_currentItem] = AuctionListing(
            payable(msg.sender),
            _nftContract,
            payable(address(0)),
            payable(address(0)),
            payable(address(0)),
            _nftType,
            _currency,
            true,
            _startprice,
            _currentItem,
            _tokenID,
            block.timestamp,
            0,
            _startprice,
            0,
            _amountNFT1155,
            _data
        );
        treasury += AuctionListingPrice;
        return _currentItem;
    }

    /// @notice Function to bid on the auctions listed
    function makeBid(uint256 _auctionID) public payable returns (bool) {
        require(
            msg.value > auctionIDtoItems[_auctionID].lastBid,
            "The amount needs to be higher than last bid (or starting bid if no bids)!"
        );
        require(
            auctionIDtoItems[_auctionID].AuctionStatus == true,
            "The auction needs to be open!"
        );
        uint256 _value = msg.value;
        uint256 _lim = (_value * 101) / 100;
        if (auctionIDtoItems[_auctionID].Autobidder == address(0)) {
            biddingcalc(payable(msg.sender), _auctionID, _value);
        } else {
            uint256 _current = auctionIDtoItems[_auctionID].autobidderlimit;
            if (_current < _value) {
                biddingcalc(payable(msg.sender), _auctionID, _value);
            } else if (_lim < _current) {
                biddingcalc(
                    auctionIDtoItems[_auctionID].Autobidder,
                    _auctionID,
                    _lim
                );
                address payable _newadd = payable(address(msg.sender));
                payable(_newadd).transfer(_value);
            } else {
                biddingcalc(
                    auctionIDtoItems[_auctionID].Autobidder,
                    _auctionID,
                    _current
                );
                address payable _newadd = payable(address(msg.sender));
                payable(_newadd).transfer(_value);
            }
        }
        return true;
    }

    /// @notice Private function to do biddingcalc - to return the previous bidder amounts
    function biddingcalc(
        address payable _bidder,
        uint256 _auctionID,
        uint256 _value
    ) private returns (bool) {
        if (
            (auctionIDtoItems[_auctionID].numberofbids >= 1) &&
            (auctionIDtoItems[_auctionID].Autobidder == address(0))
        ) {
            address payable _newadd = payable(
                address(auctionIDtoItems[_auctionID].lastBidder)
            );
            payable(_newadd).transfer((auctionIDtoItems[_auctionID].lastBid));
        } else if (
            (auctionIDtoItems[_auctionID].numberofbids >= 1) &&
            (auctionIDtoItems[_auctionID].Autobidder != address(0))
        ) {
            if (
                (auctionIDtoItems[_auctionID].lastBidder == _bidder) &&
                (auctionIDtoItems[_auctionID].Autobidder == _bidder)
            ) {} else if (auctionIDtoItems[_auctionID].lastBidder != _bidder) {
                address payable _newadd = payable(
                    address(auctionIDtoItems[_auctionID].lastBidder)
                );
                payable(_newadd).transfer(
                    (auctionIDtoItems[_auctionID].lastBid)
                );
            }
        }
        if (
            auctionIDtoItems[_auctionID].Autobidder != address(0) &&
            auctionIDtoItems[_auctionID].Autobidder != _bidder
        ) {
            auctionIDtoItems[_auctionID].Autobidder = payable(address(0));
            auctionIDtoItems[_auctionID].autobidderlimit = 0;
        }
        auctionIDtoItems[_auctionID].lastBid = _value;
        auctionIDtoItems[_auctionID].numberofbids += 1;
        auctionIDtoItems[_auctionID].lastBidder = _bidder;

        return true;
    }

    /// @notice Function to set up autobid by entering the auction ID and payable
    /// @dev If autobid amount is within 1 percent of last bid or existing Auto bid then the entered amount is set up as the bid amount;
    /// @dev if the autobid amount is greater than 1 percent of last bid or existing Auto bid then a bid is setup at the 1 percent
    /// @dev higher amount and the entered auto bid amount is saved and recorded (and would be compared and used for future competing bids / auto bids)
    function autobid(uint256 _auctionID) public payable returns (bool) {
        require(
            msg.value > auctionIDtoItems[_auctionID].lastBid,
            "The amount needs to be higher than last bid (or starting bid if no bids)!"
        );
        require(
            msg.value > auctionIDtoItems[_auctionID].autobidderlimit,
            "The amount needs to be higher than auto bidder limit!"
        );
        require(
            auctionIDtoItems[_auctionID].AuctionStatus == true,
            "The auction needs to be open!"
        );

        uint256 _bidvalue = msg.value;
        uint256 _current = auctionIDtoItems[_auctionID].lastBid;
        uint256 lim = (_current * 101) / 100;
        uint256 existingautobid = auctionIDtoItems[_auctionID].autobidderlimit;
        uint256 existlimit = (existingautobid * 101) / 100;

        if (auctionIDtoItems[_auctionID].Autobidder != address(0)) {
            if (_bidvalue > existlimit) {
                biddingcalc(payable(msg.sender), _auctionID, lim);
                address payable _newadd = payable(
                    address(auctionIDtoItems[_auctionID].Autobidder)
                );
                payable(_newadd).transfer(
                    auctionIDtoItems[_auctionID].autobidderlimit
                );
                auctionIDtoItems[_auctionID].Autobidder = payable(msg.sender);
                auctionIDtoItems[_auctionID].autobidderlimit = msg.value;
            } else {
                biddingcalc(payable(msg.sender), _auctionID, _bidvalue);
                address payable _newadd = payable(
                    address(auctionIDtoItems[_auctionID].Autobidder)
                );
                payable(_newadd).transfer(
                    auctionIDtoItems[_auctionID].autobidderlimit
                );
                auctionIDtoItems[_auctionID].Autobidder = payable(address(0));
                auctionIDtoItems[_auctionID].autobidderlimit = 0;
            }
        } else {
            if (_bidvalue > lim) {
                biddingcalc(payable(msg.sender), _auctionID, lim);
                auctionIDtoItems[_auctionID].Autobidder = payable(msg.sender);
                auctionIDtoItems[_auctionID].autobidderlimit = _bidvalue;
            } else {
                biddingcalc(payable(msg.sender), _auctionID, _bidvalue);
            }
        }
        return true;
    }

    /// @notice Function to finish auction - can only be done by seller
    function finishAuction(uint256 _auctionID) public returns (bool) {
        require(
            msg.sender == auctionIDtoItems[_auctionID].seller,
            "Only by Auction Seller!"
        );
        require(
            auctionIDtoItems[_auctionID].AuctionStatus == true,
            "The auction needs to be open!"
        );
        require(
            block.timestamp >= auctionIDtoItems[_auctionID].startTime + 3 days,
            "Cannot be run before 3 days!"
        );

        if (auctionIDtoItems[_auctionID].numberofbids >= 2) {
            if (auctionIDtoItems[_auctionID].nftType == false) {
                (bool success, ) = (auctionIDtoItems[_auctionID].nftContract)
                    .call(
                        abi.encodeWithSignature(
                            "transferFrom(address,address,uint256)",
                            payable(address(this)),
                            payable(auctionIDtoItems[_auctionID].lastBidder),
                            (auctionIDtoItems[_auctionID].tokenID)
                        )
                    );
                require(success);
            } else {
                (bool success, ) = (auctionIDtoItems[_auctionID].nftContract)
                    .call(
                        abi.encodeWithSignature(
                            "safeTransferFrom(address,address,uint256,uint256,bytes)",
                            address(this),
                            (auctionIDtoItems[_auctionID].lastBidder),
                            (auctionIDtoItems[_auctionID].tokenID),
                            (auctionIDtoItems[_auctionID].amountNFT1155),
                            (auctionIDtoItems[_auctionID].data)
                        )
                    );
                require(success);
            }
            address payable _newadd = payable(
                address(auctionIDtoItems[_auctionID].seller)
            );
            uint256 _comm = ((auctionIDtoItems[_auctionID].lastBid) *
                Auctioncomissionpercent) / 100;
            treasury += _comm;
            payable(_newadd).transfer(
                (auctionIDtoItems[_auctionID].lastBid) - _comm
            );
            auctionIDtoItems[_auctionID].buyer = payable(
                auctionIDtoItems[_auctionID].lastBidder
            );
            if (auctionIDtoItems[_auctionID].Autobidder != address(0)) {
                address payable _newadd2 = payable(
                    address(auctionIDtoItems[_auctionID].Autobidder)
                );
                payable(_newadd2).transfer(
                    (auctionIDtoItems[_auctionID].autobidderlimit) -
                        (auctionIDtoItems[_auctionID].lastBid)
                );
            }
            _counterAuctionSold.increment();
            auctionIDtoItems[_auctionID].AuctionStatus = false;
        } else {
            cancelAuction(_auctionID);
        }
        return true;
    }

    /// @notice Function to cancel an Auction listing
    function cancelAuction(uint256 _auctionID) public returns (bool) {
        require(
            msg.sender == auctionIDtoItems[_auctionID].seller,
            "Only by Auction Seller!"
        );
        require(
            auctionIDtoItems[_auctionID].AuctionStatus == true,
            "The auction needs to be open!"
        );
        require(
            block.timestamp >= auctionIDtoItems[_auctionID].startTime + 3 days,
            "Cannot be run before 3 days!"
        );

        if (
            auctionIDtoItems[_auctionID].numberofbids >= 1 &&
            (auctionIDtoItems[_auctionID].Autobidder != address(0))
        ) {
            address payable _newadd2 = payable(
                address(auctionIDtoItems[_auctionID].Autobidder)
            );
            payable(_newadd2).transfer(
                (auctionIDtoItems[_auctionID].autobidderlimit)
            );
        } else if (auctionIDtoItems[_auctionID].numberofbids >= 1) {
            address payable _newadd = payable(
                address(auctionIDtoItems[_auctionID].lastBidder)
            );
            payable(_newadd).transfer((auctionIDtoItems[_auctionID].lastBid));
        }
        if (auctionIDtoItems[_auctionID].nftType == false) {
            (bool success, ) = (auctionIDtoItems[_auctionID].nftContract).call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    payable(address(this)),
                    payable(auctionIDtoItems[_auctionID].seller),
                    (auctionIDtoItems[_auctionID].tokenID)
                )
            );
            require(success);
        } else {
            (bool success, ) = (auctionIDtoItems[_auctionID].nftContract).call(
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    address(this),
                    (auctionIDtoItems[_auctionID].seller),
                    (auctionIDtoItems[_auctionID].tokenID),
                    (auctionIDtoItems[_auctionID].amountNFT1155),
                    (auctionIDtoItems[_auctionID].data)
                )
            );
            require(success);
        }
        auctionIDtoItems[_auctionID].AuctionStatus = false;
        return true;
    }

    //    function AuctionStatus (uint _auctionID) public view returns(AuctionListing[] memory){

    //        AuctionListing[] memory _auctionItems = new AuctionListing[](1);
    //        AuctionListing storage _currentItem = auctionIDtoItems[_auctionID];
    //        _auctionItems[0] = _currentItem;

    //        return _auctionItems;
    //     }

    // function AllAuctionListed () public view returns (AuctionListing[] memory){
    //     uint index;

    //     AuctionListing[] memory _auctionItems = new AuctionListing[](_counterListAuction.current());
    //     for (uint i = 0; i < (_counterListAuction.current()); i++){
    //         if(auctionIDtoItems[i + 1].seller == msg.sender){
    //         AuctionListing storage _currentItem = auctionIDtoItems[i + 1];
    //         _auctionItems[index] = _currentItem;
    //         index++;
    //     }
    //     }
    //     return _auctionItems;
    // }

    // function myAuctionsListing () public view returns (AuctionListing[] memory){
    //     uint index;
    //     uint _arraysize;

    //     for(uint t = 0; t <(_counterListAuction.current()); t++){
    //         if(auctionIDtoItems[t + 1].seller == msg.sender){
    //             _arraysize++;
    //         }
    //     }

    //     AuctionListing[] memory _auctionItems = new AuctionListing[](_arraysize);
    //     for (uint i = 0; i < (_counterListAuction.current()); i++){
    //         if(auctionIDtoItems[i + 1].seller == msg.sender){
    //         AuctionListing storage _currentItem = auctionIDtoItems[i + 1];
    //         _auctionItems[index] = _currentItem;
    //         index++;
    //     }
    //     }
    //     return _auctionItems;
    // }

    // function allItemsforSaleListed () public view returns (ItemforSale[] memory){

    //     uint _arraysize = _counterListSale.current();
    //     ItemforSale[] memory _listItems = new ItemforSale[](_arraysize);
    //     for (uint i = 0; i < (_counterListSale.current()); i++){
    //         ItemforSale storage _currentstrcut = listingIDtoItems[i + 1];
    //         _listItems[i] = _currentstrcut;
    //     }
    //     return _listItems;
    // }

    // function ItemsforSaleAvailable () public view returns (ItemforSale[] memory){
    //     uint index;
    //     uint _arraysize;

    //     for(uint t = 0; t <(_counterListSale.current()); t++){
    //         if(listingIDtoItems[t + 1].buyer == address(0)){
    //             _arraysize++;
    //         }
    //     }

    //     ItemforSale[] memory _listItems = new ItemforSale[](_arraysize);
    //     for (uint i = 0; i < (_counterListSale.current()); i++){
    //         if(listingIDtoItems[i + 1].buyer == address(0)){
    //         ItemforSale storage _currentstrcut = listingIDtoItems[i + 1];
    //         _listItems[index] = _currentstrcut;
    //         index++;
    //     }
    //     }
    //     return _listItems;
    // }

    // function ItemsforSaleSold () public view returns (ItemforSale[] memory){
    //     uint index;

    //     ItemforSale[] memory _listItems = new ItemforSale[](_counterListSold.current());
    //     for (uint i = 0; i < (_counterListSale.current()); i++){
    //         if((listingIDtoItems[i + 1].buyer != address(0)) && (listingIDtoItems[i + 1].buyer != listingIDtoItems[i + 1].seller)){
    //         ItemforSale storage _currentstrcut = listingIDtoItems[i + 1];
    //         _listItems[index] = _currentstrcut;
    //         index++;
    //     }
    //     }
    //     return _listItems;
    // }

    // function myListings () public view returns (ItemforSale[] memory){
    //     uint index;
    //     uint _arraysize;

    //     for(uint t = 0; t <(_counterListSale.current()); t++){
    //         if(listingIDtoItems[t + 1].seller == msg.sender){
    //             _arraysize++;
    //         }
    //     }

    //     ItemforSale[] memory _listItems = new ItemforSale[](_arraysize);
    //     for (uint i = 0; i < (_counterListSale.current()); i++){
    //         if(listingIDtoItems[i + 1].seller == msg.sender){
    //         ItemforSale storage _currentstrcut = listingIDtoItems[i + 1];
    //         _listItems[index] = _currentstrcut;
    //         index++;
    //     }
    //     }
    //     return _listItems;
    // }

    // function myunsoldListings () public view returns (ItemforSale[] memory){
    //     uint index;
    //     uint _arraysize;

    //     for(uint t = 0; t <(_counterListSale.current()); t++){
    //         if((listingIDtoItems[t + 1].seller == msg.sender) && (listingIDtoItems[t + 1].buyer == address(0)) && (listingIDtoItems[t + 1].buyer != msg.sender)){
    //             _arraysize++;
    //         }
    //     }

    //     ItemforSale[] memory _listItems = new ItemforSale[](_arraysize);
    //     for (uint i = 0; i < (_counterListSale.current()); i++){
    //         if((listingIDtoItems[i + 1].seller == msg.sender) && (listingIDtoItems[i + 1].buyer == address(0)) && (listingIDtoItems[i + 1].buyer != msg.sender)){
    //         ItemforSale storage _currentstrcut = listingIDtoItems[i + 1];
    //         _listItems[index] = _currentstrcut;
    //         index++;
    //     }
    //     }
    //     return _listItems;
    // }

    // function ListItemStatus (uint _listingID) public view returns (ItemforSale[] memory){
    //     uint index;

    //     ItemforSale[] memory _listItems = new ItemforSale[](1);
    //     for (uint i = 0; i < (_counterListSale.current()); i++){
    //         if(listingIDtoItems[i + 1].listingID == _listingID){
    //         ItemforSale storage _currentstrcut = listingIDtoItems[i + 1];
    //         _listItems[index] = _currentstrcut;
    //         index++;
    //     }
    //     }
    //     return _listItems;
    // }

    // fallback() external payable
    // {
    //     emit Log("fallback message failed", msg.sender, msg.value, msg.data);
    // }

    // receive() external payable
    // {
    //     emit Rec("fallback message failed", msg.sender, msg.value);
    // }
}
