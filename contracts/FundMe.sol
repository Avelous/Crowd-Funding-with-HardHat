//Get Fund From Users
// Withdraw Funds
// Set a minimum value in usd

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Constant and Immutable keyword to optimize gas

error FundMe__NotOwner();

/** @title A Contract for crowd funding
 * @author Avelous
 * @notice This contract is a demo funding contract
 * @dev THis implements s_priceFeed as our library
 */

contract FundMe {
    using PriceConverter for uint256;

    // State Variables
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    // Fund Me Variables
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    // What happens if someone sends this contract ETH without calling the fund function
    // receive
    receive() external payable {
        fund();
    }

    // fallback
    fallback() external payable {
        fund();
    }

    function fund() public payable {
        // want to be able to set a minimum fund amount in usd

        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );

        // Store the funder's address
        s_addressToAmountFunded[msg.sender] = msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex = funderIndex + 1
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);
        // withdraw the funds
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // THis Function Saves Gas
    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    //view or Pure Functions
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

// More features
// revert transfers
// dont save same wallet twice in array
// if wallet send twice add up the total
// set a max treshold
