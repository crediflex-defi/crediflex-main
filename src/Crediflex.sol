// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {AggregatorV2V3Interface} from
    "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";
import {ICrediflexServiceManager} from "../interfaces/ICrediflexServiceManager.sol";

/**
 * @title Crediflex
 * @dev A contract for managing supply, collateral, and borrowing of assets with dynamic LTV based on credit scores.
 */
contract Crediflex {
    error ZeroAssets();
    error InsufficientShares();
    error InsufficientAssets();
    error InsufficientCollateral();
    error PositionNotHealthy();
    error InsufficientSupply();
    error NoOutstandingBorrow();
    error RepayExceedsBorrow();
    error NegativeAnswer();

    AggregatorV2V3Interface internal usdcUsdDataFeed;
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

    address public usdcAddress;
    address public wethAddress;

    uint256 constant HEALTH_FACTOR_THRESHOLD = 1e18; // HF >=1
    uint256 constant INTEREST_RATE = 1e17; // 10% annually
    uint256 constant PRECISION = 1e18; // Precision

    uint256 constant BASE_LTV = 85e16; // 85%
    uint256 constant MAX_LTV = 200e16; // 200%
    uint256 constant MAX_C_SCORE = 10e18; // Maximum CScore (10 * 1e18)
    uint256 constant MIN_C_SCORE = 5e18; // Minimum CScore for dynamic LTV

    mapping(address user => Position) public positions;

    /**
     * @dev Initializes the contract with the given parameters.
     * @param _serviceManager Address of the service manager contract.
     * @param _usdcUsdDataFeed Address of the USDC/USD data feed.
     * @param _wethUsdDataFeed Address of the WETH/USD data feed.
     * @param _usdcAddress Address of the usdc token.
     * @param _wethAddress Address of the WETH token.
     */
    constructor(
        address _serviceManager,
        address _usdcUsdDataFeed,
        address _wethUsdDataFeed,
        address _usdcAddress,
        address _wethAddress
    ) {
        lastUpdate = block.timestamp;
        serviceManager = ICrediflexServiceManager(_serviceManager);
        usdcUsdDataFeed = AggregatorV2V3Interface(_usdcUsdDataFeed);
        wethUsdDataFeed = AggregatorV2V3Interface(_wethUsdDataFeed);
        usdcAddress = _usdcAddress;
        wethAddress = _wethAddress;
    }

    /**
     * @notice Supplies assets to the contract.
     * @param assets The amount of assets to supply.
     */
    function supply(
        uint256 assets
    ) public {
        if (assets == 0) revert ZeroAssets();
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

        IERC20(usdcAddress).transferFrom(msg.sender, address(this), assets);
    }

    /**
     * @notice Withdraws shares from the contract.
     * @param shares The amount of shares to withdraw.
     */
    function withdraw(
        uint256 shares
    ) public {
        if (shares == 0) revert ZeroAssets();
        Position storage position = positions[msg.sender];
        if (shares > position.supplyShares) revert InsufficientShares();

        uint256 assets = shares * totalSupplyAssets / totalSupplyShares;
        if (assets > totalSupplyAssets) revert InsufficientAssets();
        accrueInterest();

        totalSupplyAssets -= assets;
        totalSupplyShares -= shares;
        position.supplyShares -= shares;

        IERC20(usdcAddress).transfer(msg.sender, assets);
    }

    /**
     * @notice Supplies collateral to the contract.
     * @param assets The amount of collateral to supply.
     */
    function supplyCollateral(
        uint256 assets
    ) external {
        if (assets == 0) revert ZeroAssets();
        accrueInterest();
        Position storage position = positions[msg.sender];
        position.collateral += assets;
        IERC20(wethAddress).transferFrom(msg.sender, address(this), assets);
    }

    /**
     * @notice Withdraws collateral from the contract.
     * @param assets The amount of collateral to withdraw.
     */
    function withdrawCollateral(
        uint256 assets
    ) external {
        if (assets == 0) revert ZeroAssets();
        Position storage position = positions[msg.sender];
        if (position.collateral < assets) revert InsufficientCollateral();
        accrueInterest();

        position.collateral -= assets;
        if (!isHealty()) revert PositionNotHealthy();
        IERC20(wethAddress).transfer(msg.sender, assets);
    }

    /**
     * @notice Borrows assets from the contract.
     * @param assets The amount of assets to borrow.
     */
    function borrow(
        uint256 assets
    ) external {
        if (assets == 0) revert ZeroAssets();
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

        if (!isHealty()) revert PositionNotHealthy();
        uint256 totalSupply = IERC20(usdcAddress).balanceOf(address(this));
        if (totalSupply < assets) revert InsufficientSupply();
        IERC20(usdcAddress).transfer(msg.sender, assets);
    }

    /**
     * @notice Repays borrowed assets to the contract.
     * @param shares The amount of shares to repay.
     */
    function repay(
        uint256 shares
    ) external {
        if (shares == 0) revert ZeroAssets();
        Position storage position = positions[msg.sender];
        if (position.borrowShares == 0) revert NoOutstandingBorrow();
        if (shares > position.borrowShares) revert RepayExceedsBorrow();
        accrueInterest();

        uint256 assets = shares * totalBorrowAssets / totalBorrowShares;

        position.borrowShares -= shares;
        totalBorrowAssets -= assets;
        totalBorrowShares -= shares;

        IERC20(usdcAddress).transferFrom(msg.sender, address(this), assets);
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
        return calculateHealth(msg.sender) > HEALTH_FACTOR_THRESHOLD;
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
        AggregatorV2V3Interface dataFeedOut,
        address tokenIn,
        address tokenOut
    ) public view returns (uint256 amountOut) {
        uint256 priceFeedIn = getDataFeedLatestAnswer(dataFeedIn);
        uint256 priceFeedOut = getDataFeedLatestAnswer(dataFeedOut);

        uint8 decimalsIn = IERC20Metadata(tokenIn).decimals();
        uint8 decimalsOut = IERC20Metadata(tokenOut).decimals();

        amountOut = (amountIn * priceFeedIn * 10 ** decimalsOut) / (priceFeedOut * 10 ** decimalsIn);
    }

    /**
     * @notice Calculates the health factor of the user's position.
     * @return The calculated health factor.
     */
    function calculateHealth(
        address user
    ) public view returns (uint256) {
        Position storage position = positions[user];
        if (position.borrowShares == 0) {
            return type(uint256).max;
        }

        uint256 collateral = getConversionPrice(
            position.collateral, wethUsdDataFeed, usdcUsdDataFeed, wethAddress, usdcAddress
        );

        uint256 borrowed = position.borrowShares * totalBorrowAssets / totalBorrowShares;
        uint256 healthFactor = (collateral * calculateDynamicLTV(user)) / (borrowed);

        return healthFactor;
    }

    /**
     * @notice Retrieves the latest answer from a data feed.
     * @param dataFeed The data feed to query.
     * @return The latest answer from the data feed.
     */
    function getDataFeedLatestAnswer(
        AggregatorV2V3Interface dataFeed
    ) public view returns (uint256) {
        (, int256 answer,,,) = dataFeed.latestRoundData();
        if (answer < 0) revert NegativeAnswer();
        return uint256(answer) * PRECISION / (10 ** dataFeed.decimals());
    }

    /**
     * @notice Calculates the dynamic Loan-to-Value (LTV) ratio for a user based on their credit score.
     * @dev The function retrieves the user's credit score data and calculates the LTV ratio dynamically.
     *      The LTV ratio is adjusted based on the user's credit score, with certain thresholds and caps.
     * @param user The address of the user for whom the dynamic LTV is being calculated.
     * @return The calculated dynamic LTV ratio as a uint256 value.
     */
    function calculateDynamicLTV(
        address user
    ) public view returns (uint256) {
        // Retrieve the user's credit score data from the service manager
        ICrediflexServiceManager.CScoreData memory cScoreData =
            serviceManager.getUserCScoreData(user);
        uint256 cScore = cScoreData.cScore;
        uint256 cScoreAge = block.timestamp - cScoreData.lastUpdate;

        // If the credit score is below the threshold or older than 4 months, return the base LTV
        if (cScore <= MIN_C_SCORE || cScoreAge > 120 days) {
            return BASE_LTV;
        }

        uint256 normalizedCScore = cScore - MIN_C_SCORE;
        uint256 cScoreRange = MAX_C_SCORE - MIN_C_SCORE;
        uint256 ltvRange = MAX_LTV - BASE_LTV;

        uint256 ltvAdjustment = (ltvRange * normalizedCScore) / cScoreRange;
        uint256 dynamicLTV = BASE_LTV + ltvAdjustment;

        // Ensure the dynamic LTV does not exceed the maximum LTV
        if (dynamicLTV > MAX_LTV) {
            return MAX_LTV;
        }

        return dynamicLTV;
    }
}
