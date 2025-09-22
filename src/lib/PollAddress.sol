// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../UniswapV3Pool.sol";

library poolAddress{
    function computeAddress(
        address factory,
        address token0,
        address token1,
        uint24 tickSpacing,
    ) internal pure returns(address pool){
        require(token0 < token1);

        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encodePacked(token0, token1, tickSpacing)
                            ),
                            keccak256(type(UniswapV3Pool).creationCode)
                        )
                    )
                )
            )
        );

    }
}