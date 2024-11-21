// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AggregatorV2V3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";
import {ICrediflexServiceManager} from "../interfaces/ICrediflexServiceManager.sol";

contract Crediflex {
    AggregatorV2V3Interface internal usdeUsdDataFeed;
    AggregatorV2V3Interface internal wethUsdDataFeed;
    ICrediflexServiceManager internal serviceManager;

    struct Position {
        uint256 supplyShares;
        uint256 borrowShares;
        uint256 collateral;
    }

    uint256 public totalSupplyAssets;
    uint256 public totalSupplyShares;
    uint256 public totalBorrowAssets;
    uint256 public totalBorrowShares;
    uint256 public lastUpdate;

    address public usdeAddress;
    address public wethAddress;

    uint256 constant HEALTH_FACTOR_THRESHOLD = 1e18; // HF >=1
    uint256 constant INTEREST_RATE = 1e17; // 10% annually
    uint256 constant PRECISION = 1e18; // Precision

    uint256 constant BASE_LTV = 85e16; // 85%
    uint256 constant MAX_LTV = 120e16; // 120%
    uint256 constant MAX_CSCORE = 10e18; // Maximum CScore (10 * 1e18)
    uint256 constant CSCORE_THRESHOLD = 7e18; // Minimum CScore for dynamic LTV

    mapping(address user => Position) public positions;

    constructor(
        address _serviceManager,
        address _usdeUsdDataFeed,
        address _wethUsdDataFeed,
        address _usdeAddress,
        address _wethAddress
    ) {
        lastUpdate = block.timestamp;
        serviceManager = ICrediflexServiceManager(_serviceManager);
        usdeUsdDataFeed = AggregatorV2V3Interface(_usdeUsdDataFeed);
        wethUsdDataFeed = AggregatorV2V3Interface(_wethUsdDataFeed);
        usdeAddress = _usdeAddress;
        wethAddress = _wethAddress;
    }

    function supply(uint256 assets) public {
        require(assets > 0, "assets must be greater than zero");
        accrueInterest();
        Position storage position = positions[msg.sender];
        uint256 shares = 0;
        if (totalSupplyShares == 0) {
            shares = assets;
        } else {
            shares = assets * totalSupplyShares / totalSupplyAssets;
        }
        position.supplyShares += shares;
        totalSupplyShares += shares;
        totalSupplyAssets += assets;

        IERC20(usdeAddress).transferFrom(msg.sender, address(this), assets);
    }

    function withdraw(uint256 shares) public {
        require(shares > 0, "Shares must be greater than zero");
        Position storage position = positions[msg.sender];
        require(shares <= position.supplyShares, "Insufficient shares");

        uint256 assets = shares * totalSupplyAssets / totalSupplyShares;
        require(assets <= totalSupplyAssets, "Insufficient assets in the pool");
        accrueInterest();

        totalSupplyAssets -= assets;
        totalSupplyShares -= shares;
        position.supplyShares -= shares;

        // _burn(msg.sender, shares);
        IERC20(usdeAddress).transfer(msg.sender, assets);
    }

    function supplyCollateral(uint256 assets) external {
        accrueInterest();
        Position storage position = positions[msg.sender];
        position.collateral += assets;
        IERC20(wethAddress).transferFrom(msg.sender, address(this), assets);
    }

    function withdrawCollateral(uint256 assets) external {
        accrueInterest();
        Position storage position = positions[msg.sender];
        require(assets > 0, "assets must be greater than zero");
        require(position.collateral >= assets, "Insufficient collateral");

        position.collateral -= assets;
        require(isHealty(), "Position is not healthy");
        IERC20(wethAddress).transfer(msg.sender, assets);
    }

    function borrow(uint256 assets) external {
        accrueInterest();
        Position storage position = positions[msg.sender];
        uint256 shares = 0;
        if (totalBorrowShares == 0) {
            shares = assets;
        } else {
            shares = assets * totalBorrowShares / totalBorrowAssets;
        }
        position.borrowShares += shares;
        totalBorrowAssets += assets;
        totalBorrowShares += shares;

        require(isHealty(), "Position is not healthy");
        uint256 totalSupply = IERC20(usdeAddress).balanceOf(address(this));
        require(totalSupply >= assets, "Insufficient supply to borrow");
        IERC20(usdeAddress).transfer(msg.sender, assets);
    }

    function repay(uint256 assets) external {
        accrueInterest();
        Position storage position = positions[msg.sender];
        require(assets > 0, "assets must be greater than zero");
        require(position.borrowShares > 0, "No outstanding borrow");

        uint256 shares = assets * totalBorrowShares / totalBorrowAssets;
        require(shares <= position.borrowShares, "Repay assets exceeds borrowed assets");

        position.borrowShares -= shares;
        totalBorrowAssets -= assets;
        totalBorrowShares -= shares;

        IERC20(usdeAddress).transferFrom(msg.sender, address(this), assets);
    }

    function accrueInterest() public {
        uint256 accrueTime = block.timestamp - lastUpdate;
        uint256 interestPerYear = totalBorrowShares * INTEREST_RATE / PRECISION;

        uint256 interest = accrueTime * interestPerYear / 365 days;
        totalBorrowAssets += interest;
        totalSupplyAssets += interest;

        lastUpdate = block.timestamp;
    }

    function isHealty() public view returns (bool) {
        return calculateHealth() > HEALTH_FACTOR_THRESHOLD;
    }

    function getConversionPrice(
        uint256 amountIn,
        AggregatorV2V3Interface dataFeedIn,
        AggregatorV2V3Interface dataFeedOut
    ) public view returns (uint256 amountOut) {
        uint256 priceFeedIn = getDataFeedLatestAnswer(dataFeedIn);
        uint256 priceFeedOut = getDataFeedLatestAnswer(dataFeedOut);

        amountOut = (amountIn * priceFeedIn) / priceFeedOut;
    }

    function calculateHealth() public view returns (uint256) {
        Position storage position = positions[msg.sender];
        uint256 collateral = getDataFeedLatestAnswer(wethUsdDataFeed) * position.collateral / PRECISION;
        uint256 borrowed = getDataFeedLatestAnswer(usdeUsdDataFeed) * position.borrowShares / PRECISION;

        if (borrowed == 0) {
            return type(uint256).max;
        }

        uint256 healthFactor = (collateral * calculateDynamicLTV(msg.sender)) / borrowed;
        return healthFactor;
    }

    function getDataFeedLatestAnswer(AggregatorV2V3Interface dataFeed) public view returns (uint256) {
        (, int256 answer,,,) = dataFeed.latestRoundData();
        require(answer >= 0, "Negative answer not allowed");
        return uint256(answer) * PRECISION / (10 ** dataFeed.decimals());
    }
    /**
     * @notice Calculates the dynamic Loan-to-Value (LTV) ratio for a user based on their credit score.
     * @dev The function retrieves the user's credit score data and calculates the LTV ratio dynamically.
     *      The LTV ratio is adjusted based on the user's credit score, with certain thresholds and caps.
     * @param user The address of the user for whom the dynamic LTV is being calculated.
     * @return The calculated dynamic LTV ratio as a uint256 value.
     */

    function calculateDynamicLTV(address user) public view returns (uint256) {
        // Retrieve the user's credit score data from the service manager
        ICrediflexServiceManager.CScoreData memory cScoreData = serviceManager.getUserCScoreData(user);
        uint256 cScore = cScoreData.cScore;
        uint256 cScoreAge = block.timestamp - cScoreData.lastUpdate;

        // If the credit score is below the threshold or older than 4 months, return the base LTV
        if (cScore < CSCORE_THRESHOLD || cScoreAge > 120 days) {
            return BASE_LTV;
        }

        // If the credit score exceeds the maximum allowed score, return the maximum LTV
        if (cScore > MAX_CSCORE) {
            return MAX_LTV;
        }

        // Calculate the LTV adjustment based on the normalized credit score
        uint256 ltvAdjustment = ((MAX_LTV - BASE_LTV) * cScore) / MAX_CSCORE;

        // Calculate the dynamic LTV as the base LTV plus the adjustment, capped at the maximum LTV
        uint256 dynamicLTV = BASE_LTV + ltvAdjustment;

        // Ensure the dynamic LTV does not exceed the maximum LTV
        if (dynamicLTV > MAX_LTV) {
            return MAX_LTV;
        }

        return dynamicLTV;
    }
}
