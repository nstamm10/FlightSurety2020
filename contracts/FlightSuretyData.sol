pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;         // Account used to deploy contract
    bool private operational = true;       // Blocks all state changes throughout the contract if false

    uint private funds;

    struct Insurance {
        address owner;
        bytes32 key;
        uint256 amount;
    }

    mapping(address => Airline) private airlines;             // Mapping for storing employees
    mapping(address => uint256) private authorizedAirlines; // Mapping for airlines authorized
    Insurance[] private insurance;
    mapping(address => uint256) private credit;
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor () public {
        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }



    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational() public view returns(bool) {
        return operational;
    }

    /**
    * @dev Get registration status of an airline
    *
    * @return A bool that is the current registration status
    */
    function isRegisteredAirline() public view returns(bool) {
        if (airlines[msg.sender]) {
            return true;
        } else {
            return false;
        }
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */

    //Questions on this...
    function setOperatingStatus (bool mode) external requireContractOwner {
        require(mode != operational, "New mode must be different from existing mode");
        require(airlines[msg.sender], "Caller must be registered as an Airline")

        bool isDuplicate = false;

        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function registerAirline () external pure {

    }


   /**
    * @dev Buy insurance for a flight
    * I'm implementing this as a mapping to keep track of who owns insurance on which flightSuretyApp
    * I created a new struct and mapping to handle this functionality
    * I think it should work
    */
    function buy (address airline, string memory flight, uint256 timestamp, uint256 amount) external payable {
        require(msg.value == amount, "Transaction is suspect")
        if (amount > 1) {
            uint256 credit = amount - 1;
            creditInsurees(msg.sender, credit);
        }
        bytes32 key = getFlightKey(airline, flight, timestamp);
        Insurance newInsurance = Insurance(msg.sender, key, amount);
        insurance.push(newInsurance);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees (address airline, string memory flight, uint256 timestamp) external pure {
        flightKey = getFlightKey(airline, flight, timestamp);
        for (uint i=0; i < insurance.length; i++) {
            if (insurance[i].key == flightKey) {
                credit[insurance[i].owner] = mul(insurance[i].amount, 1.5)
            }
        }
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay ( ) external pure {
        require(credit[msg.sender] > 0, "Caller does not have any credit")
        uint256 amountToReturn = credit[msg.sender];
        credit[msg.sender] = 0;
        msg.sender.transfer(amountToReturn);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund ( ) public payable {

    }

    function getFlightKey ( address airline, string memory flight, uint256 timestamp ) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable {
        fund();
    }


}
