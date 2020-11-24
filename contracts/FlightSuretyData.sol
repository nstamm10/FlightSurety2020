pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /*****************************************f***************************************************/
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

    struct Airline {                                          //Struct to classify an airline and hold relevant info
      string name;
      string abbreviation;
    }

    uint constant M = 4;                                    //constant M refers to number of airlines needed to use multi-party consensus


    uint private registeredAirlineCount = 0;
    mapping (address => mapping(address => bool)) private multiCalls;
    address[] multiCallsArray = new address[](0);                //array of addresses that have called the registerFlight function


    mapping(address => Airline) public airlines;             // Mapping for storing employees. Question: Does this contract have to inheret from the app contract in order to use a mapping that maps to an Airline type? (airline type is stored in the app contract, maybe this will have to change)
    mapping(address => uint256) private authorizedAirlines;   // Mapping for airlines authorized
    Insurance[] private insurance;
    mapping(address => uint256) private credit;
    uint private totalFunding = 0; //total funding is the bank for the insurance program. When a new airline joins, this var increases by 10 ether

    mapping(address => uint256) private voteCounter;
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
    * @dev Modifier that requires the msg.sender to be a registered airline
    */
    modifier requireIsRegisteredAirline()
    {
        require(isRegisteredAirline() == true, "Airline is not registered");
        _;
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }
    /**
    * @dev Modifier that requires the msg.value to be at least 10 ether in order to fund the contract
    */
    modifier canFund() {
      require(msg.value >= 10 ether, "Caller does not have funds to support registration.");
      _;
    }
    /**
    * @dev Modifier that distributes change back to the msg.sender upon registration
    */
    modifier registrationChange()  {
      uint _price = 10 ether;
      uint amountToReturn = msg.value - _price;
      msg.sender.transfer(amountToReturn);
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
        if (authorizedAirlines[msg.sender] == 1) {
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
        require(airlines[msg.sender], "Caller must be registered as an Airline");

        bool isDuplicate = false;

        operational = mode;
    }

    /**
    * @dev Get airline name
    *
    * @return the name field in the Airline struct, helding in the airlines mapping
    */
    function getAirlineName() public view returns(string) {
        return airlines[msg.sender].name;
    }

    /**
    * @dev Get airline abbreviation
    *
    * @return the abbreviation field in the Airline struct, helding in the airlines mapping
    */
    function getAirlineAbreviation() public view returns(string) {
        return airlines[msg.sender].abbreviation;
    }

    /**
    * @dev Get airline count
    *
    * @return the count of registered airlines in the system (not authorized)
    */
    function getRegisteredAirlineCount() public view returns(uint) {
        return registeredAirlineCount;
    }


    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function registerAirline
                                (
                                    string name,
                                    string abbreviation,
                                    address newAirline
                                )
                                external
                                requireIsRegisteredAirline
                                returns
                                (
                                    bool success,
                                    uint256 votes
                                )
    {
      if (registeredAirlineCount < 4) {
        airlines[newAirline].name = name;
        airlines[newAirline].abbreviation = abbreviation;
        registeredAirlineCount = registeredAirlineCount.add(1);
        return(true, 0);
      } else {

        bool isDuplicate = false;

        if (multiCalls[newAirline][msg.sender] == true) {
          isDuplicate = true;
          //break;
        }

        require(!isDuplicate, "Caller has already called this function");
        multiCalls[newAirline][msg.sender] = true;
        voteCounter[newAirline] = voteCounter[newAirline].add(1);
        if (voteCounter[newAirline] >= M) {
          airlines[newAirline].name = name;
          airlines[newAirline].abbreviation = abbreviation;
          return(true, voteCounter[newAirline]);
        } else {
          return(false, voteCounter[newAirline]);
        }

      }
    }


   /**
    * @dev Buy insurance for a flight
    * I'm implementing this as a mapping to keep track of who owns insurance on which flightSuretyApp
    * I created a new struct and mapping to handle this functionality
    * I think it should work

    function buy (address airline, string flight, uint256 timestamp, uint256 amount) external payable {
        require(msg.value == amount, "Transaction is suspect");
        if (amount > 1) {
            uint256 creditAmount = amount - 1;
            creditInsurees(msg.sender, creditAmount);
        }
        bytes32 key = getFlightKey(airline, flight, timestamp);
        Insurance newInsurance = Insurance(msg.sender, key, amount);
        insurance.push(newInsurance);
    }*/

    /**
     *  @dev Credits payouts to insurees

    function creditInsurees (address airline, string flight, uint256 timestamp) external pure {
        flightKey = getFlightKey(airline, flight, timestamp);
        for (uint i=0; i < insurance.length; i++) {
            if (insurance[i].key == flightKey) {
                credit[insurance[i].owner] = mul(insurance[i].amount, 1.5);
            }
        }
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *

    function pay ( ) external pure {
        require(credit[msg.sender] > 0, "Caller does not have any credit");
        uint256 amountToReturn = credit[msg.sender];
        credit[msg.sender] = 0;
        msg.sender.transfer(amountToReturn);
    }*/

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund () public canFund registrationChange payable {
      totalFunding = totalFunding.add(10 ether); // does this make the 10 ether come out of the msg.value?
      authorizedAirlines[msg.sender] = 1;


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
