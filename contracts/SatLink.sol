// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "provable-eth-api/provableAPI.sol";

contract SatLink is Ownable, usingProvable {
    // Constants
    string IPFS_ADDRESS_TWITTER_BIO_VERIFIER = 'QmdTjf18eWHmHVpSZ4fvZXd2KEHhL9By5xSVWa4iuyNKai';
    string IPFS_ADDRESS_IPFS_HASH_VERIFIER = 'QmZhncMhYz5bu5MnV1zSCLTzUqXkisbErwZDUpnam41mPL';
    string TWITTER_BIO_VERIFICATION_SUCCESS = '1';
    string IPFS_HASH_VERIFICATION_SUCCESS = '1';

    // Enum of callback funcs
    // The first enum value is the default value, therefore we'll use it for "undefined"
    enum provableCallbackFunc {
        undefined,
        queryTwitterConnection,
        assertIpfsNonexistent,
        verifyIpfs
    }

    mapping (bytes32 => provableCallbackFunc) private provableCallbackFuncs;

    // Twitter vars
    string public twitterHandle = '';
    bool public twitterConnected = false;
    bool public twitterOtpGenerated = false;
    uint public twitterOtp = 0;

    // IPFS vars
    string public ipfsCid = '';
    bool public ipfsOtpGenerated = false;
    uint public ipfsOtp = 0;
    string public ipfsSaltedHash = '';
    bool public ipfsSaltedHashUploaded = false;
    bool public ipfsConnected = false;

    // Twitter events
    event twitter_otp_generated(string handle, uint otp);
    event twitter_link_success(string handle);
    event twitter_link_failure(string handle);
    event twitter_unlinked(string handle);

    // IPFS events
    event ipfs_currently_nonexistent(string cid);
    event ipfs_otp_generated(string cid, uint otp);
    event ipfs_salted_hash_uploaded(string cid, string salted_hash);
    event ipfs_link_success(string cid);
    event ipfs_link_failure(string cid);

    event provable_callback(bytes32 _id, string _result, bytes _proof);

    constructor() public {}

    function() external payable {}

    // Twitter funcs
    /**
     * 
     */
    function generateTwitterOtp(string memory handle) public onlyOwner returns(uint) {
        twitterOtp = rand();
        twitterHandle = handle;
        emit twitter_otp_generated(handle, twitterOtp);
        twitterOtpGenerated = true;
        return twitterOtp;
    }

    /**
     * Send request to oracle to get the Tweet containing the OTP
     */
    function queryTwitterConnection() public payable onlyOwner {
        require(twitterOtpGenerated, "You must generate an OTP first!");
        require(provable_getPrice("computation") <= address(this).balance, "Please add some ETH to cover oracle query fee.");
        bytes32 queryId = provable_query(
            "computation",
            [
                IPFS_ADDRESS_TWITTER_BIO_VERIFIER,
                twitterHandle,
                uint2str(twitterOtp)
            ]
        );
        provableCallbackFuncs[queryId] = provableCallbackFunc.queryTwitterConnection;
    }

    /**
     * 
     */
    function queryTwitterConnectionCallback(string memory _result) private {
        if (compareStrings(_result, TWITTER_BIO_VERIFICATION_SUCCESS)) {
            twitterConnected = true;
            emit twitter_link_success(twitterHandle);
        } else {
            emit twitter_link_failure(twitterHandle);
        }
    }

    /**
     * Unlink Twitter (i.e. remove the link)
     */
    function unlinkTwitter() public onlyOwner {
        twitterConnected = false;
        twitterOtpGenerated = false;
        emit twitter_unlinked(twitterHandle);
    }

    // IPFS funcs
    /**
     * 
     */
    function generateIpfsOtp() public onlyOwner {
        ipfsOtp = rand();
        ipfsOtpGenerated = true;
        emit ipfs_otp_generated(ipfsCid, ipfsOtp);
    }

    /**
     * 
     */
    function assertIpfsNonexistent(string memory cid, string memory saltedHash) public onlyOwner {
        require(ipfsOtpGenerated, "Please generate an OTP first.");
        require(provable_getPrice("ipfs ") <= address(this).balance, "Please add some ETH to cover oracle query fee.");
        ipfsCid = cid;
        ipfsSaltedHash = saltedHash;
        bytes32 queryId = provable_query("ipfs", cid);
        provableCallbackFuncs[queryId] = provableCallbackFunc.assertIpfsNonexistent;
    }

    /**
     * 
     */
    function assertIpfsNonexistentCallback(string memory _result) public {
        // If file already exists, simply return
        // There's an edge case here that the user is trying to upload an empty file (which already exists on IPFS..)
        if (!compareStrings(_result, '')) {
            return;
        }

        emit ipfs_currently_nonexistent(ipfsCid);

        ipfsSaltedHashUploaded = true;
        emit ipfs_salted_hash_uploaded(ipfsCid, ipfsSaltedHash);
    }

    /**
     * Verify that the IPFS file (pointed to by ipfsCid) matches the salted hash uploaded by the user
     */
    function verifyIpfs() public onlyOwner {
        require(ipfsOtpGenerated && ipfsSaltedHashUploaded, "You must first generate an OTP and provide the file CID and hash");
        require(provable_getPrice("computation") <= address(this).balance, "Please add some ETH to cover oracle query fee.");
        bytes32 queryId = provable_query(
            "computation",
            [
                IPFS_ADDRESS_IPFS_HASH_VERIFIER,
                ipfsCid,
                uint2str(ipfsOtp),
                ipfsSaltedHash
            ]
        );
        provableCallbackFuncs[queryId] = provableCallbackFunc.verifyIpfs;
    }

    /**
     * 
     */
    function verifyIpfsCallback(string memory _result) private {
        if (compareStrings(_result, IPFS_HASH_VERIFICATION_SUCCESS)) {
            ipfsConnected = true;
            emit ipfs_link_success(ipfsCid);
        } else {
            emit ipfs_link_failure(ipfsCid);
        }
    }

    /**
     * Callback function for provable. Looks up the query ID in provableCallbackFuncs to determin which callbank func
     * to execute.
     */
    function __callback(bytes32 _id, string memory _result, bytes memory _proof) public {
        require(msg.sender == provable_cbAddress(), "The caller of this function is not the offical Oraclize Callback Address.");
        require(
            provableCallbackFuncs[_id] != provableCallbackFunc.undefined,
            "The Oraclize query ID does not match an Oraclize request made from this contract."
        );

        emit provable_callback(_id, _result, _proof);

        if (provableCallbackFuncs[_id] == provableCallbackFunc.queryTwitterConnection) {
            delete(provableCallbackFuncs[_id]);
            return queryTwitterConnectionCallback(_result);
        } else if (provableCallbackFuncs[_id] == provableCallbackFunc.assertIpfsNonexistent) {
            delete(provableCallbackFuncs[_id]);
            return assertIpfsNonexistentCallback(_result);
        } else if (provableCallbackFuncs[_id] == provableCallbackFunc.verifyIpfs) {
            delete(provableCallbackFuncs[_id]);
            return verifyIpfsCallback(_result);
        }
    }

    /**
     * Generate a random number between 0-999.
     */
    function rand() private view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
            block.number
        )));

        return (seed - ((seed / 1000) * 1000));
    }

    /**
     * Return true if a and b are equal. false otherwise.
     */
    function compareStrings(string memory a, string memory b) private pure returns(bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }


}
