// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "provable-eth-api/provableAPI.sol";

contract SatLink is Ownable, usingProvable {
    // Constants
    string IPFS_ADDRESS_TWITTER_BIO_VERIFIER = 'QmdTjf18eWHmHVpSZ4fvZXd2KEHhL9By5xSVWa4iuyNKai';
    string TWITTER_BIO_VERIFICATION_SUCCESS = '1';

    // Twitter
    string public twitterHandle = '';
    bool public twitterConnected = false;
    bool public twitterLinkRequested = false;
    uint public twitterOtp = 0;
    bytes32 private twitterOracleQueryId;

    event twitterOtpGenerated(string handle, uint otp);
    event twitter_link_success(string handle);
    event twitter_link_failure(string handle);
    event twitter_unlinked(string handle);

    constructor() public {}

    function() external payable {}

    function generateTwitterOtp(string memory handle) public onlyOwner returns(uint) {
        twitterOtp = rand();
        twitterHandle = handle;
        emit twitterOtpGenerated(handle, twitterOtp);
        twitterLinkRequested = true;
        return twitterOtp;
    }

    /**
     * Send request to oracle to get the Tweet containing the OTP
     */
    function queryTwitterConnection() public payable onlyOwner {
        require(twitterLinkRequested, "You must generate an OTP first!");
        require(provable_getPrice("computation") <= address(this).balance, "Please add some ETH to cover oracle query fee.");
        twitterOracleQueryId = provable_query(
            "computation",
            [
                IPFS_ADDRESS_TWITTER_BIO_VERIFIER,
                twitterHandle,
                uint2str(twitterOtp)
            ]
        );
    }

    function __callback(bytes32 _id, string memory _result, bytes memory _proof) public {
        require(msg.sender == provable_cbAddress(), "The caller of this function is not the offical Oraclize Callback Address.");
        require(twitterOracleQueryId == _id, "The Oraclize query ID does not match an Oraclize request made from this contract.");

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
        twitterLinkRequested = false;
        emit twitter_unlinked(twitterHandle);
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
