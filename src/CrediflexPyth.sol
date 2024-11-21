// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IPyth, PythStructs} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

// Define the UnderLend contract
contract Crediflex is ERC20 {
    event RequestCreditScore(address indexed user, uint256 timestamp);

    IPyth pyth;
    bytes32 wethUsdPriceFeedId;
    bytes32 usdeUsdPriceFeedId;

    struct Position {
        // uint256 supplyShares;
        uint256 borrowShares;
        uint256 collateral;
    }

    uint256 totalSupplyAssets;
    // uint256 totalSupplyShares;
    uint256 totalBorrowAssets;
    uint256 totalBorrowShares;
    uint256 lastUpdate;

    uint256 constant HEALTH_FACTOR_THRESHOLD = 1e18; // HF >=1
    uint256 constant INTEREST_RATE = 1e17; // 10% annually
    uint256 constant PRECISION = 1e18; // Precision

    uint256 constant BASE_LTV = 85e16; // 85%
    uint256 constant MAX_LTV = 120e16; // 120%
    uint256 constant MAX_CSCORE = 10e18; // Maximum CScore (10 * 1e18)
    uint256 constant CSCORE_THRESHOLD = 7e18; // Minimum CScore for dynamic LTV

    mapping(address user => uint256 creditScore) cScores;
    mapping(address user => Position) positions;

    // ethreum mainnet
    // address usde = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    // address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // ethena testnet
    // address usdeAddres; = 0x426E7d03f9803Dd11cb8616C65b99a3c0AfeA6dE;
    // no address weth in testnet, will be mocked for now
    address usdeAddress;
    address wethAddress;

    constructor(
        address _pyth,
        bytes32 _wethUsdPriceFeedId,
        bytes32 _usdeUsdPriceFeedId,
        address _usdeAddress,
        address _wethAddress
    ) ERC20("Crediflex", "CF") {
        lastUpdate = block.timestamp;
        pyth = IPyth(_pyth);
        wethUsdPriceFeedId = _wethUsdPriceFeedId;
        usdeUsdPriceFeedId = _usdeUsdPriceFeedId;
        usdeAddress = _usdeAddress;
        wethAddress = _wethAddress;
    }

    function supply(uint256 amount) public {
        require(amount > 0, "Supply amount must be greater than zero");
        acrueInterest();
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = amount;
        } else {
            shares = amount * totalSupply() / totalSupplyAssets;
        }
        totalSupplyAssets += amount;

        IERC20(usdeAddress).transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, shares);
    }

    function withdraw(uint256 shares) public {
        require(shares > 0, "Withdrawal shares must be greater than zero");
        require(shares <= balanceOf(msg.sender), "Insufficient shares for withdrawal");

        uint256 amount = shares * totalSupplyAssets / totalSupply();
        require(amount <= totalSupplyAssets, "Insufficient assets in the pool for withdrawal");
        acrueInterest();

        totalSupplyAssets -= amount;

        _burn(msg.sender, shares);
        IERC20(usdeAddress).transfer(msg.sender, amount);
    }

    function supplyCollateral(uint256 amount) external {
        acrueInterest();
        Position storage position = positions[msg.sender];
        position.collateral += amount;
        IERC20(wethAddress).transferFrom(msg.sender, address(this), amount);
    }

    function withdrawCollateral(uint256 amount) external {
        acrueInterest();
        Position storage position = positions[msg.sender];
        require(amount > 0, "Collateral withdrawal amount must be greater than zero");
        require(position.collateral >= amount, "Insufficient collateral for withdrawal");

        position.collateral -= amount;
        require(isHealty(), "Position is not healthy for collateral withdrawal");
        IERC20(wethAddress).transfer(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        acrueInterest();
        Position storage position = positions[msg.sender];
        uint256 shares = 0;
        if (totalBorrowShares == 0) {
            shares = amount;
        } else {
            shares = amount * totalBorrowShares / totalBorrowAssets;
        }
        position.borrowShares += shares;
        require(isHealty(), "Position is not healthy for borrowing");

        totalBorrowAssets += amount;
        totalBorrowShares += shares;

        IERC20(usdeAddress).transfer(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        acrueInterest();
        Position storage position = positions[msg.sender];
        require(amount > 0, "Repayment amount must be greater than zero");
        require(position.borrowShares > 0, "No outstanding borrow to repay");

        uint256 sharesToRepay = amount * totalBorrowShares / totalBorrowAssets;
        require(sharesToRepay <= position.borrowShares, "Repayment amount exceeds borrowed amount");

        position.borrowShares -= sharesToRepay;
        totalBorrowAssets -= amount;
        totalBorrowShares -= sharesToRepay;

        IERC20(usdeAddress).transferFrom(msg.sender, address(this), amount);
    }

    function acrueInterest() public {
        uint256 acrueTime = block.timestamp - lastUpdate;
        uint256 interestPerYear = totalBorrowShares * INTEREST_RATE / PRECISION;

        uint256 interest = acrueTime * interestPerYear / 365 days;
        totalBorrowAssets += interest;
        totalSupplyAssets += interest;

        lastUpdate = block.timestamp;
    }

    function setCreaditScoreByAvs(address user, uint256 _cScore) external {
        cScores[user] = _cScore;
    }

    function requestCreditScore(address user) external {
        emit RequestCreditScore(user, block.timestamp);
    }

    function isHealty() public view returns (bool) {
        return calculateHealth() > HEALTH_FACTOR_THRESHOLD;
    }

    function calculateHealth() public view returns (uint256) {
        Position storage position = positions[msg.sender];
        uint256 collateral = getPricefeed(wethUsdPriceFeedId) * position.collateral;
        uint256 borrowed = getPricefeed(usdeUsdPriceFeedId) * position.borrowShares;

        if (borrowed == 0) {
            return type(uint256).max;
        }

        uint256 healthFactor = (collateral * calculateDynamicLTV(msg.sender)) / borrowed;
        return healthFactor;
    }

    function getPricefeed(bytes32 _priceFeedId) public view returns (uint256) {
        PythStructs.Price memory price = pyth.getPriceNoOlderThan(_priceFeedId, 60);

        uint256 adjustedPrice = uint256(uint64(price.price));
        uint256 priceWithPrecision = adjustedPrice * PRECISION;
        uint256 divisor = 10 ** uint8(uint32(-1 * price.expo));

        return priceWithPrecision / divisor;
    }

    function calculateDynamicLTV(address user) public view returns (uint256) {
        uint256 cScore = cScores[user];

        // If CScore exceeds MAX_CSCORE, return MAX_LTV directly
        if (cScore > MAX_CSCORE) {
            return MAX_LTV;
        }

        // Validate if CScore meets the threshold
        if (cScore < CSCORE_THRESHOLD) {
            return BASE_LTV; // Return BASE_LTV if below threshold
        }

        // Calculate the LTV adjustment based on the normalized CScore
        uint256 ltvAdjustment = ((MAX_LTV - BASE_LTV) * cScore) / MAX_CSCORE;

        // Dynamic LTV is BASE_LTV + the adjustment, capped at MAX_LTV
        uint256 dynamicLTV = BASE_LTV + ltvAdjustment;

        // Ensure LTV does not exceed MAX_LTV
        if (dynamicLTV > MAX_LTV) {
            return MAX_LTV;
        }

        return dynamicLTV;
    }
}
// base LTV 85% + LTV variable

// LTV 90
// if  credit score
// score > good
// LTV 120 dynamicaly
