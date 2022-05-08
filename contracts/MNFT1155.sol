//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MNFT1155 is ERC1155, Ownable {
    using Counters for Counters.Counter;
    
  string public name;
  string public symbol;
  string public baseURI;
  
  Counters.Counter public _counter;

  mapping(uint => string) public tokenURI;

  constructor() ERC1155("") {
    name = "NFT721MakerforMarketPlace";
    symbol = "MNFT1155";
  }

  function mint(address _to, string memory _baseURI, uint _amount) public {
    _counter.increment();
    uint _tokenID = _counter.current();
    _mint(_to, _tokenID, _amount, "");
    tokenURI[_tokenID] = _baseURI;
    emit URI(_baseURI, _tokenID);
  }
}
    