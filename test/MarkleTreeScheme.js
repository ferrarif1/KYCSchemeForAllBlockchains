const fs = require('fs');
const writeFileSync = require('fs');
const { MerkleTree } = require('merkletreejs')
const SHA256 = require('crypto-js/sha256')
const keccak256 = require('keccak256')
const { ethers } = require("hardhat");
var obj = require("../src/js/testAddress.js");
var testAddr = obj.array;


const generateMerkleTree = (data) => {
    const leaves = testAddr.map(x => keccak256(x));
    // console.log(leaves);
    const merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    const merkleRoot = merkleTree.getHexRoot();

    return [merkleRoot, merkleTree];
};

const getProofOfLeaf = (leafdata, tree) => {
    const proof = tree.getProof(leafdata);
    console.log("proof of " + buf2hex(leafdata) + " is " + proof.map(x => buf2hex(x.data)));
}

const checkProof = (leafdata, tree, root) => {
    if (!tree.verify(proof, leafdata, root)) {
        console.err("Verification failed");
        return false;
    }
}


const checkTree = (testAddrData, tree, root) => {
    for (const addr of testAddrData) {
        const leaf = keccak256(addr);
        const proof = tree.getProof(leaf);

        // hex proof for solidity byte32[] input
        // const hexProof = tree.getHexProof(leaf);

        if (!tree.verify(proof, leaf, root)) {
            console.err("Verification failed");
            return false;
        }
    }

    return true;
};




function testMarkle() {
    const leaves = ['a', 'b', 'c'].map(x => keccak256(x))
    const tree = new MerkleTree(leaves, keccak256)
    const root = tree.getRoot().toString('hex')
    const leaf = keccak256('a')
    const proof = tree.getProof(leaf)
    console.log(tree.verify(proof, leaf, root)) // true


    const badLeaves = ['a', 'x', 'c'].map(x => keccak256(x))
    const badTree = new MerkleTree(badLeaves, keccak256)
    const badLeaf = keccak256('x')
    const badProof = tree.getProof(badLeaf)
    console.log(tree.verify(badProof, leaf, root)) // false
}


function buf2hex(buffer) { // buffer is an ArrayBuffer
    return [...new Uint8Array(buffer)]
        .map(x => x.toString(16).padStart(2, '0'))
        .join('');
}


async function main(outputPath) {
    const [merkleRoot, merkleTree] = generateMerkleTree(testAddr);
    getProofOfLeaf(keccak256(testAddr[0]), merkleTree)
    if (checkTree(testAddr, merkleTree, merkleRoot)) {
        fs.writeFileSync(
            outputPath,
            JSON.stringify({
                root: merkleRoot,
                tree: merkleTree,
            })
        );

        console.log(`Successfully generate merkle tree to ${outputPath}.`);
    } else {
        console.err("Generate merkle tree failed.");
    }
    testMarkle()

    // testContractVerify
    const root = merkleTree.getRoot()
    const hexroot = merkleRoot
    const leaf = keccak256(testAddr[0]);
    const hexleaf = buf2hex(leaf)
    const proof = merkleTree.getProof(leaf)
    const hexproof = merkleTree.getProof(leaf).map(x => buf2hex(x.data))
    const positions = merkleTree.getProof(leaf).map(x => x.position === 'right' ? 1 : 0)

    console.log("hexroot = " + hexroot)
    console.log("hexleaf = ")
    console.log(hexleaf)
    console.log("hexproof = ")
    console.log(hexproof)
    console.log("positions = ")
    console.log(positions)
   

    const KYCManager = await ethers.getContractFactory("KYCManager");
    const kycManager = await KYCManager.deploy();
    console.log("KYCManager deployed to:", kycManager.address);
     
    const treeVerify = merkleTree.verify(proof, leaf, merkleRoot);
    console.log("tree.verify = ", treeVerify);

    const contractVerify = await kycManager.verify.call(hexroot, hexleaf, hexproof, positions);
    console.log("verified = ", contractVerify);
    
}

main("./test/outputMerkleTree.json");
