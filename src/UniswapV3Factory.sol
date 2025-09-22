// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IUniswapV3PoolDeployer.sol";

contract UniswapV3Factory is IUniswapV3PoolDeployer {
    mapping(uint24 => bool) public tickSpacings;
    constructor() {
        tickSpacings[10] = true;
        tickSpacings[60] = true;


    PoolParameters public parameters;
    mapping(address => mapping(address => mapping(uint24 => address)))
        public pools;


    function createPool(
        address tokenX,
        address tokenY,
        uint24 tickSpacing
    ) public returns (address pool) {
        if (tokenX == tokenY) revert TokensMustBeDifferent();
        if (!tickSpacings[tickSpacing]) revert UnsupportedTickSpacing();

        (tokenX, tokenY) = tokenX < tokenY
            ? (tokenX, tokenY)
            : (tokenY, tokenX);

        if (tokenX == address(0)) revert TokenXCannotBeZero();
        if (pools[tokenX][tokenY][tickSpacing] != address(0))
            revert PoolAlreadyExists();

        parameters = PoolParameters({
            factory: address(this),
            token0: tokenX,
            token1: tokenY,
            tickSpacing: tickSpacing
        });

        pool = address(
            new UniswapV3Pool{salt: keccak256(abi.encodePacked(tokenX, tokenY, tickSpacing))}()
        );

        delete parameters;

        pools[tokenX][tokenY][tickSpacing] = pool;
        pools[tokenY][tokenX][tickSpacing] = pool;

        emit PoolCreated(tokenX, tokenY, tickSpacing, pool);

    }
