// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
n, accumulator is bigNumber，(May be out of range of uint256)，so use string as the value type
*/
contract IDNFT is Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _NFTIds;

    struct UserData {
        uint256 NFTId;
        uint256 g;
        bytes32 hashOfXpub; //optional
        string accumulator;
        string n;
    }
    mapping(uint256 => string) public SetUrlForNFTId;
    mapping(uint256 => uint256) public NFTIdToExpirationTime;
    mapping(uint256 => address) private NFTIdToAdmin;
    mapping(address => UserData) private AdminToUserData;
    mapping(uint256 => bool) private NFTIdToAvailable;

    constructor() ERC721("IDNFT", "IDNFT") {
        
    }

    function approveContract() public{
        setApprovalForAll(address(this), true);
    }

    function approveOwner() public{
        setApprovalForAll(address(owner()), true);
    }

    /*
   mint ID NFT
   NFT_Data:HashCommitment(Xpub)，Issuer, Approved Scope of Business:[ICO, NFT Marketplace]
   */
    function beforeMint(
        address to,
        string memory tokenURI,
        uint256 expirationTime
    ) public onlyOwner {
        //set NFT data
        _NFTIds.increment();
        uint256 newItemId = _NFTIds.current();
        SetUrlForNFTId[newItemId] = tokenURI;

        //expiration time
        updateExpirationTime(newItemId, expirationTime);
        //unlock
        manageIDNFT(newItemId, true);
        //link data with account
        AdminToUserData[to].NFTId = newItemId;
        NFTIdToAdmin[newItemId] = to;
    }

    // invoke by user
    function mintIDNFT() public returns (uint256) {
        uint256 nftid = AdminToUserData[msg.sender].NFTId;
        require(nftid > 0, "The NFTID should exist");
        string memory tokenURI = SetUrlForNFTId[nftid];
        _mint(msg.sender, nftid);
        _setTokenURI(nftid, tokenURI);
        approve(address(owner()), nftid);
        // approve(address(this), nftid);
        return nftid;
    }

     function justMint(
        address to,
        string memory tokenURI,
        uint256 expirationTime
    ) public onlyOwner {
        //set NFT data
        _NFTIds.increment();
        uint256 newItemId = _NFTIds.current();
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);

        //expiration time
        updateExpirationTime(newItemId, expirationTime);
        //unlock
        manageIDNFT(newItemId, true);
        //link data with account
        AdminToUserData[to].NFTId = newItemId;
        NFTIdToAdmin[newItemId] = to;
    }

  

    /*
    override _transfer()
    only by owner
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(msg.sender == owner(),"caller must be owner"); //限制普通用户不能转，只能由owner转
    }
    

    /*
    manageIDNFT： temporary freeze
    */
    function manageIDNFT(uint256 NFTId, bool approveOrLock) public onlyOwner {
        NFTIdToAvailable[NFTId] = approveOrLock;
    }

    /*
    modifyAdminAddr: transfer 
    */
    function modifyAdminAddr(address oldAdmin, address newAdmin)
        public
        onlyOwner
    {
        bool newAdminIsContract = isContract(newAdmin);
        require(
            newAdminIsContract != true,
            "The newAdmin should be an EOA account!"
        );
        UserData memory userdata = AdminToUserData[oldAdmin];
        uint256 nftid = userdata.NFTId;
        require(nftid > 0, "The user does not exist!");
        AdminToUserData[newAdmin] = userdata;
        NFTIdToAdmin[userdata.NFTId] = newAdmin;
        transferFrom(oldAdmin, newAdmin, nftid);
    }

    /*
    Expiration Time
    */
    function updateExpirationTime(uint256 NFTId, uint256 timestamp)
        public
        onlyOwner
    {
        require(NFTId <= _NFTIds.current());
        NFTIdToExpirationTime[NFTId] = timestamp;
    }

    /*
    update accumulator data
    */

    function updateAccumulator(
        string memory _accumulator,
        string memory _n,
        uint256 _g
    ) public {
        UserData storage userdata = AdminToUserData[msg.sender];
        userdata.accumulator = _accumulator;
        userdata.n = _n;
        userdata.g = _g;
    }

    /*
    update Xpub
    */
    function updateAccumulator(bytes32 _hashOfXpub) public {
        UserData storage userdata = AdminToUserData[msg.sender];
        userdata.hashOfXpub = _hashOfXpub;
    }

    /*
    Query Data
   */

    function managerOfNFTId(uint256 NFTId) public view returns (address) {
        address addr = NFTIdToAdmin[NFTId];
        return addr;
    }

    function userDataOfNFTId(uint256 NFTId)
        public
        view
        returns (UserData memory)
    {
        address addr = NFTIdToAdmin[NFTId];
        UserData memory userdata = AdminToUserData[addr];
        return userdata;
    }

    function userDataOfManager(address managerAddr)
        public
        view
        returns (UserData memory)
    {
        UserData memory userdata = AdminToUserData[managerAddr];
        return userdata;
    }

    function availableOfNFTId(uint256 NFTId) public view returns (bool) {
        return NFTIdToAvailable[NFTId];
    }

    function NFTIdOfManager(address managerAddr) public view returns (uint256) {
        UserData memory userdata = AdminToUserData[managerAddr];
        return userdata.NFTId;
    }


    function expirationTimeOfNFTId(uint256 NFTId)
        public
        view
        returns (uint256)
    {
        return NFTIdToExpirationTime[NFTId];
    }


    //untils
    function isContract(address account) public view returns (bool) {
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(account)
        }

        return (codeHash != accountHash && codeHash != 0x0);
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
}
