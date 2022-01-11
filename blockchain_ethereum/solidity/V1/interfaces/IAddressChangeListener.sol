//SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title
 * @author
 * @dev
 */
interface IAddressChangeListener { 

    function notifyChangeOfAddress(string memory _addressName, address _address) external returns (bool _recieved);

}