//"SPDX-License-Identifier: APACHE 2.0"

pragma solidity >=0.8.0 <0.9.0;

import "./IOpenRegister.sol";
import "./IOpenVersion.sol";

import "./LOpenUtilities.sol";

import "./IAddressChangeListener.sol";

import "https://github.com/Block-Star-Logic/open-roles/blob/main/blockchain_ethereum/solidity/v2/contracts/interfaces/IOpenRoles.sol";

contract OpenRegister is IOpenRegister, IOpenVersion {

    using LOpenUtilities for uint256;

    uint256 version = 4; 

    string name; 
    
    address rootAdmin; 

    IOpenRoles roleManager; 
    bool openRolesConfigured; 

    mapping(string=>address) addressByName; 
    mapping(address=>bool) knownAddressStatusByAddress; 

    mapping(string=>bool) passValidByPass;

    mapping(string=>IAddressChangeListener[]) addressChangeListenerList; 
    mapping(string=>mapping(address=>bool)) isOnNotificationList;
    mapping(string=>mapping(address=>uint256)) notificationListIndex; 

    struct PassUsageStatistic { 
         string pass;
         uint256 dateUsed; 
         address userAddress; 
         string usageType; 
    }

    PassUsageStatistic [] usageStatistics; 

    constructor(string memory _name, address _rootAdmin) { 
        rootAdmin = _rootAdmin;
        name = _name;  
    }

    function getVersion() override view external returns (uint256 _version){
        return version; 
    }

    function getName() override view external returns (string memory _contractName){
        return name; 
    }

    function isKnownAddress(address _address) override view external returns (bool _isKnown){
        return knownAddressStatusByAddress[_address];
    }

    function registerKnownAddress(address _address) override external returns (bool _registered){
        doSecurity(msg.sender, "registerKnownAddress");
        knownAddressStatusByAddress[_address] = true; 

        return true; 
    }

    function deregisterKnownAddress(address _address)  override external returns (bool _deregistered){
        doSecurity(msg.sender, "deregisterKnownAddress");
        knownAddressStatusByAddress[_address] = false; 
        return true; 
    }

    function getAddress(string memory _addressName)  override view external returns (address _address){
        return addressByName[_addressName];
    }

    function addAddresses(string [] memory _addressNames, address [] memory _addresses)  override external returns (bool _added){        
        doSecurity(msg.sender, "addAddresses");
        for(uint256 x = 0; x < _addressNames.length; x++){
            address a = _addresses[x];
            string memory an = _addressNames[x];
            knownAddressStatusByAddress[a] = true; 
            addressByName[an] = a; 
            propagateAddressChangeNotification(an, a);
        }
        return true; 
    }

    function replaceAddresses(string [] memory _addressNames, address [] memory _addresses)  override external returns (uint256 _replaced){
       doSecurity(msg.sender, "replaceAddresses");
       for(uint256 x = 0; x < _addressNames.length; x++){
            address a = _addresses[x];
            string memory an = _addressNames[x];
            addressByName[an] = a; 
           propagateAddressChangeNotification(an, a);
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

    function registerAddressChangeListener(string [] memory _addressNames, address _addressChangeListenerAddress, string memory _registryPass) override external returns (bool _registered){
        require(passValidByPass[_registryPass], " registerAddressChangeListener 00 - valid pass only " );
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
        require(passValidByPass[_registryPass], " deregisterAddressChangeListener 00 - valid pass only " );
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
        return true; 
    }

    function setRootAdmin(address _newAdminAddress) external returns (bool _set)  { 
        doSecurity(msg.sender, "setRootAdminr");
        rootAdmin = _newAdminAddress; 
        return true; 
    }

    function propagateAddressChangeNotification(string memory _addressName, address _address) internal returns(bool _recieved) {

        IAddressChangeListener [] memory addressChangeListenerList_ = addressChangeListenerList[_addressName];
        uint256 pass = 0; 
        uint256 fail = 0; 
        for(uint256 x = 0; x < addressChangeListenerList_.length; x++ )        {
            if(addressChangeListenerList_[x].notifyChangeOfAddress(_addressName, _address)){
                pass++;
            }
            else {
                fail++;            
            }
        }
        return true; 
    }
    
    function doSecurity(address _user, string memory _function) view internal returns (bool _done) {
        if(openRolesConfigured) {
            //@todo implement IOpenRoles 
        }
        else {
            require(_user == rootAdmin, " Open Register 00 - admin only");
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
}