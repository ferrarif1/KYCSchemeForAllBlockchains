// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

interface KYCNFTInterface {
    function awardItem(address player, string memory tokenURI)
        external
        returns (uint256);

    function updateExpirationTime(uint256 tokenId, uint256 timestamp) external;
}

/*
n, accumulator is bigNumber，(May be out of range of uint256)，so use string as the value type
*/
contract KYCManager is Ownable {
    struct UserData {
        uint256 NFTId;
        bytes32 merkleRoot;
    }

    KYCNFTInterface kycNFTContract;

    mapping(uint256 => address) private NFTIdToManager;
    mapping(address => UserData) private ManagerToUserData;
    mapping(uint256 => bool) private NFTIdToAvailable;

    //set this first!
    function setKYCNFTContractAddress(address _kycnftContractAddr)
        public
        onlyOwner
    {
        kycNFTContract = KYCNFTInterface(_kycnftContractAddr);
    }

    function createKYCNFT(
        string memory tokenUrl,
        address manager,
        uint256 expirationTime
    ) external onlyOwner {
        //owner of NFT is KYCManager Contract
        address kycnftmanager = (address)(this);
        uint256 NFTId = kycNFTContract.awardItem(kycnftmanager, tokenUrl);
        kycNFTContract.updateExpirationTime(NFTId, expirationTime);
        setAvailableOfNFTId(NFTId, true);
        initManagerAddr(NFTId, manager);
    }

    function setAvailableOfNFTId(uint256 NFTId, bool _available)
        public
        onlyOwner
    {
        NFTIdToAvailable[NFTId] = _available;
    }

    /*
    NFTIdToManager
   */
    function initManagerAddr(uint256 NFTId, address manager) public onlyOwner {
        NFTIdToManager[NFTId] = manager;
        ManagerToUserData[manager].NFTId = NFTId;
    }

    function modifyManagerAddr(address newManager) public {
        UserData memory userdata = ManagerToUserData[msg.sender];
        ManagerToUserData[newManager] = userdata;
        NFTIdToManager[userdata.NFTId] = newManager;
    }

    /*
    ManagerToUserData
  */
    function updateMerkleRoot(bytes32 newMerkleRoot) public {
        UserData storage userdata = ManagerToUserData[msg.sender];
        userdata.merkleRoot = newMerkleRoot;
    }

    /*
    Query Data
  */

    function managerOfNFTId(uint256 NFTId) public view returns (address) {
        address addr = NFTIdToManager[NFTId];
        return addr;
    }

    function userDataOfNFTId(uint256 NFTId)
        public
        view
        returns (UserData memory)
    {
        address addr = NFTIdToManager[NFTId];
        UserData memory userdata = ManagerToUserData[addr];
        return userdata;
    }

    function userDataOfManager(address managerAddr)
        public
        view
        returns (UserData memory)
    {
        UserData memory userdata = ManagerToUserData[managerAddr];
        return userdata;
    }

    function availableOfNFTId(uint256 NFTId) public view returns (bool) {
        return NFTIdToAvailable[NFTId];
    }

    function NFTIdOfManager(address managerAddr) public view returns (uint256) {
        UserData memory userdata = ManagerToUserData[managerAddr];
        return userdata.NFTId;
    }

    /*
  verify merkle proof
  */
    function verifyMerkleProof(
        bytes32 root,
        bytes32 leaf,
        bytes32[] calldata proof,
        uint256[] calldata positions
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (positions[i] == 1) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        return computedHash == root;
    }

    function verifyKYCAuthProof(
        bytes32 leaf,
        bytes32[] calldata proof,
        uint256[] calldata positions,
        uint256 NFTId
    )public view returns (bool) {
        address addr = NFTIdToManager[NFTId];
        UserData memory userdata = ManagerToUserData[addr];
        bool result = verifyMerkleProof(userdata.merkleRoot, leaf, proof, positions);
        return result;
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
}
