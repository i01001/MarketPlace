//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract MNFT721 is ERC721URIStorage, Ownable {
      using Strings for uint256;
      using Counters for Counters.Counter;

      address public MarketPlaceContract;
      
      Counters.Counter public _counter;


      constructor() ERC721("NFT721MakerforMarketPlace", "MNFT721"){
      }


    function setMarketPlace (address _input) public onlyOwner {
        MarketPlaceContract = _input;
    }


    function mint(address _to, string memory _tokenURI) public returns (uint, address) {
        // require (MarketPlaceContract != 0x0000000000000000000000000000000000000000, "Set the Marketplace Address contract via the setMarketPlace function!");
        _counter.increment();
        uint _tokencount = _counter.current();
        _safeMint(_to, _tokencount );
        _setTokenURI(_tokencount, _tokenURI);
        // setApprovalForAll(MarketPlaceContract, true);
        return (_tokencount, address(this));
    }

}