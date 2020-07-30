pragma solidity ^0.6.0;

contract TenancyAgreement {
    
    uint rentPerWeek; // e.g. $300
    bool periodicLease; //Lease with no set enddate
    uint leaseEnd; //e.g. 52 weeks // set to 0 if periodic
    address primaryTenant; //e.g. 0x0weosjqwoeij231
    address public managerAddress;
    address public ownerAddress;
    bool holdingDeposit; //1 week of rent for holding
    uint rentalBondInWeeks; // e.g. 4 weeks of rent
    address factoryAddress;
    uint timeStart;
    uint totalPaid;
    bool oracleVerified;
    
    
    mapping (address => SecondaryTenant) secondaryTenants;
    
    LeaseExtensionProposal xtensionProposal;
    
    Payment[] public paymentsMade;
    
    //Represents a Payment, which can be checked for auditing
    struct Payment {
        address user;
        uint amountPayed;
        uint timePayed;
        address payedTo;
    }
    
    //The details of a SecondaryTent
    struct SecondaryTenant {
        bool isAccepted;
        uint newTenantRent;
        uint newTenantEndTime;
    }
    //The state of a LeaseExtensionProposal
    struct LeaseExtensionProposal {
        bool isValid;
        bool accepted;
        uint proposalTime;
        uint additionalWeeksFromProposal;
    }

    constructor(uint _rentPerWeek, bool _periodicLease, uint _leaseDuration, address _primaryTenant, address _managerAddress, address _ownerAddress, bool _holdingDesposit, uint _rentalBondInWeeks) public{
        rentPerWeek = _rentPerWeek;
        periodicLease = _periodicLease;
        leaseEnd = ((_leaseDuration)*1 weeks) + now;
        primaryTenant = _primaryTenant;
        managerAddress = _managerAddress;
        ownerAddress = _ownerAddress;
        holdingDeposit = _holdingDesposit;
        rentalBondInWeeks = _rentalBondInWeeks;
        factoryAddress = msg.sender;
        timeStart = now;
    }
    //Retrieve the rent amount owed from the current time
    function getAmountOwed() public view enforceProxy returns (uint){
        uint totalOverall = ((now - timeStart)/(1 weeks))*rentPerWeek;
        uint totalOwing = totalOverall - totalPaid;
        return totalOwing;
    }
    
    //Propose a lease extension as a property manager or a property owner
    function proposeLeaseExtension(address currUser, uint additionalWeeks) public enforceProxy {
        require (currUser == managerAddress || currUser == ownerAddress, "Only manager and owner have authority to extend lease");
        require (xtensionProposal.isValid == false, "There already exists a lease extension proposal");
        LeaseExtensionProposal memory newProp = LeaseExtensionProposal(true, false, now, additionalWeeks);
        xtensionProposal = newProp;
    }
    
    //Accept a lease extension as the primary tenant
    function acceptLeaseExtension(address currUser) public enforceProxy {
        require (currUser == primaryTenant, "You are not allowed to accept the Lease Extension");
        require (xtensionProposal.isValid == true, "There is no lease extension proposal");
        require (xtensionProposal.accepted == false, "xtension proposal has already been accepted");
        xtensionProposal.isValid = false;
        xtensionProposal.accepted = true;
        uint propTimeEnd = xtensionProposal.proposalTime + (xtensionProposal.additionalWeeksFromProposal * 1 weeks);
        if (propTimeEnd > leaseEnd) {
            leaseEnd = propTimeEnd;
        }
    }
    //Propose adding a Secondary Tenant
    function proposeAddTenant(address currUser, address newTenant, uint newTenantRent, uint newTenantDuration) public enforceProxy {
        require (currUser == primaryTenant, "Only the primary tenant can add secondary tenants");
        SecondaryTenant memory nT = SecondaryTenant(false, newTenantRent, now + ((newTenantDuration)*1 weeks));
        secondaryTenants[newTenant] = nT;
    }
    //As a secondary tenant, accept an invite
    function acceptAddTenant(address currUser) public enforceProxy {
        require (secondaryTenants[currUser].newTenantRent != 0, "There is no proposal for you to join as a secondary tenant");
        secondaryTenants[currUser].isAccepted = true;
    }
    //Payment goes to the primary tenants so that owner not worrying about multiple people.
    function payRentSecondaryTenant(address currUser, uint amount) public enforceProxy {
        require (secondaryTenants[currUser].isAccepted == true, "You are not a secondaryTenant");
        require (secondaryTenants[currUser].newTenantEndTime > now, "You're lease is finished");
        Payment memory newPayment = Payment(currUser, amount, now, primaryTenant);
        paymentsMade.push(newPayment);
    }

    
    //Pay Rent as Primary Tenant
    function payRent(address currUser, uint amount) public enforceProxy  {
        uint totalOverall = ((now - timeStart)/(1 weeks))*rentPerWeek;
        uint totalOwing = totalOverall - totalPaid;
        require(totalOwing - amount >= 0, "You are overpaying for your rent!");
        totalPaid += amount;
        Payment memory newPayment = Payment(currUser, amount, now, ownerAddress);
        paymentsMade.push(newPayment);
    }

    //Retrieve the bond as the primary tenant
    function retrieveBond(address currUser) public view enforceProxy returns (uint amount){
        require (primaryTenant == currUser, "You are now allowed to retrieve the bond");
        require (now > leaseEnd, "Cannot retrieve the bond before lease ends");
        uint addWeek = 0;
        if (holdingDeposit == true){
            addWeek = 1;
        }
        return ((rentalBondInWeeks+addWeek)*1 weeks);
    }
    
    //Change the rent as the property Manager or the property owner
    function changeRent(address currUser, uint newRent) public enforceProxy returns (bool success){
        require (currUser == managerAddress || currUser == ownerAddress, "You are not allowed to increase the rent");
        timeStart = now;
        totalPaid = 0;
        rentPerWeek = newRent;
        return true;
    }

    function getRentPerWeek() public view returns (uint rent) {
        return rentPerWeek;
    }
    
    function getHomeOwner() public view returns (address owner){
        return ownerAddress;
    }
    
    function getPrimaryTenant() public view returns(address primTenant){
        return primaryTenant;
    }
    
    modifier enforceProxy(){
        require (msg.sender == factoryAddress, "Must use factory Proxy");
        _;
    }


}
