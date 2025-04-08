// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Crediflex} from "src/Crediflex.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {AggregatorV2V3Interface} from
    "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";
import {ICrediflexServiceManager} from "../interfaces/ICrediflexServiceManager.sol";

contract CrediflexTest is Test {
    Crediflex public crediflex;
    ICrediflexServiceManager public crediflexManager;
    HelperConfig public helperConfig;

    address usdcUsdDataFeed;
    address wethUsdDataFeed;
    address usdc;
    address weth;
    address serviceManager;

    uint256 public constant STARTING_ETH_BALANCE = 10 ether;
    uint256 public constant STARTING_USDC_BALANCE = 100_000e6;

    address LENDER = makeAddr("lender");
    address BORROWER = makeAddr("borrower");
    uint256 public constant LENDING_AMOUNT = 10_000 * 10e6;

    uint256 constant BASE_LTV = 85e16; // 85%
    uint256 constant MAX_LTV = 200e16; // 200%
    uint256 constant MAX_C_SCORE = 10e18; // Maximum CScore (10 * 1e18)
    uint256 constant MIN_C_SCORE = 5e18; // Minimum CScore for dynamic LTV

    function setUp() public {
        helperConfig = new HelperConfig();

        (usdcUsdDataFeed, wethUsdDataFeed, usdc, weth, serviceManager) =
            helperConfig.activeNetworkConfig();
        crediflexManager = ICrediflexServiceManager(serviceManager);

        crediflex = new Crediflex(serviceManager, usdcUsdDataFeed, wethUsdDataFeed, usdc, weth);

        ERC20Mock(weth).mint(BORROWER, STARTING_ETH_BALANCE);
        ERC20Mock(usdc).mint(BORROWER, STARTING_USDC_BALANCE);
    }

    function testSupply() public {
        vm.startPrank(BORROWER);
        uint256 amount = 1000e6;
        IERC20(usdc).approve(address(crediflex), amount);
        crediflex.supply(amount);
        assertEq(crediflex.totalSupplyShares(), amount);
        (uint256 shares,,) = crediflex.positions(BORROWER);

        assertEq(shares, amount);
        vm.stopPrank();
    }

    modifier suppliedByLender() {
        vm.startPrank(LENDER);
        ERC20Mock(usdc).mint(LENDER, LENDING_AMOUNT);
        IERC20(usdc).approve(address(crediflex), LENDING_AMOUNT);
        crediflex.supply(LENDING_AMOUNT);
        vm.stopPrank();
        _;
    }

    function testWithdraw() public {
        vm.startPrank(BORROWER);
        uint256 amount = 1000e6;
        IERC20(usdc).approve(address(crediflex), amount);
        crediflex.supply(amount);

        (uint256 shares,,) = crediflex.positions(BORROWER);
        crediflex.withdraw(shares);
        assertEq(crediflex.totalSupplyShares(), 0);
        assertEq(IERC20(usdc).balanceOf(BORROWER), STARTING_USDC_BALANCE);
        vm.stopPrank();
    }

    function testSupplyCollateral() public {
        vm.startPrank(BORROWER);
        uint256 collateralAmount = 1 ether;
        IERC20(weth).approve(address(crediflex), collateralAmount);
        crediflex.supplyCollateral(collateralAmount);
        (,, uint256 collateral) = crediflex.positions(BORROWER);
        assertEq(collateral, collateralAmount);
        vm.stopPrank();
    }

    function testWithdrawCollateral() public {
        vm.startPrank(BORROWER);
        uint256 collateralAmount = 1 ether;
        IERC20(weth).approve(address(crediflex), collateralAmount);
        crediflex.supplyCollateral(collateralAmount);

        crediflex.withdrawCollateral(collateralAmount);
        (,, uint256 collateral) = crediflex.positions(BORROWER);
        assertEq(collateral, 0);
        vm.stopPrank();
    }

    function testBorrowInsufficientSupply() public {
        vm.startPrank(BORROWER);
        uint256 collateralAmount = 1 ether; // WETH
        uint256 borrowAmount = 0.5 * 1e6; // USDC
        IERC20(weth).approve(address(crediflex), collateralAmount);
        crediflex.supplyCollateral(collateralAmount);

        // Attempt to borrow without any lender supplying funds
        vm.expectRevert(abi.encodeWithSignature("InsufficientSupply()"));
        crediflex.borrow(borrowAmount);
        vm.stopPrank();
    }

    function testBorrowIsNotHealthy() public {
        vm.startPrank(BORROWER);
        uint256 collateralAmount = 1 ether; // WETH / USD 3500
        uint256 borrowAmount = 3000 ether; // USDE / USD 1.1
        IERC20(weth).approve(address(crediflex), collateralAmount);
        crediflex.supplyCollateral(collateralAmount);

        vm.expectRevert(abi.encodeWithSignature("PositionNotHealthy()"));
        crediflex.borrow(borrowAmount);
        vm.stopPrank();
    }

    function testBorrow() public suppliedByLender {
        vm.startPrank(BORROWER);
        uint256 collateralAmount = 1 ether; // WETH
        uint256 borrowAmount = 1000e6; // USDC
        IERC20(weth).approve(address(crediflex), collateralAmount);
        crediflex.supplyCollateral(collateralAmount);

        uint256 expectedUsdcBalance = STARTING_USDC_BALANCE + borrowAmount;

        crediflex.borrow(borrowAmount);
        (, uint256 borrowShares,) = crediflex.positions(BORROWER);
        assertEq(borrowShares, borrowAmount);

        uint256 usdcBalance = IERC20(usdc).balanceOf(BORROWER);
        assertEq(usdcBalance, expectedUsdcBalance);
        vm.stopPrank();
    }

    function testRepay() public suppliedByLender {
        vm.startPrank(BORROWER);
        uint256 collateralAmount = 1 ether;
        uint256 borrowAmount = 500 * 1e6;
        IERC20(weth).approve(address(crediflex), collateralAmount);
        crediflex.supplyCollateral(collateralAmount);

        crediflex.borrow(borrowAmount);
        IERC20(usdc).approve(address(crediflex), borrowAmount);
        crediflex.repay(borrowAmount);
        (, uint256 borrowShares,) = crediflex.positions(BORROWER);
        assertEq(borrowShares, 0);
        vm.stopPrank();
    }

    function testRequestCScore() public {
        uint256 expectedCScore = 7 ether;
        ICrediflexServiceManager.Task memory task = crediflexManager.createNewTask(BORROWER);
        crediflexManager.respondToTask(task, expectedCScore, 0, "");
        ICrediflexServiceManager.CScoreData memory cScoreData =
            crediflexManager.getUserCScoreData(BORROWER);
        assertEq(cScoreData.cScore, expectedCScore);
    }

    function testDynamicLTVIfCScoreLessThanThreshold() public {
        ICrediflexServiceManager.Task memory task = crediflexManager.createNewTask(BORROWER);
        crediflexManager.respondToTask(task, MIN_C_SCORE - 1e18, 0, "");

        uint256 ltv = crediflex.calculateDynamicLTV(BORROWER);
        console.log("Calculated LTV:", ltv);
        assertEq(BASE_LTV, ltv);
    }

    function testDynamicLTVIfCScoreGreaterThanThreshold() public {
        uint256 cScore = MIN_C_SCORE + 1e17;
        ICrediflexServiceManager.Task memory task = crediflexManager.createNewTask(BORROWER);
        crediflexManager.respondToTask(task, cScore, 0, "");

        uint256 ltv = crediflex.calculateDynamicLTV(BORROWER);
        console.log("Calculated LTV:", ltv);
        assertGt(ltv, BASE_LTV);
    }

    function testDynamicLTVIfCScoreReachedMax() public {
        uint256 cScore = MAX_C_SCORE + 1e18;
        ICrediflexServiceManager.Task memory task = crediflexManager.createNewTask(BORROWER);
        crediflexManager.respondToTask(task, cScore, 0, "");

        uint256 ltv = crediflex.calculateDynamicLTV(BORROWER);
        console.log("Calculated LTV:", ltv);
        assertEq(ltv, MAX_LTV);
    }

    function testCalculateHealth() public suppliedByLender {
        vm.startPrank(BORROWER);
        uint256 collateralAmount = 2 ether; // 3600 USD
        uint256 borrowAmount = 1800e6; // 1000 USD

        // Approve and supply collateral
        IERC20(weth).approve(address(crediflex), collateralAmount);
        crediflex.supplyCollateral(collateralAmount);

        // Borrow against the collateral
        crediflex.borrow(borrowAmount);

        // Check if the borrowed amount is transferred to the borrower
        console.log("Health Factor:", crediflex.calculateHealth(BORROWER));

        (uint256 supplyShares, uint256 borrowShares, uint256 collateral) =
            crediflex.positions(BORROWER);
        console.log("Borrower Position - Supply Shares:", supplyShares);
        console.log("Borrower Position - Borrow Shares:", borrowShares);
        console.log("Borrower Position - Collateral:", collateral);

        vm.stopPrank();
    }

    function testCalculateHealthWithMaxLTV() public suppliedByLender {
        uint256 cScore = MAX_C_SCORE + 1e18;
        ICrediflexServiceManager.Task memory task = crediflexManager.createNewTask(BORROWER);
        crediflexManager.respondToTask(task, cScore, 0, "");

        vm.startPrank(BORROWER);
        uint256 collateralAmount = 1 ether; // 1800 USD
        uint256 borrowAmount = 1000e6; // 100 USD

        // Approve and supply collateral
        IERC20(weth).approve(address(crediflex), collateralAmount);
        crediflex.supplyCollateral(collateralAmount);

        // Borrow against the collateral
        crediflex.borrow(borrowAmount);

        // Check if the borrowed amount is transferred to the borrower
        console.log("Health Factor:", crediflex.calculateHealth(BORROWER));

        (uint256 supplyShares, uint256 borrowShares, uint256 collateral) =
            crediflex.positions(BORROWER);
        console.log("Borrower Position - Supply Shares:", supplyShares);
        console.log("Borrower Position - Borrow Shares:", borrowShares);
        console.log("Borrower Position - Collateral:", collateral);

        vm.stopPrank();
    }
}
