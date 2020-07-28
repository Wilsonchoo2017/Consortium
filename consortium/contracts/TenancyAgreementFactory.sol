pragma solidity ^0.6.0;

import "./TenancyAgreement.sol";
import "./ERC20.sol";


//https://www.fairtrading.nsw.gov.au/housing-and-property/renting/starting-a-tenancy#what

contract TenancyAgreementFactory {

    string tenantInformationStatement = "https://www.fairtrading.nsw.gov.au/__data/assets/pdf_file/0009/608382/Tenant-information-statement.pdf";

    struct PropertyManager {
        uint licenseNumber;
        address managerAddress;
    }

    struct PropertyOwner {
        bool exists;
        address propertyOwnerAddress;
    }

    // struct DisclosedPropertyDetails {
    //     bool plannedToBeSold; //Is the property planned to be sold
    //     bool subjectToCourtAction; // Is the property subject to court action where the mortgagee is trying to take possession of the property
    //     bool isStrataScheme; //Is the property in a strata scheme and a strata renewal committee is currently established for the strata scheme.
    //     bool affectedByNature; //Property has been affected by flooding from a natural weather event or bushfire in the last five years.
    //     bool significantHealthOrSafety; //Property has significant health or safety risks that would not be apparent to the tenant.
    //     bool sceneOfCrime; //Property has been the scene of a serious violent crime (e.g. murder or aggravated assault) in the last five years
    //     bool asbestosRegister; //Property is listed on the loose-fill asbestos insulation register
    //     bool drugManufactured; //Property has been used to manufacture or cultivate a prohibited drug or prohibited plant in the last two years
    //     bool fireSafetyIssues; //Property is part of a building where a fire safety or building product rectification order (or a notice of intention to issue one of these orders) has been issued for external combustible cladding
    //     bool parkingZoningIssues; //Property is affected by zoning or laws that will not allow a tenant to obtain a parking permit, and only paid parking is available in the area
    //     bool differentWasteServices; //Property is provided with any council waste services that are different to other properties in the council area
    //     bool sharedDriveWalkway; //Property has a driveway or walkway that others can legally use.

    // }

    struct TenancyProposal {
        uint rentPerWeek; // e.g. $300
        bool periodicLease; //Lease with no set enddate
        uint leaseDuration; //e.g. 5 months // set to 0 if periodic
        address primaryTenant; //e.g. 0x0weosjqwoeij231
        address managerAddress;
        address ownerAddress;
        bool holdingDeposit; //1 week of rent for holding
        uint disclosedDetails;
        uint rentalBondInWeeks; // e.g. 4 weeks of rent
        bool accepted;
        bool ownerApproved;
        bool isValid;
    }

    PropertyManager public owningPropertyManager;
    address public tokenAddress;
    address[7] public contractDetails;
    // Mapping from tenant address to Agreement
    mapping (address => address) public tenancyAgreements;
    uint currentProposalId = 0;
    mapping (address => TenancyProposal) public tenancyProposals; //TenancyProposals by tenant
    // mapping (uint => DisclosedPropertyDetails) public disclosedPropertyDetails;
    mapping (address => uint) public balances;
    ERC20 ercContract;

    // Creates a new lunch venue contract
    constructor(uint _licenseNumber, address _tokenAddress) public {
        PropertyManager memory newPropertyManager = PropertyManager({licenseNumber: _licenseNumber, managerAddress: msg.sender});
        owningPropertyManager = newPropertyManager;
        tokenAddress = _tokenAddress;
        ercContract = ERC20(tokenAddress);
    }

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

    function viewLeaseProposal() public view returns (uint rentPerWeek, bool periodicLease, uint leaseDuration,
                                                address managerAddress, address ownerAddress, bool holdingDeposit, uint rentalBondInWeeks){
        require (tenancyProposals[msg.sender].primaryTenant == msg.sender, "User does not have any active lease proposals!");
        TenancyProposal memory tp = tenancyProposals[msg.sender];
        return (tp.rentPerWeek, tp.periodicLease, tp.leaseDuration, tp.managerAddress, tp.ownerAddress, tp.holdingDeposit, tp.rentalBondInWeeks);
    }

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

    function getAmountOwedTenant() public view returns (uint amountOwed){
        address taAddr = tenancyAgreements[msg.sender];
        require (taAddr != address(0), "User does not have an active tenancyAgreement");
        TenancyAgreement ta = TenancyAgreement(taAddr);
        return ta.getAmountOwed();
    }


    function rejectLease() public {
        tenancyProposals[msg.sender].primaryTenant = address(0);
    }

    function ownerApproveLease(address _tenantAddress) public {
        TenancyProposal memory cp = tenancyProposals[_tenantAddress];
        require (msg.sender == cp.ownerAddress, "You are not the owner!");
        tenancyProposals[_tenantAddress].ownerApproved = true;
    }

    // @Rez - Extension
    // function disclosePropertyDetails(uint proposalId, bool _plannedToBeSold, bool _subjectToCourtAction, bool _isStrataScheme, bool _affectedByNature, bool _significantHealthOrSafety,
    //                                  bool _sceneOfCrime, bool _asbestosRegiser, bool _drugManufactured, bool _fireSafetyIssues, bool _parkingZoningIssues, bool _differentWasteServices,
    //                                  bool _sharedDriveWalkway) public {
    //     //TODO
    //     // TenancyProposal memory currProp = tenancyProposals[proposalId];


    // }


    function negotiatePriceTenant(uint newRent) public {
        TenancyProposal memory cp = tenancyProposals[msg.sender];
        require (msg.sender == cp.primaryTenant, "You are not allowed to negotiate the price");
        require (cp.isValid == true, "Lease is already under negotiation");
        tenancyProposals[msg.sender].rentPerWeek = newRent;
        tenancyProposals[msg.sender].isValid = false;
    }

    function negotiatePriceManagerOwner(address tenantAddress, uint newRent) public {
        TenancyProposal memory cp = tenancyProposals[tenantAddress];
        require (msg.sender == cp.managerAddress || msg.sender == cp.ownerAddress, "You are not allowed to negotiate price!");
        tenancyProposals[tenantAddress].rentPerWeek = newRent;
        tenancyProposals[tenantAddress].isValid = true;
    }


    function payRent(uint amount) public returns (bool success){
        address taAddr = tenancyAgreements[msg.sender];
        require (taAddr != address(0), "User does not have an active tenancyAgreement");
        TenancyAgreement ta = TenancyAgreement(taAddr);
        ta.payRent(msg.sender, amount);
        ercContract.transferFrom(msg.sender, ta.getHomeOwner(), amount);
        return true;
    }

    function acceptLease() public returns (TenancyAgreement leaseAgreementAddress) {
        // TenancyProposal memory newTenancyProposal
        //TODO
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
        uint amountPayable = weeksOfRentPayable*cp.rentPerWeek;
        bool isSuccess = ercContract.transferFrom(msg.sender, address(this), amountPayable);
        require(isSuccess == true, "Transfer Balance failed");
        return newTenancyAgreement;
    }

    function proposeLeaseExtension(address tenancyAddress, uint additionalWeeks) public {
        TenancyAgreement ta = TenancyAgreement(tenancyAddress);
        ta.proposeLeaseExtension(msg.sender, additionalWeeks);
    }

    function acceptLeaseExtension() public {
        address taAddr = tenancyAgreements[msg.sender];
        require (taAddr != address(0), "User does not have an active tenancyAgreement");
        TenancyAgreement ta = TenancyAgreement(taAddr);
        ta.acceptLeaseExtension(msg.sender);
    }

    function getTokenContract() public view returns (address){
        return tokenAddress;
    }

    function retrieveBond() public {
        address taAddr = tenancyAgreements[msg.sender];
        require (taAddr != address(0), "User does not have an active tenancyAgreement");
        TenancyAgreement ta = TenancyAgreement(taAddr);
        uint bondValue = ta.retrieveBond(msg.sender);
        bool isSuccess = ercContract.transfer(msg.sender, bondValue);
        require (isSuccess == true, "Failed to transfer bond to user");
    }


    function changeRent(address tenancyAddress, uint newRent) public {
        TenancyAgreement ta = TenancyAgreement(tenancyAddress);
        bool isSuccess = ta.changeRent(msg.sender, newRent);
        require(isSuccess == true, "Failed to Change rent");
    }
    //Duration is in weeks;
    function proposeAddSecondaryTenant(address newTenant, uint newTenantRent, uint newTenantDuration) public {
        address taAddr = tenancyAgreements[msg.sender];
        require (taAddr != address(0), "User does not have an active tenancyAgreement");
        TenancyAgreement ta = TenancyAgreement(taAddr);
        ta.proposeAddTenant(msg.sender, newTenant, newTenantRent, newTenantDuration);
    }

    function acceptAddSecondaryTenant(address tenancyAddress) public {
        TenancyAgreement ta = TenancyAgreement(tenancyAddress);
        ta.acceptAddTenant(msg.sender);
    }

    function payRentSecondaryTenant(address tenancyAddress) public {
        //TODO
    }

    modifier restricted() { // Only manager can do
        require (msg.sender == owningPropertyManager.managerAddress, "Can only be executed by the factory manager");
        _;
    }


}
