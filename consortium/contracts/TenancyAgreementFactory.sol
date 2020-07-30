pragma solidity ^0.6.0;

// import "./SafeMath.sol";
import "./TenancyAgreement.sol";
import "./ERC20.sol";



contract TenancyAgreementFactory {
    


    //This defines the state of a Tenancy Proposal
    struct TenancyProposal {
        uint rentPerWeek; // e.g. $300
        bool periodicLease; //Lease with no set end date
        uint leaseDuration; //e.g. 5 months
        address primaryTenant;  //Address of the Primary Tenant
        address managerAddress; // Address of the Manager
        address ownerAddress; // Address of the Owner
        bool holdingDeposit; //1 week of rent for holding
        uint disclosedDetails; // Ignore: Extension Feature
        uint rentalBondInWeeks; // e.g. 4 weeks of rent
        bool accepted; // Has the TenancyProposal already been accepted
        bool ownerApproved; // Has the Owner approved the lease proposal
        bool isValid; // Is the TenancyProposal in a non-negotiation state
    }

    // Stores the details of the creator of the contract
    address contractOwner;
    uint public contractOwnerLicenseNumber;
    
    // Address of the ERC20 Token Smart Contract
    address public tokenAddress;
    // Mapping from tenant address to TenancyAgreement
    mapping (address => address) public tenancyAgreements;
    uint currentProposalId = 0;
    // Mapping from tenant address to TenancyProposal
    mapping (address => TenancyProposal) public tenancyProposals; //TenancyProposals by tenant

    //State of the ERC20 Contract
    ERC20 ercContract;

    //Creates an instance of the TenancyAgreementFactory
    constructor(uint _licenseNumber, address _tokenAddress) public {
        tokenAddress = _tokenAddress;
        ercContract = ERC20(tokenAddress);
        contractOwner = msg.sender;
        contractOwnerLicenseNumber = _licenseNumber;
    }
    
    //Propose a lease to a tenant as the owner
    function proposeLeaseAsOwner(address _tenant, uint _rentPerWeek, bool _periodicLease, uint _leaseDuration, bool _holdingDeposit, uint _rentalBondInWeeks) public returns (uint proposalId) {
        require (_rentalBondInWeeks <= 4, "Rental Bond cannot be more than 4 weeks for rent");
        TenancyProposal memory newTenancyProposal = TenancyProposal({
            rentPerWeek: _rentPerWeek,
            periodicLease: _periodicLease,
            leaseDuration: _leaseDuration,
            primaryTenant: _tenant,
            managerAddress: address(0),
            ownerAddress: msg.sender,
            holdingDeposit: _holdingDeposit,
            disclosedDetails: currentProposalId,
            rentalBondInWeeks: _rentalBondInWeeks,
            accepted: false,
            ownerApproved: true,
            isValid: true
        });
        require (tenancyProposals[_tenant].primaryTenant == address(0), "Tenant already has a proposed Lease");
        tenancyProposals[_tenant] = newTenancyProposal;
        currentProposalId++;
        return currentProposalId-1;
    }
    
    //View the leaseProposal as a tenant
    function viewLeaseProposal() public view returns (uint rentPerWeek, bool periodicLease, uint leaseDuration, 
                                                address managerAddress, address ownerAddress, bool holdingDeposit, uint rentalBondInWeeks) {
        require (tenancyProposals[msg.sender].primaryTenant == msg.sender, "User does not have any active lease proposals!");
        TenancyProposal memory tp = tenancyProposals[msg.sender];
        return (tp.rentPerWeek, tp.periodicLease, tp.leaseDuration, tp.managerAddress, tp.ownerAddress, tp.holdingDeposit, tp.rentalBondInWeeks);
    }
    
    //View the leaseProposal as anyone other than the tenant
    function viewLeaseProposalOther(address tenantAddress) public view returns (uint rentPerWeek, bool periodicLease, uint leaseDuration, 
                                                address managerAddress, address ownerAddress, bool holdingDeposit, uint rentalBondInWeeks) {
        require (tenancyProposals[tenantAddress].primaryTenant == tenantAddress, "Given user does not have any active lease proposals!");
        TenancyProposal memory tp = tenancyProposals[tenantAddress];
        return (tp.rentPerWeek, tp.periodicLease, tp.leaseDuration, tp.managerAddress, tp.ownerAddress, tp.holdingDeposit, tp.rentalBondInWeeks);
    }
    
    //Propose a lease as a Manager
    function proposeLeaseAsManager(address _tenant, uint _rentPerWeek, bool _periodicLease, uint _leaseDuration, bool _holdingDeposit, uint _rentalBondInWeeks, address _ownerAddress) public returns (uint proposalId) {
        require (_rentalBondInWeeks <= 4, "Rental Bond cannot be more than 4 weeks for rent");
        TenancyProposal memory newTenancyProposal = TenancyProposal({
            rentPerWeek: _rentPerWeek,
            periodicLease: _periodicLease,
            leaseDuration: _leaseDuration,
            primaryTenant: _tenant,
            managerAddress: msg.sender,
            ownerAddress: _ownerAddress,
            holdingDeposit: _holdingDeposit,
            disclosedDetails: currentProposalId,
            rentalBondInWeeks: _rentalBondInWeeks,
            accepted: false,
            ownerApproved: false,
            isValid: true
        });
        require (tenancyProposals[_tenant].primaryTenant == address(0), "Tenant already has a proposed Lease");
        tenancyProposals[_tenant] = newTenancyProposal;
        currentProposalId++;
        return currentProposalId-1;
    }
    
    //Check the amount of rent owed as a tenant
    function getAmountOwedTenant() public view returns (uint amountOwed){
        address taAddr = tenancyAgreements[msg.sender];
        require (taAddr != address(0), "User does not have an active tenancyAgreement");
        TenancyAgreement ta = TenancyAgreement(taAddr);
        return ta.getAmountOwed();
    }
    
    //Reject the lease as a tenant
    function rejectLease() public {
        require (tenancyProposals[msg.sender].accepted == false, "This tenancy has already been accepted");
        tenancyProposals[msg.sender].primaryTenant = address(0);
    }
    
    //Approve of a manager proposed lease, as the owner
    function ownerApproveLease(address _tenantAddress) public {
        TenancyProposal memory cp = tenancyProposals[_tenantAddress];
        require (msg.sender == cp.ownerAddress, "You are not the owner!");
        tenancyProposals[_tenantAddress].ownerApproved = true;
    }
    
    //Negotiate the price as a Tenant
    function negotiatePriceTenant(uint newRent) public {
        TenancyProposal memory cp = tenancyProposals[msg.sender];
        require (msg.sender == cp.primaryTenant, "You are not allowed to negotiate the price");
        require (cp.isValid == true, "Lease is already under negotiation");
        tenancyProposals[msg.sender].rentPerWeek = newRent;
        tenancyProposals[msg.sender].isValid = false;
    }
    
    //Negotiate the price as a Manager or Owner
    function negotiatePriceManagerOwner(address tenantAddress, uint newRent) public {
        TenancyProposal memory cp = tenancyProposals[tenantAddress];
        require (msg.sender == cp.managerAddress || msg.sender == cp.ownerAddress, "You are not allowed to negotiate price!");
        tenancyProposals[tenantAddress].rentPerWeek = newRent;
        tenancyProposals[tenantAddress].isValid = true;
    }
    
    
    //Accept the Lease as a Tenant
    function acceptLease() public returns (TenancyAgreement leaseAgreementAddress) {
        TenancyProposal memory cp = tenancyProposals[msg.sender];
        require (msg.sender == cp.primaryTenant, "You are not allowed to accept this lease");
        require (cp.accepted == false, "Tenancy agreement has already been accepted");
        require (cp.ownerApproved == true, "Owner has not yet approved of this Tenancy Proposal");
        require (cp.isValid == true, "Lease is not valid as still under negotiation");
        require (tenancyAgreements[msg.sender] == address(0), "User already has a tenancy agreement!");
        tenancyProposals[msg.sender].accepted = true;
        TenancyAgreement newTenancyAgreement = new TenancyAgreement(cp.rentPerWeek, cp.periodicLease, cp.leaseDuration, cp.primaryTenant, cp.managerAddress, cp.ownerAddress, cp.holdingDeposit, cp.rentalBondInWeeks);
        tenancyAgreements[msg.sender] = address(newTenancyAgreement);
        uint weeksOfRentPayable = cp.rentalBondInWeeks;
        if (cp.holdingDeposit == true) {
            weeksOfRentPayable+=1;
        }
        uint amountPayable = SafeMath.mul(weeksOfRentPayable,cp.rentPerWeek);
        bool isSuccess = ercContract.transferFrom(msg.sender, address(this), amountPayable);
        require(isSuccess == true, "Transfer Balance failed");
        return newTenancyAgreement;
    }

    //Pay the Rent as a Tenant
    function payRent(uint amount) public returns (bool success){
        address taAddr = tenancyAgreements[msg.sender];
        require (taAddr != address(0), "User does not have an active tenancyAgreement");
        TenancyAgreement ta = TenancyAgreement(taAddr);
        ta.payRent(msg.sender, amount);
        ercContract.transferFrom(msg.sender, ta.getHomeOwner(), amount);
        return true;
    }
    
    //Propose Lease Extension as a Manager or Owner
    function proposeLeaseExtension(address tenancyAddress, uint additionalWeeks) public {
        TenancyAgreement ta = TenancyAgreement(tenancyAddress);
        ta.proposeLeaseExtension(msg.sender, additionalWeeks);
    }
    
    //Accept Lease Extension as a Tenant
    function acceptLeaseExtension() public {
        address taAddr = tenancyAgreements[msg.sender];
        require (taAddr != address(0), "User does not have an active tenancyAgreement");
        TenancyAgreement ta = TenancyAgreement(taAddr);
        ta.acceptLeaseExtension(msg.sender);
    }
    
    //Get the address of the Token Contract
    function getTokenContract() public view returns (address){
        return tokenAddress;
    }
    
    //Retrieve Bond as the Primary Tenant
    function retrieveBond() public {
        address taAddr = tenancyAgreements[msg.sender];
        require (taAddr != address(0), "User does not have an active tenancyAgreement");
        TenancyAgreement ta = TenancyAgreement(taAddr);
        uint bondValue = ta.retrieveBond(msg.sender);
        bool isSuccess = ercContract.transfer(msg.sender, bondValue);
        require (isSuccess == true, "Failed to transfer bond to user");
    }
 
    //Change the Rent as a Manager or Owner
    function changeRent(address tenancyAddress, uint newRent) public {
        TenancyAgreement ta = TenancyAgreement(tenancyAddress);
        bool isSuccess = ta.changeRent(msg.sender, newRent);
        require(isSuccess == true, "Failed to Change rent");
    }
    //Invite a secondary tenant as the Primary Tenant
    function proposeAddSecondaryTenant(address newTenant, uint newTenantRent, uint newTenantDuration) public {
        address taAddr = tenancyAgreements[msg.sender];
        require (taAddr != address(0), "User does not have an active tenancyAgreement");
        TenancyAgreement ta = TenancyAgreement(taAddr);
        ta.proposeAddTenant(msg.sender, newTenant, newTenantRent, newTenantDuration);
    }
    
    //Accept an invitation as the secondary tenant
    function acceptAddSecondaryTenant(address tenancyAddress) public {
        TenancyAgreement ta = TenancyAgreement(tenancyAddress);
        ta.acceptAddTenant(msg.sender);
    }
    
    //Pay rent as the secondary tenant, which goes to the primary tenant
    function payRentSecondaryTenant(address tenancyAddress, uint amount) public {
       address taAddr = tenancyAgreements[tenancyAddress];
        require (taAddr != address(0), "User does not have an active tenancyAgreement");
        TenancyAgreement ta = TenancyAgreement(taAddr);
        ta.payRentSecondaryTenant(msg.sender, amount);
        ercContract.transferFrom(msg.sender, ta.getPrimaryTenant(), amount);
    }
    
    //Change the ERC20 token being used as the owner of the factory
    function changeTokenAddress(address newAddress) public {
        require (msg.sender == contractOwner, "You are not the owner of the factory");
        tokenAddress = newAddress;
        ercContract = ERC20(tokenAddress);
    }

    //Check the amount of rent owed as a tenant
    function getAmountOwedTenant() public view returns (uint amountOwed){
        address taAddr = tenancyAgreements[msg.sender];
        require (taAddr != address(0), "User does not have an active tenancyAgreement");
        TenancyAgreement ta = TenancyAgreement(taAddr);
        return ta.getAmountOwed();
    }
    
}
