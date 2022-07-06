// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";


interface KYCNFTInterface {
  function awardItem(address player, string memory tokenURI) external returns (uint256);
  function updateExpirationTime(uint tokenId,uint timestamp) external;
}

/*
n, accumulator is bigNumber，(May be out of range of uint256)，so use string as the value type
*/
contract KYCManager is Ownable {
    struct UserData{
    uint NFTId;
    bytes32 merkleRoot;
    }
  
  KYCNFTInterface kycNFTContract;


  mapping(uint => address) private NFTIdToManager;
  mapping(address => UserData) private ManagerToUserData;
  mapping(uint => bool) private NFTIdToAvailable;

  //set this first!
  function setKYCNFTContractAddress(address _kycnftContractAddr) public onlyOwner {
    kycNFTContract = KYCNFTInterface(_kycnftContractAddr);
  }
  
  function createKYCNFT(string memory tokenUrl, address manager, uint expirationTime) external onlyOwner{
    //owner of NFT is KYCManager Contract
    address kycnftmanager = (address)(this);
    uint256 NFTId = kycNFTContract.awardItem(kycnftmanager, tokenUrl);
    kycNFTContract.updateExpirationTime(NFTId, expirationTime);
    setNFTAvailableOfNFTId(NFTId, true);
    initManagerAddr(NFTId, manager);
  }
  
  function setNFTAvailableOfNFTId(uint NFTId, bool _available)  public onlyOwner{
    NFTIdToAvailable[NFTId] = _available;
  }
  
  
  /*
    NFTIdToManager
   */
  function initManagerAddr(uint NFTId, address manager) public onlyOwner {
    NFTIdToManager[NFTId] = manager;
    ManagerToUserData[manager].NFTId = NFTId;
  }  
  
  function modifyManagerAddr(address newManager) public{
    UserData memory userdata = ManagerToUserData[msg.sender];
    ManagerToUserData[newManager] = userdata;
    NFTIdToManager[userdata.NFTId] = newManager;
  }


  /*
    ManagerToUserData
  */
  function updateMerkleRoot(byte32 _merkleRoot) public {
      UserData storage userdata = ManagerToUserData[msg.sender];
      userdata.merkleRoot = _merkleRoot;
    
  }

   /*
    Query Data
  */
 
  function managerOfNFTId(uint NFTId) public view returns(address) {
      address addr = NFTIdToManager[NFTId];
      return addr;
  }

  function userDataOfNFTId(uint NFTId) public view returns(UserData memory){
      address addr = NFTIdToManager[NFTId];
      UserData memory userdata = ManagerToUserData[addr];
      return userdata;
  }

  function userDataOfManager(address managerAddr) public view returns(UserData memory){
      UserData memory userdata = ManagerToUserData[managerAddr];
      return userdata;
  }

  function availableOfNFTId(uint NFTId) public view returns(bool){
      return NFTIdToAvailable[NFTId];
  }

  function NFTIdOfManager(address managerAddr) public view returns(uint){
      UserData memory userdata = ManagerToUserData[managerAddr];
      return userdata.NFTId;
  }

  /*
  verify markle proof
  */
  function verify(
    bytes32 root,
    bytes32 leaf,
    bytes32[] calldata proof,
    uint256[] calldata positions
  )
    public
    pure
    returns (bool)
  {
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (positions[i] == 1) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    return computedHash == root;
  }
  /*
  for test
  */

   function verifyTest(
    bytes32 root,
    bytes32 leaf,
    bytes32[] calldata proof,
    uint256[] calldata positions
  )
    public
    pure
    returns (bytes32  [] memory)
  {
    bytes32 computedHash = leaf;
    bytes32  [] memory  allcomputedHash =  new bytes32[](proof.length+1);
    allcomputedHash[0];
    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (positions[i] == 1) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
        allcomputedHash[i] = computedHash;
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
        allcomputedHash[i] = computedHash;
      }
    }
    if(root==computedHash){

    }
    return allcomputedHash;
  }

  fallback () external payable{
    revert();
  }

  receive() external payable{
    revert();
  }
}
