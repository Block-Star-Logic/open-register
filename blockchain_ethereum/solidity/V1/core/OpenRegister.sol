//SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "https://github.com/Block-Star-Logic/open-version/blob/e161e8a2133fbeae14c45f1c3985c0a60f9a0e54/blockchain_ethereum/solidity/V1/interfaces/IOpenVersion.sol";

import "https://github.com/Block-Star-Logic/open-roles/blob/93764de97d40c04b150f51b92bf2a448f22fbd1f/blockchain_ethereum/solidity/v2/contracts/interfaces/IOpenRolesManaged.sol";


import "https://github.com/Block-Star-Logic/open-roles/blob/732f4f476d87bece7e53bd0873076771e90da7d5/blockchain_ethereum/solidity/v2/contracts/core/OpenRolesSecureCore.sol";

import "../interfaces/IOpenRegister.sol";


/**
 * @title Open Register
 * @author Block Star Logic 
 * @dev The Open Register is responsible for keeping track of all addresses operating in a given dApp estate. 
 */
contract OpenRegister is OpenRolesSecureCore, IOpenVersion, IOpenRegister, IOpenRolesManaged {

    using LOpenUtilities for address; 

    uint256 version = 22; 

    string name                     = "RESERVED_OPEN_REGISTER_CORE"; 

    string coreRole                 = "DAPP_CORE_ROLE";

    string derivativeAdminRole      = "DERIVATIVE_CONTRACTS_ADMIN_ROLE";

    string openAdminRole            = "RESERVED_OPEN_ADMIN_ROLE";

    string roleManagerCA            = "RESERVED_OPEN_ROLES_CORE";

    string [] defaultRoles          = [coreRole, derivativeAdminRole, openAdminRole];

    mapping(string=>bool) hasDefaultFunctionsByRole;
    mapping(string=>string[]) defaultFunctionsByRole;

    address [] coreAddressList; 
    address [] derivativeAddresList; 
    address [] userAddressList; 

    mapping(address=>bool) isUserAddressByUserAddress;
    mapping(address=>bool) hasUsageTypes; 
    mapping(address=>string[]) usageTypesByUserAddress; 

    mapping(address=>mapping(string=>uint256)) versionByNameByAddress; 
    mapping(string=>mapping(uint256=>address)) addressByVersionByName; 
    mapping(string=>uint256) nameByHighestVersion; 
    mapping(address=>uint256) versionByAddress; 
    mapping(address=>string) nameByAddress;   
    mapping(address=>bool) knownByAddress; 
  
    mapping(address=>bool) knownByDerivativeAddress; 
    mapping(address=>string) typeByDerivativeAddress; 

    mapping(string=>uint256[]) versionHistoryByName; 


    constructor(string memory _dAppName, address _openRolesAddress) OpenRolesSecureCore(_dAppName) { 
        setRoleManager(_openRolesAddress);   
        addConfigurationItem(_openRolesAddress);
        addConfigurationItem(name, self, version);
        initDefaultFunctionsForRoles();    
        registerInternal(self, name, version);
        IOpenVersion ov = IOpenVersion(_openRolesAddress);
        registerInternal(_openRolesAddress, ov.getName(), ov.getVersion());     
    }

    function getVersion() override view external returns (uint256 _version){
        return version; 
    }

    function getName() override view external returns (string memory _contractName){
        return name; 
    }

    function getDefaultRoles() override view external returns (string [] memory _roleNames){
        return defaultRoles; 
    }

    function hasDefaultFunctions(string memory _role) override view external returns(bool _hasFunctions){
        return hasDefaultFunctionsByRole[_role];
    } 

    function getDefaultFunctions(string memory _role) override view external returns (string [] memory _functions){
        return defaultFunctionsByRole[_role];
    }

    function getDapp() override view external returns (string memory _dapp){
        return dappName; 
    }

    function getAddress(string memory _addressName) override view external returns (address _address){
        return getAddressInternal(_addressName);
    }   

    function getName(address _address) override view external returns (string memory _name) {
        return nameByAddress[_address];
    }

    function getUserAddressUsage(address _address) override view external returns (string [] memory _usage){
        if(hasUsageTypes[_address]){
            return usageTypesByUserAddress[_address];
        }
        return new string[](0);
    }

    function isKnownAddress(address _address) override view external returns (bool _isKnown){
        return knownByAddress[_address];
    }

    function isDerivativeAddress(address _address) override view external returns (bool _isDerivativeAddress){
        return knownByDerivativeAddress[_address];
    }
    
    function getDerivativeAddressType(address _address) override view external returns (string memory _type){
        return typeByDerivativeAddress[_address];
    }

    function listAddresses() view external returns (address [] memory _addresses, string [] memory _names, uint256 [] memory _versions){
        _names = new string[](coreAddressList.length);
        _versions = new uint256[](coreAddressList.length);
        for(uint256 x = 0; x < coreAddressList.length; x++) {
            _names[x] = nameByAddress[coreAddressList[x]];
            _versions[x] = versionByAddress[coreAddressList[x]];
        }
        return (coreAddressList, _names, _versions);
    }

    function getDerivativeAddresses() view external returns (address [] memory _addresses, string [] memory _types) {
        _types = new string[](derivativeAddresList.length);
        for(uint256 x = 0; x < derivativeAddresList.length; x++){
            _types[x] = typeByDerivativeAddress[derivativeAddresList[x]];
        }
        return (derivativeAddresList, _types);
    }

    function getUserAddresses() view external returns (address [] memory _addresses){
        return userAddressList; 
    }

    function registerAddress(address _address, string memory _name, uint256 _version) override external returns (bool _registered){
        require(isSecure(coreRole, "registerAddress")," dapp core only "); 
        require(!knownByAddress[_address], " address already registered ");
        registerInternal(_address, _name, _version);
        return true; 
    }

    function isUserAddress(address _address) override view external returns (bool _isUserAddress){
        return isUserAddressByUserAddress[_address];
    }

    function registerUserAddress(address _address, string memory _usageType) override external returns (bool _registered){
        require(isSecure(coreRole, "registerUserAddress")," dapp core only "); 
        return registerUserAddressInternal(_address, _usageType);
    }

    function registerOpenVersionAddress(address _address) override external returns (bool _registered) {
        require(isSecure(coreRole, "registerOpenVersionAddress")," dapp core only "); 
        IOpenVersion ov = IOpenVersion(_address);        
        return registerInternal(_address, ov.getName(), ov.getVersion());
    }

    function deregisterAddress(address _address) override external returns (bool _deregistered){
        require(isSecure(coreRole, "deregisterAddress")," dapp core only "); 
        return deregisterInternal(_address);
    }

    function registerDerivativeAddress( address _address, string memory _type) override external returns (bool _registered){
        require(isSecure(derivativeAdminRole, "registerDerivativeAddress")," derivative contract admin only "); 
        knownByAddress[_address] = true; 
        knownByDerivativeAddress[_address] = true; 
        typeByDerivativeAddress[_address] = _type; 
        derivativeAddresList.push(_address);
        return true; 
    }

    function deregisterDerivativeAddress(address _address) override external returns (bool _deregistered){
        require(isSecure(derivativeAdminRole, "deregisterDerivativeAddress")," derivative contract admin only "); 
        return deregisterInternal(_address);
    }

    function clearRegister() external returns (bool _cleared){
        require(isSecure(openAdminRole, "clearRegister")," admin only "); 
        for(uint256 x = 0; x < coreAddressList.length; x++) {
            deregisterInternal(coreAddressList[x]);
        }
        return true; 
    }

    function notifyChangeOfAddress() external returns(bool _notified) {   
        require(isSecure(openAdminRole, "notifyChangeOfAddress"), " admin only ");                         
        address openRolesAddress_ = getAddressInternal(roleManagerCA);
        setRoleManager(openRolesAddress_);
        addConfigurationItem(openRolesAddress_);
        IOpenVersion ov = IOpenVersion(openRolesAddress_);
        registerInternal(openRolesAddress_, ov.getName(), ov.getVersion()); 
        return true; 
    }
    
    //==================================== INTERNAL ===================================

    function getAddressInternal(string memory _addressName) view internal returns(address _address){
        uint256 highestVersion_ = nameByHighestVersion[_addressName];
        return addressByVersionByName[_addressName][highestVersion_];
    }

    function registerUserAddressInternal(address  _address, string memory _usageType) internal returns (bool) {
        knownByAddress[_address]                = true;
        isUserAddressByUserAddress[_address]    = true;
        hasUsageTypes[_address]                 = true; 
        usageTypesByUserAddress[_address].push(_usageType);
        return true; 
    }

    function registerInternal(address _address, string memory _name, uint256 _version) internal returns (bool) {
        knownByAddress[_address] = true; 
        versionByNameByAddress[_address][_name] = _version; 
        addressByVersionByName[_name][_version] = _address; 

        uint256 oldVersion_ = nameByHighestVersion[_name];
        versionByAddress[_address] = _version; 
        versionHistoryByName[_name].push(_version);
        if(oldVersion_ < _version) { 
            nameByHighestVersion[_name] = _version;                         
        }

        nameByAddress[_address] = _name; 
        coreAddressList.push(_address);
        return true; 
    }

    function deregisterInternal (address _address) internal returns (bool) {
        delete knownByAddress[_address];

        if(isUserAddressByUserAddress[_address]) {
            delete isUserAddressByUserAddress[_address];
            delete hasUsageTypes[_address]; 
            delete usageTypesByUserAddress[_address];
            userAddressList = _address.remove(userAddressList);
            return true; 
        }

        if(knownByDerivativeAddress[_address]){        
            delete knownByDerivativeAddress[_address]; 
            delete typeByDerivativeAddress[_address]; 
            derivativeAddresList = _address.remove(derivativeAddresList);
            return true; 
        }

        string memory name_ = nameByAddress[_address];
        delete nameByAddress[_address];
        uint256 version_ = versionByNameByAddress[_address][name_];
        uint256[] memory versions_ = versionHistoryByName[name_];
        uint256 highestVersion_ = nameByHighestVersion[name_]; 
        if(version_ == highestVersion_) { 
            if(versions_.length > 2){ 
                uint256 nextIndex = versions_.length - 2; 
                uint256 nextHighestVersion_ = versions_[nextIndex];
                nameByHighestVersion[name_] = nextHighestVersion_;
            }
            else { 
                delete nameByHighestVersion[name_];
            }                      
        }
        delete versionByNameByAddress[_address][name_]; 
        delete addressByVersionByName[name_][version_]; 
        coreAddressList = _address.remove(coreAddressList);
        return true; 
    }

    function initDefaultFunctionsForRoles() internal { 
        hasDefaultFunctionsByRole[coreRole]  = true; 
        defaultFunctionsByRole[coreRole].push("registerAddress");
        defaultFunctionsByRole[coreRole].push("deregisterAddress");
        defaultFunctionsByRole[coreRole].push("clearRegister");
        defaultFunctionsByRole[coreRole].push("registerOpenVersionAddress");
        defaultFunctionsByRole[coreRole].push("registerUserAddress");

        hasDefaultFunctionsByRole[derivativeAdminRole] = true; 
        defaultFunctionsByRole[derivativeAdminRole].push("registerDerivativeAddress");
        defaultFunctionsByRole[derivativeAdminRole].push("deregisterDerivativeAddress");

        hasDefaultFunctionsByRole[openAdminRole] = true; 
        defaultFunctionsByRole[openAdminRole].push("clearRegister");
        defaultFunctionsByRole[openAdminRole].push("notifyChangeOfAddress");        
    }

}

