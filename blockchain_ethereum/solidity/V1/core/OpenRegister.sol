//SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;

import "https://github.com/Block-Star-Logic/open-version/blob/7127d35f5f65108c54472991e074f6847580682b/blockchain_ethereum/solidity/V1/interfaces/IOpenVersion.sol";

import "https://github.com/Block-Star-Logic/open-libraries/blob/7c34b2d947acdef28273cd789c2fe830913600d6/blockchain_ethereum/solidity/V1/libraries/LOpenUtilities.sol";

import "https://github.com/Block-Star-Logic/open-roles/blob/ed19a6420371f5270db47ca10fca1e430acf3f19/blockchain_ethereum/solidity/v2/contracts/interfaces/IOpenRoles.sol";

import "https://github.com/Block-Star-Logic/open-register/blob/49dc829a25d632c9933a3e6b4fbc7cdda28bd022/blockchain_ethereum/solidity/V1/interfaces/IAddressChangeListener.sol";

import "../interfaces/IOpenRegister.sol";
/**
 * @title Open Register
 * @author Block Star Logic 
 * @dev The Open Register is responsible for keeping track of all addresses operating in a given dApp estate. 
 */
contract OpenRegister is IOpenRegister, IOpenVersion {

    using LOpenUtilities for uint256;
    using LOpenUtilities for string; 
    using LOpenUtilities for string[];

    uint256 version = 9; 

    string name; 
    
    address rootAdmin; 

    IOpenRoles roleManager; 
    bool openRolesConfigured; 

    string [] configuredNames; 

    string [] oustandingPropagationList;

    mapping(string=>address) addressByName; 
    mapping(address=>bool) knownAddressStatusByAddress; 

    mapping(string=>bool) passValidByPass;

    mapping(string=>IAddressChangeListener[]) addressChangeListenerList; 
    mapping(string=>mapping(address=>bool)) isOnNotificationList;
    mapping(string=>mapping(address=>uint256)) notificationListIndex; 

    mapping(address=>bool) knownDerivativeAddressByAddress;

    mapping(address=>string) dAppByDerivativeAddress; 
    mapping(string=>address[]) derivativeAddressesByDApp; 
    mapping(string=>mapping(address=>bool)) knownDerivativeAddressByDApp; 

    mapping(string=>bool) hasBeenPropagated; 

    struct PassUsageStatistic { 
         string pass;
         uint256 dateUsed; 
         address userAddress; 
         string usageType; 
    }

    PassUsageStatistic [] usageStatistics; 

    constructor(string memory _name, address _rootAdmin) { 
        rootAdmin = _rootAdmin;
        knownAddressStatusByAddress[rootAdmin] = true;
        name = _name;  
    }

    function getVersion() override view external returns (uint256 _version){
        return version; 
    }

    function getName() override view external returns (string memory _contractName){
        return name; 
    }

    function getRoot() view external returns (address _rootAdmin){
        return rootAdmin; 
    }

    function isKnownAddress(address _address) override view external returns (bool _isKnown){
        return knownAddressStatusByAddress[_address];
    }

    function isDerivativeAddress(address _address) override view external returns (bool _isDerivative){
        return knownDerivativeAddressByAddress[_address];
    }

    function getDAppForDerivativeAddress(address _address) override view external returns (string memory _dApp){
        return dAppByDerivativeAddress[_address];
    }

    function getAddress(string memory _addressName)  override view external returns (address _address){
        return addressByName[_addressName];
    }

    function registerKnownAddress(address _address) override external returns (bool _registered){
        return registerKnownAddressInternal(_address);
    }

    function deregisterKnownAddress(address _address)  override external returns (bool _deregistered){
        doSecurity(msg.sender, "deregisterKnownAddress");
        knownAddressStatusByAddress[_address] = false; 
        return true; 
    }

    function addAddresses(string [] memory _addressNames, address [] memory _addresses)  override external returns (bool _added){        
        doSecurity(msg.sender, "addAddresses");
        for(uint256 x = 0; x < _addressNames.length; x++){
            string memory an = _addressNames[x];
            address a = _addresses[x];        
            knownAddressStatusByAddress[a] = true; 
            addressByName[an] = a; 
            hasBeenPropagated[an] = false; 
            oustandingPropagationList.push(an);            
        }
        return true; 
    }

    function replaceAddresses(string [] memory _addressNames, address [] memory _addresses)  override external returns (uint256 _replaced){
       doSecurity(msg.sender, "replaceAddresses");
       for(uint256 x = 0; x < _addressNames.length; x++){
            address a = _addresses[x];
            string memory an = _addressNames[x];
            addressByName[an] = a; 
            knownAddressStatusByAddress[a] = true;
            hasBeenPropagated[an] = false; 
            oustandingPropagationList.push(an);  
            _replaced++;          
        }
        return _replaced; 
    }

    function removeAddresses(string [] memory _addressNames) override external returns (uint256 _removed) {
        doSecurity(msg.sender, "removeAddresses");
        for(uint256 x = 0; x < _addressNames.length; x++){               
            string memory an = _addressNames[x];
            delete addressByName[an];                  
            _removed++;
        }
        return _removed; 
    }

    function registerDerivativeAddress(string memory _dApp, address _address) override external returns (bool _registered) { 
        doSecurity(msg.sender, "registerDerivativeAddress");
        if(!knownDerivativeAddressByDApp[_dApp][_address]){
            registerKnownAddressInternal(_address); 
            knownDerivativeAddressByAddress[_address] = true;         
            dAppByDerivativeAddress[_address] = _dApp; 
            derivativeAddressesByDApp[_dApp].push(_address);
            knownDerivativeAddressByDApp[_dApp][_address] = true; 
            return true; 
        }
        return false; 
    }

    function deregisterDerivativeAddress(address _address) override external returns (bool _deregistered) { 
        doSecurity(msg.sender, "deregisterDerivativeAddress");
        this.deregisterKnownAddress(_address); 
        delete knownDerivativeAddressByAddress[_address]; 
        return true; 
    }

    function registerAddressChangeListener(string [] memory _addressNames, address _addressChangeListenerAddress, string memory _registryPass) override external returns (bool _registered){
        require(passValidByPass[_registryPass], " Open Register : registerAddressChangeListener : 00 - valid pass required " );
        if(!knownAddressStatusByAddress[_addressChangeListenerAddress]){
            knownAddressStatusByAddress[_addressChangeListenerAddress] = true;
        }
        for(uint256 x = 0; x < _addressNames.length; x++) {
            string memory addressName_ = _addressNames[x];
            
            if(!isOnNotificationList[addressName_][_addressChangeListenerAddress]){
                IAddressChangeListener addressChangeListner = IAddressChangeListener(_addressChangeListenerAddress);            
                addressChangeListenerList[addressName_].push(addressChangeListner);
                notificationListIndex[addressName_][_addressChangeListenerAddress] = addressChangeListenerList[addressName_].length; 
                isOnNotificationList[addressName_][_addressChangeListenerAddress] = true;                 
            }
        }
        passValidByPass[_registryPass] = false; 
        addPassUsageStatistic(_registryPass, block.timestamp, msg.sender, "REGISTER");    
        return true; 
    }

    function deregisterAddressChangeListener(string [] memory _addressNames, address _addressChangeListenerAddress, string memory _registryPass) override external returns (bool _deregistered){
        require(passValidByPass[_registryPass], " Open Register : deregisterAddressChangeListener : 00 - valid pass required " );
        for(uint256 x = 0; x < _addressNames.length; x++){
             string memory addressName_ = _addressNames[x];
            if(isOnNotificationList[addressName_][_addressChangeListenerAddress]){            
                uint256 index = notificationListIndex[addressName_][_addressChangeListenerAddress];
                uint256 []memory indexes = new uint256[](1);
                indexes[0] = index; 
                addressChangeListenerList[addressName_] = removeNotifiable(indexes, addressChangeListenerList[addressName_]);
                isOnNotificationList[addressName_][_addressChangeListenerAddress] = false; 
            }
        }
        passValidByPass[_registryPass] = false; 
        addPassUsageStatistic(_registryPass, block.timestamp, msg.sender, "DEREGISTER");        
        return true; 
    }        

    function listConfigurations() view external returns (string[] memory _configuredNames, address[] memory _configuredAddresses) { 
        doSecurity(msg.sender, "listConfigurations");
        _configuredAddresses = new address[](configuredNames.length);
        for(uint256 x = 0; x < configuredNames.length; x++){
            _configuredAddresses[x] = addressByName[configuredNames[x]];
        }
        return (configuredNames,_configuredAddresses);
    }

    function addPass(string memory _pass) external returns (bool _added) {
        doSecurity(msg.sender, "addPass");
        if(!passValidByPass[_pass]) {
            passValidByPass[_pass] = true; 
            addPassUsageStatistic(_pass, block.timestamp, msg.sender, "ADD"); 
            return true; 
        }
        return false; 
    }

    function removePass(string memory _pass) external returns (bool _removed) {
        doSecurity(msg.sender,"removePass");
        if(passValidByPass[_pass]){
            delete passValidByPass[_pass]; 
            addPassUsageStatistic(_pass, block.timestamp, msg.sender, "REMOVE");    
            return true; 
        }
        return false; 
    }

    function getAllPassUsageStatistics() view external returns ( PassUsageStatistic [] memory usageStatistic) {
        return usageStatistics; 
    }
        

    function getRoleManager() view external returns (address _roleManager) {
        return address(roleManager);
    }

    function setRoleManager(address _roleManagerAddress) external returns (bool _set) {
        doSecurity(msg.sender, "setRoleManager");        
        roleManager = IOpenRoles(_roleManagerAddress);
        knownAddressStatusByAddress[_roleManagerAddress] = true; 
        return true; 
    }

    function setRootAdmin(address _newAdminAddress) external returns (bool _set)  { 
        doSecurity(msg.sender, "setRootAdminr");
        knownAddressStatusByAddress[_newAdminAddress] = true; 
        rootAdmin = _newAdminAddress; 
        return true; 
    }


    function propagateAddressChangeNotification(string memory _addressName) external returns(bool _recieved) {

        IAddressChangeListener [] memory addressChangeListenerList_ = addressChangeListenerList[_addressName];
        address address_ = addressByName[_addressName];
        uint256 pass = 0; 
        uint256 fail = 0; 
        for(uint256 x = 0; x < addressChangeListenerList_.length; x++ )        {
            if(addressChangeListenerList_[x].notifyChangeOfAddress(_addressName, address_)){
                pass++;
            }
            else {
                fail++;            
            }
        }
        _addressName.remove(oustandingPropagationList);
        hasBeenPropagated[_addressName] = true; 
        return true; 
    }
    
    //==================================== INTERNAL ===================================

    function doSecurity(address _user, string memory _function) view internal returns (bool _done) {
        if(openRolesConfigured) {
            //@todo implement IOpenRoles 
        }
        else {
            require(_user == rootAdmin, string(" Open Register ").append(_function).append(string(" 00 - admin only")));
        }        
        return true; 
    }

    function removeNotifiable(uint256 [] memory _indexesToRemove, IAddressChangeListener[] memory _addressChangeListenerList) pure internal returns (IAddressChangeListener[] memory _replacementList) {
        
        _replacementList = new IAddressChangeListener[](_addressChangeListenerList.length - _indexesToRemove.length);

        uint256 y = 0 ; 
        for(uint256 x =0; x < _addressChangeListenerList.length; x++ ){
            if(!x.isContained(_indexesToRemove)) {
                _replacementList[y] = _addressChangeListenerList[x];
            }
        }      
        return _replacementList; 
    }

    function addPassUsageStatistic(string memory _pass,
         uint256 _dateUsed, 
         address _userAddress,
         string memory _usageType ) internal returns (bool _added) {

        PassUsageStatistic memory pus = PassUsageStatistic({
            pass : _pass,
            dateUsed : _dateUsed,
            userAddress : _userAddress,  
            usageType : _usageType
        });
        usageStatistics.push(pus);
        return true; 
    }

    function registerKnownAddressInternal(address _address) internal returns (bool _registered){
        doSecurity(msg.sender, "registerKnownAddress");
        knownAddressStatusByAddress[_address] = true; 
        return true; 
    }
}