// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./SatLink.sol";

contract SatLinkFactory {
  mapping(address => SatLink) public instances;

  event satlink_created(address creator, address _address);

  constructor() public {}

  function createSatLink() public {
    SatLink satlink = new SatLink();
    satlink.transferOwnership(msg.sender);
    instances[msg.sender] = satlink;
    emit satlink_created(msg.sender, address(satlink));
  }
}
