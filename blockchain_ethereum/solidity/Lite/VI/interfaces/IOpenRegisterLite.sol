// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;
/**
 * @title IOpenRegisterLite 
 * @dev the IOpenRegisterLite interface creates a registry for all contracts related to a dApp. It's purpose is to make the look up 
 * of stable contract versions and autoconfiguration easier, saving development time. 
 */
interface IOpenRegisterLite { 

    /**
     * @dev VersionedEntry is a represenation of all the named and versioned contracts in this registry 
     */
    struct VersionedEntry{ 
        /** * @dev contract address */
        address veAddress; 
        /** * @dev contract name */
        string name; 
        /** * @dev contract version */
        uint256 version;     
    }

    /**  
     * @dev this function returns whether the given name is known to the registry 
     * @param _name the name of the contract 
     * @return _isKnown true if the name is known
     */
    function isKnown(string memory _name) view external returns (bool _isKnown);

    /**  
     * @dev this function returns whether the given address is known to the registry 
     * @param _address the name of the contract 
     * @return _isKnown true if the address is known
     */
    function isKnown(address _address) view external returns (bool _isKnown);
    
    /**
     * @dev this function returns the address that has the given name 
     * @param _name the name of the address
     * @return _address the address that has the given name 
     */
    function getAddress(string memory _name) view external returns (address _address);
    
    /**
     * @dev this function returns the name of the given address
     * @param _address the address for which the name is sought
     * @return _name the name of the given address
     */
    function getName(address _address) view external returns (string memory _name);

    /** 
     * @dev this function lists all the addresses that are in this registry as versioned entries 
     * @return _versionedEntries list of entries in the registry 
     */ 
    function listAddresses() view external returns (VersionedEntry [] memory _versionedEntries);

}