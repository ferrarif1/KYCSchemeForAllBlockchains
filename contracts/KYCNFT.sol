// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract KYCNFT is ERC721URIStorage,Ownable {
  address public kycManager;
  uint public last_completed_migration;
  mapping(uint => uint) public NFTID_To_ExpirationTime;
  
  //set this first!
  function setKYManagerContractAddress(address _kycManagerAddr) public onlyOwner {
    kycManager = _kycManagerAddr;
  }
  
  modifier onlyKycManagerContractAddress(){
      require(msg.sender == kycManager);
      _;
  }

  using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor() ERC721("KYCNFT", "KYCNFT") {}
  
    function awardItem(address player, string memory tokenURI)
        external
        onlyKycManagerContractAddress
        returns (uint256){  
        
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function updateExpirationTime(uint tokenId,uint timestamp) external onlyKycManagerContractAddress{
        require(tokenId <= _tokenIds.current());
        NFTID_To_ExpirationTime[tokenId] = timestamp;
    }

    function expirationTimeOfNFTId(uint tokenId) public view returns(uint){
        return NFTID_To_ExpirationTime[tokenId];
    }
  
}
