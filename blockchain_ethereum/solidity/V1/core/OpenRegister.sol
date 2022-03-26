//SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
 
import "https://github.com/Block-Star-Logic/open-roles/blob/fc410fe170ac2d608ea53e3760c8691e3c5b550e/blockchain_ethereum/solidity/v2/contracts/interfaces/IOpenRolesManaged.sol";
import "https://github.com/Block-Star-Logic/open-libraries/blob/16a705a5421984ca94dc72fff100cb406ac9aa96/blockchain_ethereum/solidity/V1/libraries/LOpenUtilities.sol";

import "../interfaces/IOpenRegister.sol";

import "../openblock/OpenRolesSecure.sol";

/**
 * @title Open Register
 * @author Block Star Logic 
 * @dev The Open Register is responsible for keeping track of all addresses operating in a given dApp estate. 
 */
contract OpenRegister is OpenRolesSecure, IOpenRegister, IOpenRolesManaged {

    using LOpenUtilities for address; 

    uint256 version = 10; 

    string name                     = "RESERVED_OPEN_REGISTER"; 

    string dApp; 

    string coreRole                 = "DAPP_CORE_ROLE";
    string derivativeAdminRole      = "DERIVATIVE_ADMIN_ROLE";

    string [] defaultRoles = [coreRole, derivativeAdminRole];

    string [] roleNames = [coreRole];

    mapping(string=>bool) hasDefaultFunctionsByRole;
    mapping(string=>string[]) defaultFunctionsByRole;

    address [] addressList; 
    address [] derivativeAddresList; 

    mapping(address=>bool) knownByAddress; 
    mapping(string=>address) addressByName; 
    mapping(address=>string) nameByAddress; 

    mapping(address=>bool) knownByDerivativeAddress; 
    mapping(address=>string) typeByDerivativeAddress; 


    constructor(string memory _dAppName, address _openRolesAddress) { 
        dApp = _dAppName; 
        setRoleManager(_openRolesAddress);   
        initDefaultFunctionsForRoles();         
    }

    function getVersion() override view external returns (uint256 _version){
        return version; 
    }

    function getName() override view external returns (string memory _contractName){
        return name; 
    }

    function getDefaultRoles() override view external returns (string [] memory _roleNames){
        return roleNames; 
    }

    function hasDefaultFunctions(string memory _role) override view external returns(bool _hasFunctions){
        return hasDefaultFunctionsByRole[_role];
    } 

    function getDefaultFunctions(string memory _role) override view external returns (string [] memory _functions){
        return defaultFunctionsByRole[_role];
    }

    function getDapp() override view external returns (string memory _dapp){
        return dApp; 
    }

    function getAddress(string memory _addressName) override view external returns (address _address){
        return addressByName[_addressName];
    }   

    function getName(address _address) override view external returns (string memory _name) {
        return nameByAddress[_address];
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

    function listAddresses() view external returns (address [] memory _addresses, string [] memory _names){
        _names = new string[](addressList.length);
        for(uint256 x = 0; x < addressList.length; x++) {
            _names[x] = nameByAddress[addressList[x]];
        }
        return (addressList, _names);
    }

    function getDerivativeAddresses() view external returns (address [] memory _addresses, string [] memory _types) {
        _types = new string[](derivativeAddresList.length);
        for(uint256 x = 0; x < derivativeAddresList.length; x++){
            _types[x] = typeByDerivativeAddress[derivativeAddresList[x]];
        }
        return (derivativeAddresList, _types);
    }

    function registerAddress(address _address, string memory _nameOrType) override external returns (bool _registered){
        require(isSecure(coreRole, "registerAddress")," dapp core only "); 
        registerInternal(_address, _nameOrType);
        return true; 
    }

    function registerOpenVersionAddress(address _address) override external returns (bool _registered) {
        require(isSecure(coreRole, "registerOpenVersionAddress")," dapp core only "); 
        string memory _name = IOpenVersion(_address).getName();
        return registerInternal(_address, _name);
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
        delete knownByAddress[_address];
        delete knownByDerivativeAddress[_address]; 
        delete typeByDerivativeAddress[_address]; 
        derivativeAddresList = _address.remove(derivativeAddresList);
        return true; 
    }

    function clearRegister() external returns (bool _cleared){
        require(isSecure(coreRole, "clearRegister")," dapp core only "); 
        for(uint256 x = 0; x < addressList.length; x++) {
            deregisterInternal(addressList[x]);
        }
        return true; 
    }
    
    //==================================== INTERNAL ===================================

    function registerInternal(address _address, string memory _name) internal returns (bool) {
        knownByAddress[_address] = true; 
        addressByName[_name] = _address; 
        nameByAddress[_address] = _name; 
        addressList.push(_address);
        return true; 
    }

    function deregisterInternal (address _address) internal returns (bool) {
        delete knownByAddress[_address]; 
        string memory name_ = nameByAddress[_address];
        delete nameByAddress[_address];
        delete addressByName[name_]; 
        addressList = _address.remove(addressList);
        return true; 
    }

    function initDefaultFunctionsForRoles() internal { 
        hasDefaultFunctionsByRole[coreRole]  = true; 
        defaultFunctionsByRole[coreRole].push("registerAddress");
        defaultFunctionsByRole[coreRole].push("deregisterAddress");

        hasDefaultFunctionsByRole[derivativeAdminRole] = true; 
        defaultFunctionsByRole[derivativeAdminRole].push("registerDerivativeAddress");
        defaultFunctionsByRole[derivativeAdminRole].push("deregisterDerivativeAddress");
        
    }

}

