// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {OGClubClubs} from "../src/OGClubClubs.sol";
import {OGClubFurniture} from "../src/OGClubFurniture.sol";
import {OGClubFarmVault} from "../src/OGClubFarmVault.sol";
import {MockOG} from "../src/mocks/MockOG.sol";
import {ClubDeployment, DeployClubsSepolia, DeployClubsMainnet} from "../script/DeployClubs.s.sol";

contract ClubsConstructorFactory {
    function deploy(bytes memory code, bytes32 salt) external returns (address created) {
        assembly ("memory-safe") {
            created := create2(0, add(code, 32), mload(code), salt)
        }
        require(created != address(0), "constructor failed");
    }
}

contract ClubsDeploymentTest is Test {
    address internal owner = makeAddr("club deployment owner");
    address internal royalty = makeAddr("club deployment royalty");

    function test_SepoliaScriptDeploysRealDependenciesConfiguresAndOpensSale() public {
        vm.chainId(11155111);
        DeployClubsSepolia script = new DeployClubsSepolia();
        (MockOG token, OGClubFurniture furniture, OGClubFarmVault vault, OGClubClubs clubs) =
            script.deploy(owner, royalty, "[[0,1,1],[7,2,1],[99,4,4]]");
        assertEq(token.balanceOf(owner), token.INITIAL_SUPPLY());
        assertEq(furniture.owner(), owner);
        assertEq(vault.owner(), owner);
        assertEq(clubs.owner(), owner);
        assertEq(address(vault.token()), address(token));
        assertEq(address(clubs.token()), address(token));
        assertEq(clubs.vault(), address(vault));
        assertEq(address(clubs.furniture()), address(furniture));
        assertEq(clubs.price(), 100_000e18);
        assertTrue(clubs.saleOpen());
        _assertFootprint(clubs, 0, 1, 1);
        _assertFootprint(clubs, 7, 2, 1);
        _assertFootprint(clubs, 99, 4, 4);
        assertFalse(furniture.bootstrapped()); // Club scripts do not consume the raffle's first grant.
        (address receiver, uint256 amount) = clubs.royaltyInfo(1, 10_000);
        assertEq(receiver, royalty);
        assertEq(amount, 500);
        vm.startPrank(owner);
        token.approve(address(clubs), clubs.price());
        assertEq(clubs.mintClub(), 1);
        vm.stopPrank();
        assertEq(token.balanceOf(address(vault)), 50_000e18);
        assertEq(token.balanceOf(clubs.BURN_ADDRESS()), 50_000e18);
        assertEq(token.balanceOf(address(clubs)), 0);
    }

    function test_MainnetScriptUsesSuppliedDependenciesAndLeavesSaleClosed() public {
        vm.chainId(1);
        // Dependencies deliberately have no code: the constructor cannot call them.
        DeployClubsMainnet.Config memory config = DeployClubsMainnet.Config({
            token: IERC20(makeAddr("existing OG")),
            vault: makeAddr("existing farm vault"),
            price: 123,
            furniture: IERC1155(makeAddr("existing furniture")),
            owner: owner,
            royaltyReceiver: royalty
        });
        DeployClubsMainnet script = new DeployClubsMainnet();
        OGClubClubs clubs = script.deploy(config, "[[7,2,1]]");
        assertEq(address(clubs.token()), address(config.token));
        assertEq(clubs.vault(), config.vault);
        assertEq(clubs.price(), 123);
        assertEq(address(clubs.furniture()), address(config.furniture));
        assertEq(clubs.owner(), owner);
        assertFalse(clubs.saleOpen());
        _assertFootprint(clubs, 7, 2, 1);
        vm.expectRevert(OGClubClubs.SaleClosed.selector);
        clubs.mintClub();
    }

    function test_EmptyFootprintsAreExplicitlyUnconfiguredAndScriptsEnforceChain() public {
        vm.chainId(31337);
        DeployClubsSepolia script = new DeployClubsSepolia();
        (,,, OGClubClubs clubs) = script.deploy(owner, royalty, "[]");
        (,, bool set, bool locked) = clubs.footprintOf(7);
        assertFalse(set);
        assertFalse(locked);
        vm.chainId(1);
        vm.expectRevert(ClubDeployment.WrongChain.selector);
        script.deploy(owner, royalty, "[]");
        DeployClubsMainnet mainnet = new DeployClubsMainnet();
        vm.chainId(11155111);
        DeployClubsMainnet.Config memory config;
        vm.expectRevert(ClubDeployment.WrongChain.selector);
        mainnet.deploy(config, "[]");
    }

    function test_FootprintJSONValidatesBeforeDeploymentWithoutTruncation() public {
        DeployClubsSepolia script = new DeployClubsSepolia();
        string[10] memory invalid = [
            string("[[7,0,1]]"),
            "[[7,1,5]]",
            "[[7,256,1]]",
            "[[7,1]]",
            "[[7,1,1,2]]",
            "[[7,-1,1]]",
            "[[-1,1,1]]",
            "[[7,1.5,1]]",
            "[[true,1,1]]",
            "not JSON"
        ];
        for (uint256 i; i < invalid.length; ++i) {
            vm.expectRevert();
            script.parseFootprints(invalid[i]);
        }
        vm.expectRevert(abi.encodeWithSelector(ClubDeployment.DuplicateFootprint.selector, uint256(7)));
        script.parseFootprints("[[7,1,1],[7,2,1]]");
        uint256[][] memory rows = script.parseFootprints(
            "[[115792089237316195423570985008687907853269984665640564039457584007913129639935,4,4]]"
        );
        assertEq(rows[0][0], type(uint256).max);
        assertEq(rows[0][1], 4);
    }

    function test_FactoryConstructorWorksOnEmptyChainWithExplicitOwnerAndBoundedRuntime() public {
        ClubsConstructorFactory factory = new ClubsConstructorFactory();
        address absentToken = makeAddr("absent token");
        address absentFurniture = makeAddr("absent furniture");
        address absentVault = makeAddr("absent vault");
        bytes memory code = abi.encodePacked(
            vm.getCode("OGClubClubs.sol:OGClubClubs"),
            abi.encode(absentToken, absentVault, 100_000e18, absentFurniture, owner, royalty)
        );
        assertLe(code.length, 49_152);
        OGClubClubs clubs = OGClubClubs(factory.deploy(code, bytes32(uint256(1))));
        assertEq(clubs.owner(), owner);
        assertTrue(clubs.owner() != address(factory));
        assertFalse(clubs.saleOpen());
        assertEq(address(clubs.token()), absentToken);
        assertEq(address(clubs.furniture()), absentFurniture);
        _checkRuntime(address(clubs).code);
    }

    function test_PredictedSelfVaultIsRejected() public {
        address predicted = vm.computeCreateAddress(address(this), vm.getNonce(address(this)));
        vm.expectRevert(OGClubClubs.UnexpectedTokenDebit.selector);
        new OGClubClubs(IERC20(makeAddr("token")), predicted, 1, IERC1155(makeAddr("furniture")), owner, royalty);
    }

    function _assertFootprint(OGClubClubs clubs, uint256 id, uint8 width, uint8 height) private view {
        (uint8 w, uint8 h, bool set, bool locked) = clubs.footprintOf(id);
        assertEq(w, width);
        assertEq(h, height);
        assertTrue(set);
        assertFalse(locked);
    }

    function _checkRuntime(bytes memory code) private pure {
        assertGt(code.length, 0);
        assertLe(code.length, 24_576);
        bool reachable = true;
        for (uint256 i; i < code.length; ++i) {
            uint8 op = uint8(code[i]);
            if (op == 0x5b) reachable = true;
            if (op >= 0x60 && op <= 0x7f) {
                i += op - 0x5f;
                continue;
            }
            if (reachable) assertTrue(op != 0xf4 && op != 0xf2 && op != 0xff, "forbidden application opcode");
            if (op == 0x00 || op == 0x56 || op == 0xf3 || op == 0xfd || op == 0xff) reachable = false;
        }
    }
}
