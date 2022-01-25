//SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;
/**
 * @title Open Register
 * @author Block Star Logic 
 * @dev
 */

interface IOpenRegister {

    function isKnownAddress(address _address) view external returns (bool _isKnown);

    function isDerivativeAddress(address _address) view external returns (bool _isDerivative);

    function getDAppForDerivativeAddress(address _address) view external returns (string memory _dApp);

    function getAddress(string memory _addressName) view external returns (address _address);    

    function addAddresses(string [] memory _addressNames, address [] memory _addresses) external returns (bool _added);

    function replaceAddresses(string [] memory _addressNames, address [] memory _addresses) external returns (uint256 _replaced);

    function removeAddresses(string [] memory _addressNames) external returns (uint256 _removed);

    function registerAddressChangeListener(string [] memory _addressNames, address _addressChangeListenerAddress, string memory _registryPass) external returns (bool _registered);

    function deregisterAddressChangeListener(string [] memory _addressNames, address _addressChangeListenerAddress,  string memory _registryPass) external returns (bool _deregistered);

    function registerKnownAddress(address _address) external returns (bool _registered);

    function deregisterKnownAddress(address _address) external returns (bool _deregistered);

    function registerDerivativeAddress(string memory _dApp, address _address) external returns (bool _registered);

    function deregisterDerivativeAddress(address _address) external returns (bool _deregistered); 

}