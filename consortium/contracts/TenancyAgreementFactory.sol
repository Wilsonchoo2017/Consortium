pragma solidity ^0.6.0;

import "./TenancyAgreement.sol";


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
    
    struct DisclosedPropertyDetails {
        bool plannedToBeSold; //Is the property planned to be sold
        bool subjectToCourtAction; // Is the property subject to court action where the mortgagee is trying to take possession of the property
        bool isStrataScheme; //Is the property in a strata scheme and a strata renewal committee is currently established for the strata scheme.
        bool affectedByNature; //Property has been affected by flooding from a natural weather event or bushfire in the last five years.
        bool significantHealthOrSafety; //Property has significant health or safety risks that would not be apparent to the tenant.
        bool sceneOfCrime; //Property has been the scene of a serious violent crime (e.g. murder or aggravated assault) in the last five years
        bool asbestosRegister; //Property is listed on the loose-fill asbestos insulation register
        bool drugManufactured; //Property has been used to manufacture or cultivate a prohibited drug or prohibited plant in the last two years
        bool fireSafetyIssues; //Property is part of a building where a fire safety or building product rectification order (or a notice of intention to issue one of these orders) has been issued for external combustible cladding
        bool parkingZoningIssues; //Property is affected by zoning or laws that will not allow a tenant to obtain a parking permit, and only paid parking is available in the area
        bool differentWasteServices; //Property is provided with any council waste services that are different to other properties in the council area
        bool sharedDriveWalkway; //Property has a driveway or walkway that others can legally use.
        
    }
    
    struct TenancyProposal {
        uint rentPerWeek; // e.g. $300
        bool periodicLease; //Lease with no set enddate
        uint leaseDuration; //e.g. 5 months // set to 0 if periodic
        address primaryTenant; //e.g. 0x0weosjqwoeij231
        bool hasManager;
        address ownerAddress;
        bool holdingDeposit; //1 week of rent for holding
        uint disclosedDetails;
        uint rentalBondInWeeks; // e.g. 4 weeks of rent
        bool accepted;
    }
    
    PropertyManager public owningPropertyManager;
    address public tokenAddress;
    // Mapping from tenant address to Agreement
    mapping (address => TenancyAgreement) public tenancyAgreements;
    uint currentProposalId = 0;
    mapping (uint => TenancyProposal) public tenancyProposals;
    mapping (uint => DisclosedPropertyDetails) public disclosedPropertyDetails;
    

    // Creates a new lunch venue contract
    constructor(uint _licenseNumber, address _tokenAddress) public {
        PropertyManager memory newPropertyManager = PropertyManager({licenseNumber: _licenseNumber, managerAddress: msg.sender});
        owningPropertyManager = newPropertyManager;
        tokenAddress = _tokenAddress;
    }
    
    function proposeLeaseAsOwner(address _tenant, uint _rentPerWeek, bool _periodicLease, uint _leaseDuration, bool _holdingDeposit, uint _rentalBondInWeeks) public returns (uint proposalId) {
        require (_rentalBondInWeeks <= 4, "Rental Bond cannot be more than 4 weeks for rent");
        TenancyProposal memory newTenancyProposal = TenancyProposal({
            rentPerWeek: _rentPerWeek,
            periodicLease: _periodicLease,
            leaseDuration: _leaseDuration,
            primaryTenant: _tenant,
            hasManager: false,
            ownerAddress: msg.sender,
            holdingDeposit: _holdingDeposit,
            disclosedDetails: currentProposalId,
            rentalBondInWeeks: _rentalBondInWeeks,
            accepted: false
        });
        tenancyProposals[currentProposalId] = newTenancyProposal;
        currentProposalId++;
        return currentProposalId-1;
    }
    
    function proposeLeaseAsManager() public {
        //TODO
    }
    
    function disclosePropertyDetails(uint proposalId, bool _plannedToBeSold, bool _subjectToCourtAction, bool _isStrataScheme, bool _affectedByNature, bool _significantHealthOrSafety,
                                     bool _sceneOfCrime, bool _asbestosRegiser, bool _drugManufactured, bool _fireSafetyIssues, bool _parkingZoningIssues, bool _differentWasteServices,
                                     bool _sharedDriveWalkway) public {
        //TODO
        // TenancyProposal memory currProp = tenancyProposals[proposalId];
        
                                         
    } 
    
    function acceptLease(uint proposalId) public payable returns (address leaseAgreementAddress) {
        // TenancyProposal memory newTenancyProposal
        //TODO
    }
 
    
    modifier restricted() { // Only manager can do
        require (msg.sender == owningPropertyManager.managerAddress, "Can only be executed by the factory manager");
        _;
    }
    
    
}
