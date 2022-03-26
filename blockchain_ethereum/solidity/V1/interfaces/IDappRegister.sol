//SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

interface  IDappRegister  { 

    function getAddress(string memory _addressName) view external returns (address _address);    

    function addAddresses(string [] memory _addressNames, address [] memory _addresses) external returns (bool _added);

    function replaceAddresses(string [] memory _addressNames, address [] memory _addresses) external returns (uint256 _replaced);

    function removeAddresses(string [] memory _addressNames) external returns (uint256 _removed);

    function registerKnownAddress(address _address) external returns (bool _registered);

    function deregisterKnownAddress(address _address) external returns (bool _deregistered);

    function registerDerivativeAddress( address _address) external returns (bool _registered);

    function deregisterDerivativeAddress(address _address) external returns (bool _deregistered); 

}