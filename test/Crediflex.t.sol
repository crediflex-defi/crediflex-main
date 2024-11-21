// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Crediflex} from "../src/Crediflex.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockCrediflexServiceManager} from "./mocks/MockCrediflexServiceManager.sol";
import {AggregatorV2V3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";
import {ICrediflexServiceManager} from "../interfaces/ICrediflexServiceManager.sol";

contract CrediflexTest is Test {
    Crediflex public crediflex;
    ICrediflexServiceManager public crediflexManager;
    HelperConfig public helperConfig;

    address usdeUsdDataFeed;
    address wethUsdDataFeed;
    address usde;
    address weth;
    uint256 deployerKey;

    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    address LENDER = makeAddr("lender");
    address BORROWER = makeAddr("borrower");
    uint256 public constant LENDING_AMOUNT = 5000 ether;

    function setUp() public {
        helperConfig = new HelperConfig();

        crediflexManager = new MockCrediflexServiceManager();
        (usdeUsdDataFeed, wethUsdDataFeed, usde, weth,) = helperConfig.activeNetworkConfig();

        crediflex = new Crediflex(address(crediflexManager), usdeUsdDataFeed, wethUsdDataFeed, usde, weth);

        ERC20Mock(weth).mint(BORROWER, STARTING_USER_BALANCE);
        ERC20Mock(usde).mint(BORROWER, STARTING_USER_BALANCE);
    }

    function testSupply() public {
        vm.startPrank(BORROWER);
        uint256 amount = 1 ether;
        IERC20(usde).approve(address(crediflex), amount);
        crediflex.supply(amount);
        assertEq(crediflex.totalSupplyShares(), amount);
        (uint256 shares,,) = crediflex.positions(BORROWER);

        assertEq(shares, amount);
        vm.stopPrank();
    }

    modifier suppliedByLender() {
        vm.startPrank(LENDER);
        ERC20Mock(usde).mint(LENDER, LENDING_AMOUNT);
        IERC20(usde).approve(address(crediflex), LENDING_AMOUNT);
        crediflex.supply(LENDING_AMOUNT);
        vm.stopPrank();
        _;
    }

    function testWithdraw() public {
        vm.startPrank(BORROWER);
        uint256 amount = 1 ether;
        IERC20(usde).approve(address(crediflex), amount);
        crediflex.supply(amount);

        (uint256 shares,,) = crediflex.positions(BORROWER);
        crediflex.withdraw(shares);
        assertEq(crediflex.totalSupplyShares(), 0);
        assertEq(IERC20(usde).balanceOf(BORROWER), STARTING_USER_BALANCE);
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
        uint256 borrowAmount = 0.5 ether; // USDE
        IERC20(weth).approve(address(crediflex), collateralAmount);
        crediflex.supplyCollateral(collateralAmount);

        // Attempt to borrow without any lender supplying funds
        vm.expectRevert("Insufficient supply to borrow");
        crediflex.borrow(borrowAmount);
        vm.stopPrank();
    }

    function testBorrowIsNotHealthy() public {
        vm.startPrank(BORROWER);
        uint256 collateralAmount = 1 ether; // WETH / USD 3000
        uint256 borrowAmount = 3000 ether; // USDE / USD 1.1
        IERC20(weth).approve(address(crediflex), collateralAmount);
        crediflex.supplyCollateral(collateralAmount);

        vm.expectRevert("Position is not healthy");
        crediflex.borrow(borrowAmount);
        vm.stopPrank();
    }

    function testBorrow() public suppliedByLender {
        vm.startPrank(BORROWER);
        uint256 collateralAmount = 1 ether; // WETH
        uint256 borrowAmount = 1000 ether; // USDE
        IERC20(weth).approve(address(crediflex), collateralAmount);
        crediflex.supplyCollateral(collateralAmount);

        uint256 expectedUsdeBalance = STARTING_USER_BALANCE + borrowAmount;

        crediflex.borrow(borrowAmount);
        (, uint256 borrowShares,) = crediflex.positions(BORROWER);
        assertEq(borrowShares, borrowAmount);

        uint256 usdeBalance = IERC20(usde).balanceOf(BORROWER);
        assertEq(usdeBalance, expectedUsdeBalance);
        vm.stopPrank();
    }

    function testRepay() public suppliedByLender {
        vm.startPrank(BORROWER);
        uint256 collateralAmount = 1 ether;
        uint256 borrowAmount = 0.5 ether;
        IERC20(weth).approve(address(crediflex), collateralAmount);
        crediflex.supplyCollateral(collateralAmount);

        crediflex.borrow(borrowAmount);
        IERC20(usde).approve(address(crediflex), borrowAmount);
        crediflex.repay(borrowAmount);
        (, uint256 borrowShares,) = crediflex.positions(BORROWER);
        assertEq(borrowShares, 0);
        vm.stopPrank();
    }
}
