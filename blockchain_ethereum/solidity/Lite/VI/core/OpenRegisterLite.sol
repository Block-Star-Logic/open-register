// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/Block-Star-Logic/open-version/blob/e161e8a2133fbeae14c45f1c3985c0a60f9a0e54/blockchain_ethereum/solidity/V1/interfaces/IOpenVersion.sol";
import "../interfaces/IOpenRegisterLite.sol";

contract OpenRegisterLite is IOpenRegisterLite, IOpenVersion { 

    string constant name = "RESERVED_OPEN_REGISTER_LITE"; 
    uint256 constant version = 1; 
    address self;

    address administrator; 
    mapping(string=>bool) isKnownName; 
    mapping(address=>bool) isKnownAddress; 
    mapping(string=>address) addressByName; 
    mapping(address=>string) nameByAddress; 

    address[] validAddresses; 
    address[] allAddresses; 
    mapping(address=>VersionedEntry) versionedEntryByAddress;

    constructor(address _administrator) {
        administrator = _administrator; 
        self = address(this);
        init();        
    }

    function getName() pure external returns (string memory _name){
        return name;
    }

    function getVersion() pure external returns (uint256 _version) {
        return version; 
    }

    function isKnown(string memory _name) view external returns (bool _isKnown){
        return isKnownName[_name];
    }

    function isKnown(address _address) view external returns (bool _isKnown){
        return isKnownAddress[_address];
    }

    function getAddress(string memory _name)view external returns (address _address){
        return addressByName[_name];
    }
    
    function getName(address _address)view external returns (string memory _name){
        return nameByAddress[_address];
    }

    function listAddresses() view external returns (VersionedEntry [] memory _versionedEntries){
        return getVersionedEntries(validAddresses);
    }

    function addVersionedAddress(address _address) external returns (bool _added){
        adminOnly(); 
        require(!isKnownAddress[_address], " known address ");
        IOpenVersion ov_ = IOpenVersion(_address);
        return addVersionedAddressInternal(_address, ov_.getName(), ov_.getVersion());
    }

    function addNonVersionedAddress(address _address, string memory _name) external returns (bool _added){
        adminOnly(); 
        require(!isKnownAddress[_address], " known address ");
        return addVersionedAddressInternal(_address, _name, 0);
    }

    function removeVersionedAddress(address _address) external returns (bool _removed){
        adminOnly(); 
        VersionedEntry memory  ve_ = versionedEntryByAddress[_address];
        
        delete versionedEntryByAddress[_address];
        delete isKnownAddress[_address];
        
        if(isKnownName[ve_.name]){
            if(addressByName[ve_.name] == _address){
                // valid 
                delete addressByName[ve_.name];
                delete isKnownName[ve_.name];                
                delete nameByAddress[_address];
                validAddresses = remove(_address, validAddresses);
            }
            else {
                // not valid 
            }
        }
        return true; 
    }


    function setAdministrator(address _address) external returns (bool) {
        adminOnly();
        administrator = _address; 
        return true; 
    }
    //======================================== INTERNAL ============================================

    function init() internal returns (bool _initiated){
       return addVersionedAddressInternal(self, name, version);
    }

    function addVersionedAddressInternal(address _address, string memory _name, uint256 _version)  internal returns (bool _added) {
        VersionedEntry memory ve_ = VersionedEntry({
                                                veAddress : _address,
                                                name : _name,
                                                version : _version
                                            });
        return addVersionedEntryInternal(ve_);          
    }

    function addVersionedEntryInternal(VersionedEntry memory _ve) internal returns (bool _added) {
        versionedEntryByAddress[_ve.veAddress] = _ve; 

        if(!isKnownName[_ve.name]) {
            isKnownName[_ve.name] = true; 
        }
        else { 
           validAddresses = remove(addressByName[_ve.name], validAddresses);
        }
        isKnownAddress[_ve.veAddress] = true; 
        nameByAddress[_ve.veAddress] = _ve.name; 
        addressByName[_ve.name] = _ve.veAddress; 
        validAddresses.push(_ve.veAddress);
        allAddresses.push(_ve.veAddress);
        return true; 
    }

    function remove(address a, address [] memory b) pure internal returns (address [] memory c) {
        c = new address[](b.length-1);
        uint256 y = 0; 
        for(uint256 x = 0; x < b.length; x++) {
            if(a != b[x]){
                c[y] = b[x];
                y++;
            }
        }
        return c; 
    }

    function getVersionedEntries(address [] memory _addresses)view  internal returns (VersionedEntry [] memory _versionedEntries) {
        _versionedEntries = new VersionedEntry[](_addresses.length);
        for(uint256 x = 0; x < _addresses.length; x++) {
            _versionedEntries[x] = versionedEntryByAddress[_addresses[x]];
        }
        return _versionedEntries; 
    }

    function adminOnly() view internal returns (bool _adminOnly){
        require(msg.sender == administrator, " admin only ");
        return true; 
    }
}