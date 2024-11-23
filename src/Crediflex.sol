// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV2V3Interface} from
    "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";
import {ICrediflexServiceManager} from "../interfaces/ICrediflexServiceManager.sol";

/**
 * @title Crediflex
 * @dev A contract for managing supply, collateral, and borrowing of assets with dynamic LTV based on credit scores.
 * @author Ammar Robbani
 */
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
    uint256 constant MAX_C_SCORE = 10e18; // Maximum CScore (10 * 1e18)
    uint256 constant MIN_C_SCORE = 5e18; // Minimum CScore for dynamic LTV

    mapping(address user => Position) public positions;

    /**
     * @dev Initializes the contract with the given parameters.
     * @param _serviceManager Address of the service manager contract.
     * @param _usdeUsdDataFeed Address of the USDE/USD data feed.
     * @param _wethUsdDataFeed Address of the WETH/USD data feed.
     * @param _usdeAddress Address of the USDE token.
     * @param _wethAddress Address of the WETH token.
     */
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

    /**
     * @notice Supplies assets to the contract.
     * @param assets The amount of assets to supply.
     */
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

    /**
     * @notice Withdraws shares from the contract.
     * @param shares The amount of shares to withdraw.
     */
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

        IERC20(usdeAddress).transfer(msg.sender, assets);
    }

    /**
     * @notice Supplies collateral to the contract.
     * @param assets The amount of collateral to supply.
     */
    function supplyCollateral(uint256 assets) external {
        accrueInterest();
        Position storage position = positions[msg.sender];
        position.collateral += assets;
        IERC20(wethAddress).transferFrom(msg.sender, address(this), assets);
    }

    /**
     * @notice Withdraws collateral from the contract.
     * @param assets The amount of collateral to withdraw.
     */
    function withdrawCollateral(uint256 assets) external {
        accrueInterest();
        Position storage position = positions[msg.sender];
        require(assets > 0, "assets must be greater than zero");
        require(position.collateral >= assets, "Insufficient collateral");

        position.collateral -= assets;
        require(isHealty(), "Position is not healthy");
        IERC20(wethAddress).transfer(msg.sender, assets);
    }

    /**
     * @notice Borrows assets from the contract.
     * @param assets The amount of assets to borrow.
     */
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

    /**
     * @notice Repays borrowed assets to the contract.
     * @param assets The amount of assets to repay.
     */
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

    /**
     * @notice Accrues interest on borrowed assets.
     */
    function accrueInterest() public {
        uint256 accrueTime = block.timestamp - lastUpdate;
        uint256 interestPerYear = totalBorrowShares * INTEREST_RATE / PRECISION;

        uint256 interest = accrueTime * interestPerYear / 365 days;
        totalBorrowAssets += interest;
        totalSupplyAssets += interest;

        lastUpdate = block.timestamp;
    }

    /**
     * @notice Checks if the position is healthy based on the health factor.
     * @return True if the position is healthy, false otherwise.
     */
    function isHealty() public view returns (bool) {
        return calculateHealth() > HEALTH_FACTOR_THRESHOLD;
    }

    /**
     * @notice Converts an amount from one asset to another using data feeds.
     * @param amountIn The amount of the input asset.
     * @param dataFeedIn The data feed for the input asset.
     * @param dataFeedOut The data feed for the output asset.
     * @return amountOut The converted amount of the output asset.
     */
    function getConversionPrice(
        uint256 amountIn,
        AggregatorV2V3Interface dataFeedIn,
        AggregatorV2V3Interface dataFeedOut
    ) public view returns (uint256 amountOut) {
        uint256 priceFeedIn = getDataFeedLatestAnswer(dataFeedIn);
        uint256 priceFeedOut = getDataFeedLatestAnswer(dataFeedOut);

        amountOut = (amountIn * priceFeedIn) / priceFeedOut;
    }

    /**
     * @notice Calculates the health factor of the user's position.
     * @return The calculated health factor.
     */
    function calculateHealth() public view returns (uint256) {
        Position storage position = positions[msg.sender];
        uint256 collateral =
            getDataFeedLatestAnswer(wethUsdDataFeed) * position.collateral / PRECISION;
        uint256 borrowed =
            getDataFeedLatestAnswer(usdeUsdDataFeed) * position.borrowShares / PRECISION;

        if (borrowed == 0) {
            return type(uint256).max;
        }

        uint256 healthFactor = (collateral * calculateDynamicLTV(msg.sender)) / borrowed;
        return healthFactor;
    }

    /**
     * @notice Retrieves the latest answer from a data feed.
     * @param dataFeed The data feed to query.
     * @return The latest answer from the data feed.
     */
    function getDataFeedLatestAnswer(AggregatorV2V3Interface dataFeed)
        public
        view
        returns (uint256)
    {
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
        ICrediflexServiceManager.CScoreData memory cScoreData =
            serviceManager.getUserCScoreData(user);
        uint256 cScore = cScoreData.cScore;
        uint256 cScoreAge = block.timestamp - cScoreData.lastUpdate;

        // If the credit score is below the threshold or older than 4 months, return the base LTV
        if (cScore < MIN_C_SCORE || cScoreAge > 120 days) {
            return BASE_LTV;
        }

        // If the credit score exceeds the maximum allowed score, return the maximum LTV
        if (cScore > MAX_C_SCORE) {
            return MAX_LTV;
        }

        // Calculate the LTV adjustment based on the normalized credit score
        uint256 ltvAdjustment = ((MAX_LTV - BASE_LTV) * cScore) / MAX_C_SCORE;

        // Calculate the dynamic LTV as the base LTV plus the adjustment, capped at the maximum LTV
        uint256 dynamicLTV = BASE_LTV + ltvAdjustment;

        // Ensure the dynamic LTV does not exceed the maximum LTV
        if (dynamicLTV > MAX_LTV) {
            return MAX_LTV;
        }

        return dynamicLTV;
    }
}
