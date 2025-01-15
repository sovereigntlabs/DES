// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IERC5192.sol";

contract DecentralizedEmploymentSystem is ERC721, IERC5192 {
    using Counters for Counters.Counter;

    // Counters
    Counters.Counter private _companyIds;
    Counters.Counter private _employeeTokenIds;
    Counters.Counter private _contractIds;

    struct Review {
        uint256 rating;
        string comments;
        address reviewer;
    }

    // Structs
    struct Company {
        string name;
        string industry;
        address owner;
        uint256[] employeeIds;
        bool isActive;
    }

    struct EmployeeDetails {
        uint256 tokenId;
        uint256 companyId;
        uint256[] contractIds;
    }

    struct Contract {
        uint256 companyId;
        uint256 employeeTokenId;
        uint256 salary;
        uint256 duration;
        uint256 startTime;
        string responsibilities;
        string terminationConditions;
        ContractStatus status;
        uint256 balance;
        address employee;
        address arbitrator;
    }

    enum ContractStatus {
        Created,
        Active,
        Disputed,
        Terminated,
        Completed
    }

    // Mappings
    mapping(uint256 => Company) private companies;
    mapping(uint256 => Contract) private contracts;
    mapping(address => EmployeeDetails) private employeeDetails;
    mapping(uint256 => Review[]) private contractReviews;
    mapping(uint256 => uint256[]) private employeeContracts;
    mapping(address => bool) private registeredEmployees;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => bool) private _locked;

    // Events
    event CompanyRegistered(
        uint256 companyId,
        address owner,
        string name,
        string industry
    );
    event EmployeeTokenMinted(uint256 tokenId, address employee);
    event ContractCreated(
        uint256 contractId,
        uint256 companyId,
        uint256 employeeTokenId,
        uint256 salary,
        uint256 duration
    );
    event ContractExecuted(uint256 contractId);
    event SalaryDeposited(uint256 contractId, uint256 amount);
    event SalaryReleased(uint256 contractId, address employee);
    event DisputeRaised(uint256 contractId, address raisedBy);
    event DisputeResolved(uint256 contractId, bool decisionForEmployee);
    event ContractTerminated(uint256 contractId, string reason);
    event ReviewSubmitted(uint256 contractId, uint256 rating, string comments);

    // Constructor
    constructor() ERC721("EmployeeToken", "EMPT") {}

    // Modifiers
    modifier onlyCompanyOwner(uint256 companyId) {
        require(companies[companyId].owner == msg.sender, "Not company owner");
        _;
    }

    modifier onlyActiveCompany(uint256 companyId) {
        require(companies[companyId].isActive, "Company not active");
        _;
    }

    modifier contractExists(uint256 contractId) {
        require(
            contractId > 0 && contractId <= _contractIds.current(),
            "Invalid contract"
        );
        _;
    }

    modifier arbitratorExists(uint256 contractId) {
        require(
            contracts[contractId].arbitrator == msg.sender,
            "Not valid arbitrator"
        );
        _;
    }

    // Override the _baseURI function from ERC721
    function _baseURI() internal pure override returns (string memory) {
        return ""; // Base URI if you want to use it, or leave empty
    }

    // Override tokenURI function to return the full URI for a token
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _ownerOf(tokenId) != address(0),
            "ERC721: URI query for nonexistent token"
        );
        return _tokenURIs[tokenId];
    }

    // Implement the required functions from IERC5192
    function locked(uint256 tokenId) external view override returns (bool) {
        require(
            ownerOf(tokenId) != address(0),
            "ERC5192: Query for nonexistent token"
        );
        return _locked[tokenId];
    }

    // Override transfer functions to prevent transfer if locked
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        address from = super._update(to, tokenId, auth);

        // Allow minting, but prevent transfers if locked
        if (from != address(0)) {
            require(!_locked[tokenId], "ERC5192: Token is locked");
        }

        return from;
    }

    // Company Management Functions
    function registerCompany(
        string calldata name,
        string calldata industry
    ) external returns (uint256 companyId) {
        _companyIds.increment();
        companyId = _companyIds.current();

        companies[companyId] = Company({
            name: name,
            industry: industry,
            owner: msg.sender,
            employeeIds: new uint256[](0),
            isActive: true
        });

        emit CompanyRegistered(companyId, msg.sender, name, industry);
    }

    function mintEmployeeToken(
        uint256 companyId,
        address employee,
        string calldata metadataURI
    )
        external
        onlyCompanyOwner(companyId)
        onlyActiveCompany(companyId)
        returns (uint256 tokenId)
    {
        require(!registeredEmployees[employee], "Employee already registered");

        _employeeTokenIds.increment();
        tokenId = _employeeTokenIds.current();

        _safeMint(employee, tokenId);
        _tokenURIs[tokenId] = metadataURI;
        _locked[tokenId] = true; // Lock the token
        registeredEmployees[employee] = true;

        // Store the tokenId in company's employeeIds array
        companies[companyId].employeeIds.push(tokenId);

        emit Locked(tokenId); // Emit the locked event
        emit EmployeeTokenMinted(tokenId, employee);
    }

    function createContract(
        uint256 companyId,
        uint256 employeeTokenId,
        uint256 salary,
        uint256 duration,
        string calldata responsibilities,
        string calldata terminationConditions,
        address arbitrator
    )
        external
        onlyCompanyOwner(companyId)
        onlyActiveCompany(companyId)
        returns (uint256 contractId)
    {
        _contractIds.increment();
        contractId = _contractIds.current();

        address employee = ownerOf(employeeTokenId);

        contracts[contractId] = Contract({
            companyId: companyId,
            employeeTokenId: employeeTokenId,
            salary: salary,
            duration: duration,
            startTime: 0,
            responsibilities: responsibilities,
            terminationConditions: terminationConditions,
            status: ContractStatus.Created,
            balance: 0,
            employee: employee,
            arbitrator: arbitrator
        });

        employeeContracts[employeeTokenId].push(contractId);
        companies[companyId].employeeIds.push(employeeTokenId);

        emit ContractCreated(
            contractId,
            companyId,
            employeeTokenId,
            salary,
            duration
        );
    }

    function executeContract(
        uint256 contractId
    ) external contractExists(contractId) {
        Contract storage contract_ = contracts[contractId];
        require(
            contract_.status == ContractStatus.Created,
            "Invalid contract status"
        );
        require(msg.sender == contract_.employee, "Only employee can execute");

        contract_.status = ContractStatus.Active;
        contract_.startTime = block.timestamp;

        emit ContractExecuted(contractId);
    }

    // Payment System Functions
    function depositSalary(
        uint256 contractId
    ) external payable contractExists(contractId) {
        Contract storage contract_ = contracts[contractId];
        require(
            contract_.status == ContractStatus.Active,
            "Contract not active"
        );
        require(msg.value > 0, "Invalid amount");

        contract_.balance += msg.value;

        emit SalaryDeposited(contractId, msg.value);
    }

    function releaseSalary(
        uint256 contractId
    ) external contractExists(contractId) {
        Contract storage contract_ = contracts[contractId];
        require(
            contract_.status == ContractStatus.Active,
            "Contract not active"
        );
        require(contract_.balance > 0, "No balance to release");
        require(msg.sender == contract_.employee, "Only employee can withdraw");

        uint256 amount = contract_.balance;
        contract_.balance = 0;

        (bool success, ) = payable(contract_.employee).call{value: amount}("");
        require(success, "Transfer failed");

        emit SalaryReleased(contractId, contract_.employee);
    }

    // Dispute Resolution Functions
    function raiseDispute(
        uint256 contractId
    ) external contractExists(contractId) {
        Contract storage contract_ = contracts[contractId];
        require(
            msg.sender == contract_.employee ||
                msg.sender == companies[contract_.companyId].owner,
            "Unauthorized"
        );
        require(
            contract_.status == ContractStatus.Active,
            "Invalid contract status"
        );

        contract_.status = ContractStatus.Disputed;

        emit DisputeRaised(contractId, msg.sender);
    }

    function resolveDispute(
        uint256 contractId,
        bool decisionForEmployee
    ) external contractExists(contractId) arbitratorExists(contractId) {
        Contract storage contract_ = contracts[contractId];
        require(
            contract_.status == ContractStatus.Disputed,
            "Contract not disputed"
        );

        if (decisionForEmployee && contract_.balance > 0) {
            uint256 amount = contract_.balance;
            contract_.balance = 0;
            (bool success, ) = payable(contract_.employee).call{value: amount}(
                ""
            );
            require(success, "Transfer failed");
        }

        contract_.status = ContractStatus.Terminated;

        emit DisputeResolved(contractId, decisionForEmployee);
    }

    // Contract Termination Function
    function terminateContract(
        uint256 contractId,
        string calldata reason
    ) external contractExists(contractId) {
        Contract storage contract_ = contracts[contractId];
        require(
            msg.sender == contract_.employee ||
                msg.sender == companies[contract_.companyId].owner,
            "Unauthorized"
        );
        require(
            contract_.status == ContractStatus.Active,
            "Invalid contract status"
        );

        contract_.status = ContractStatus.Terminated;

        emit ContractTerminated(contractId, reason);
    }

    // Review System Functions
    function submitReview(
        uint256 contractId,
        uint256 rating,
        string calldata comments
    ) external contractExists(contractId) {
        Contract storage contract_ = contracts[contractId];
        require(
            msg.sender == contract_.employee ||
                msg.sender == companies[contract_.companyId].owner,
            "Unauthorized"
        );
        require(
            contract_.status == ContractStatus.Terminated ||
                contract_.status == ContractStatus.Completed,
            "Contract still active"
        );

        contractReviews[contractId].push(
            Review({rating: rating, comments: comments, reviewer: msg.sender})
        );

        emit ReviewSubmitted(contractId, rating, comments);
    }

    function getReviews(
        uint256 contractId
    ) external view contractExists(contractId) returns (Review[] memory) {
        return contractReviews[contractId];
    }

    // Additional Helper Functions
    function isContractActive(uint256 contractId) public view returns (bool) {
        Contract storage contract_ = contracts[contractId];
        return
            contract_.status == ContractStatus.Active &&
            block.timestamp < contract_.startTime + contract_.duration;
    }

    function getCompanyDetails(
        uint256 companyId
    )
        external
        view
        returns (
            string memory name,
            string memory industry,
            address owner,
            uint256[] memory employeeIds
        )
    {
        Company storage company = companies[companyId];
        return (
            company.name,
            company.industry,
            company.owner,
            company.employeeIds
        );
    }

    function getEmployeeDetails(
        address _employee
    )
        external
        view
        returns (
            uint256 tokenId,
            uint256 companyId,
            uint256[] memory contractIds
        )
    {
        EmployeeDetails storage employee = employeeDetails[_employee];

        return (employee.tokenId, employee.companyId, employee.contractIds);
    }

    // Get all employees of a company with their details
    function getAllCompanyEmployees(
        uint256 companyId
    ) external view returns (EmployeeDetails[] memory) {
        Company storage company = companies[companyId];
        uint256[] memory employeeIds = company.employeeIds;
        EmployeeDetails[] memory details = new EmployeeDetails[](
            employeeIds.length
        );

        for (uint256 i = 0; i < employeeIds.length; i++) {
            uint256 tokenId = employeeIds[i];
            details[i] = EmployeeDetails({
                tokenId: tokenId,
                companyId: companyId,
                contractIds: employeeContracts[tokenId]
            });
        }

        return details;
    }

    function getContractDetails(
        uint256 contractId
    )
        external
        view
        contractExists(contractId)
        returns (
            uint256 companyId,
            uint256 employeeTokenId,
            uint256 salary,
            uint256 duration,
            uint256 startTime,
            string memory responsibilities,
            string memory terminationConditions,
            ContractStatus status,
            uint256 balance,
            address employee
        )
    {
        Contract storage contract_ = contracts[contractId];
        return (
            contract_.companyId,
            contract_.employeeTokenId,
            contract_.salary,
            contract_.duration,
            contract_.startTime,
            contract_.responsibilities,
            contract_.terminationConditions,
            contract_.status,
            contract_.balance,
            contract_.employee
        );
    }

    // Get company statistics
    function getCompanyStats(
        uint256 companyId
    )
        external
        view
        returns (
            uint256 totalEmployees,
            uint256 activeEmployees,
            uint256 totalContracts,
            uint256 activeContracts,
            uint256 averageRating
        )
    {
        Company storage company = companies[companyId];
        uint256[] memory employeeIds = company.employeeIds;
        uint256 ratingSum = 0;
        uint256 ratingCount = 0;

        for (uint256 i = 0; i < employeeIds.length; i++) {
            uint256[] memory empContracts = employeeContracts[employeeIds[i]];
            totalContracts += empContracts.length;

            for (uint256 j = 0; j < empContracts.length; j++) {
                Contract storage contract_ = contracts[empContracts[j]];
                if (contract_.status == ContractStatus.Active) {
                    activeContracts++;
                }

                Review[] storage reviews = contractReviews[empContracts[j]];
                for (uint256 k = 0; k < reviews.length; k++) {
                    ratingSum += reviews[k].rating;
                    ratingCount++;
                }
            }

            if (isEmployeeActive(employeeIds[i])) {
                activeEmployees++;
            }
        }

        totalEmployees = employeeIds.length;
        averageRating = ratingCount > 0 ? ratingSum / ratingCount : 0;
    }

    // Helper function to check if an employee is active
    function isEmployeeActive(uint256 tokenId) internal view returns (bool) {
        uint256[] memory empContracts = employeeContracts[tokenId];
        for (uint256 i = 0; i < empContracts.length; i++) {
            if (isContractActive(empContracts[i])) {
                return true;
            }
        }
        return false;
    }

    // Function to receive Ether
    receive() external payable {}
}
