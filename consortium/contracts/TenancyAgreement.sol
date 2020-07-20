pragma solidity ^0.6.0;

contract TenancyAgreement {
    
    uint rentPerWeek; // e.g. $300
    bool periodicLease; //Lease with no set enddate
    uint leaseDuration; //e.g. 5 months // set to 0 if periodic
    address primaryTenant; //e.g. 0x0weosjqwoeij231
    bool hasManager;
    address ownerAddress;
    bool holdingDeposit; //1 week of rent for holding
    // uint disclosedDetails;
    uint rentalBondInWeeks; // e.g. 4 weeks of rent
    address tokenAddress;

    constructor(uint _rentPerWeek, bool _periodicLease, uint _leaseDuration, address _primaryTenant, bool _hasManager, address _ownerAddress, bool _holdingDesposit, uint _rentalBondInWeeks, address _tokenAddress) public{
        rentPerWeek = _rentPerWeek;
        periodicLease = _periodicLease;
        leaseDuration = _leaseDuration;
        primaryTenant = _primaryTenant;
        hasManager = _hasManager;
        ownerAddress = _ownerAddress;
        holdingDeposit = _holdingDesposit;
        rentalBondInWeeks = _rentalBondInWeeks;
        tokenAddress = _tokenAddress;
    }

    
    function payRent() public payable returns (bool success) {
        //TODO
    }

    function collectRent() public {
        //TODO
    }
    
    function retrieveBond() public returns (bool success){
        //TODO
    }
    
    function proposeExtendLease() public returns (bool success){
        //TODO
    }
    
    function increaseRent() public returns (bool success){
        //TODO
    }
    
    function addSecondaryTenant() public returns (bool success){
        //TODO
    }

}
