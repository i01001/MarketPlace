//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract MarketPlace is Ownable, ReentrancyGuard, ERC1155Holder {
    // using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public _counterListSale;
    Counters.Counter public _counterListSold;
    Counters.Counter public _counterListAuction;
    Counters.Counter public _counterAuctionSold;

    address public NFT721Contract;
    address public NFT1155Contract;
    uint256 public ListingPrice = 10**15;
    uint256 public AuctionListingPrice = 10**15;
    uint256 public listsalecomissionpercent = 5;
    uint256 public Auctioncomissionpercent = 10;
    uint256 public treasury;

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

    struct AuctionListing {
        address payable seller;
        address nftContract;
        address payable buyer;
        address payable lastBidder;
        bool nftType;
        bool currencyType;
        bool AuctionStatus;
        uint256 startingprice;
        uint256 AuctionID;
        uint256 tokenID;
        uint256 startTime;
        uint256 lastBid;
        uint256 numberofbids;
        uint256 amountNFT1155;
        bytes data;
    }

    constructor() {}

    mapping(uint256 => ItemforSale) private listingIDtoItems;
    mapping(uint256 => AuctionListing) private auctionIDtoItems;

    event Log(string _function, address _sender, uint256 _value, bytes _data);
    event Rec(string _function, address _sender, uint256 _value);

    function setNFT721ContractAddress(address _input) public onlyOwner {
        NFT721Contract = _input;
    }

    function setNFT1155ContractAddress(address _input) public onlyOwner {
        NFT1155Contract = _input;
    }

    function setListingPrice(uint256 _listingPrice) public onlyOwner {
        ListingPrice = _listingPrice;
    }

    function setAuctionListingPrice(uint256 _listingPrice) public onlyOwner {
        AuctionListingPrice = _listingPrice;
    }

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

    function listingSaleComission(uint256 _comission) public onlyOwner {
        listsalecomissionpercent = _comission;
    }

    function AuctionSaleComission(uint256 _comission) public onlyOwner {
        Auctioncomissionpercent = _comission;
    }

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
            _nftType,
            _currency,
            true,
            _startprice,
            _currentItem,
            _tokenID,
            block.timestamp,
            _startprice,
            0,
            _amountNFT1155,
            _data
        );
        treasury += AuctionListingPrice;
        return _currentItem;
    }

    function makeBid(uint256 _auctionID) public payable returns (bool) {
        require(
            msg.value > auctionIDtoItems[_auctionID].lastBid,
            "The amount needs to be higher than last bid (or starting bid if no bids)!"
        );
        require(
            auctionIDtoItems[_auctionID].AuctionStatus == true,
            "The auction needs to be open!"
        );

        if (auctionIDtoItems[_auctionID].numberofbids >= 1) {
            address payable _newadd = payable(
                address(auctionIDtoItems[_auctionID].lastBidder)
            );
            payable(_newadd).transfer((auctionIDtoItems[_auctionID].lastBid));
        }
        auctionIDtoItems[_auctionID].lastBid = msg.value;
        auctionIDtoItems[_auctionID].numberofbids += 1;
        auctionIDtoItems[_auctionID].lastBidder = payable(msg.sender);
        return true;
    }

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
            _counterAuctionSold.increment();
            auctionIDtoItems[_auctionID].AuctionStatus = false;
        } else {
            cancelAuction(_auctionID);
        }
        return true;
    }

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

        if (auctionIDtoItems[_auctionID].numberofbids >= 1) {
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
        return true;
    }

    //    function AuctionStatus (uint _auctionID) public view returns(AuctionListing[] memory){

    //        AuctionListing[] memory _auctionItems = new AuctionListing[](1);
    //        AuctionListing storage _currentItem = auctionIDtoItems[_auctionID];
    //        _auctionItems[0] = _currentItem;

    //        return _auctionItems;
    //     }

    // function AllAuctionListed() public view returns (AuctionListing[] memory) {
    //     uint256 index;

    //     AuctionListing[] memory _auctionItems = new AuctionListing[](
    //         _counterListAuction.current()
    //     );
    //     for (uint256 i = 0; i < (_counterListAuction.current()); i++) {
    //         if (auctionIDtoItems[i + 1].seller == msg.sender) {
    //             AuctionListing storage _currentItem = auctionIDtoItems[i + 1];
    //             _auctionItems[index] = _currentItem;
    //             index++;
    //         }
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

    // function allItemsforSaleListed()
    //     public
    //     view
    //     returns (ItemforSale[] memory)
    // {
    //     uint256 _arraysize = _counterListSale.current();
    //     ItemforSale[] memory _listItems = new ItemforSale[](_arraysize);
    //     for (uint256 i = 0; i < (_counterListSale.current()); i++) {
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

    // fallback() external payable {
    //     emit Log("fallback message failed", msg.sender, msg.value, msg.data);
    // }

    // receive() external payable {
    //     emit Rec("fallback message failed", msg.sender, msg.value);
    // }
}
