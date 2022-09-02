// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.01 ether;
  uint256 public maxSupply = 5;
  uint256 public maxMintAmount = 3;
  uint256 public nftPerAddressLimit = 2;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;


  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setnotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "The contract is paused!");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "Need to minet at least one NFT");
    require(_mintAmount <= maxMintAmount, "Max mint amount per address exceeded!");
    require(supply + _mintAmount <= maxSupply, "Max NFT limit exceeded.");
    
    // Here is been revised in order to avoid multi minted from same whitelisted address!!
    if (msg.sender != owner()) {
        if (onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "This address is not in whitelist yet!");
            // revised section below this two lines of code!
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        }
        require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function isWhitelisted(address _user) public view returns(bool) {
      for(uint256 i = 0; i < whitelistedAddresses.length; i++) {
          if(whitelistedAddresses[i] == _user) {
              return true;
          }
      }
      return false;

  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if(revealed == false) {
        return notRevealedUri;
    }
    
    // make sure the tokenId is in string type to avoid error fetching.
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner function below
  function reveal() public onlyOwner {
      revealed = true;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
      nftPerAddressLimit = _limit;
  }
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setnotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
 
 function whitelistUsers(address[] calldata _users) public onlyOwner {
     delete whitelistedAddresses;
     whitelistedAddresses = _users;
  }
 
//   three method to approach the functionality: call, transfer, send
  function withdraw() public payable onlyOwner {
    // payable(msg.sender).transfer(address(this).balance);
    // require(payable(msg.sender).transfer(address(this).balance));
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}

/** demo address 
["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
"0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
"0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
"0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB",
"0x617F2E2fD72FD9D5503197092aC168c91465E7f2"]
*/