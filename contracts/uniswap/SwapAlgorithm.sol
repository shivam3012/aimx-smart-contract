// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";

library SwapAlgorithm {
    using SafeERC20 for IERC20;

    function _secondTokenAmountForLp(
        uint256 _amountIn,
        address _pair,
        address _tokenA,
        address _tokenB
    ) internal view returns (uint256 _liquidity) {
        (uint256 _amountAReserve, uint256 _amountBReserve) = getPairReserves(
            _pair,
            _tokenA,
            _tokenB
        );
        return quote(_amountIn, _amountAReserve, _amountBReserve);
    }

    function _addLiquidity(
        uint256 _amountA,
        uint256 _amountB,
        address _tokenA,
        address _tokenB,
        address _router,
        address _receiver
    ) internal returns (uint256 _liquidity) {
        //approve nrgy coins to uniswap
        (, , _liquidity) = IUniswapV2Router(_router).addLiquidity(
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            0,
            0,
            _receiver,
            block.timestamp + 1800
        );
    }

    function _removeLiquidity(
        uint256 _lpIn,
        address _receiver,
        address _tokenA,
        address _tokenB,
        address _router
    ) internal returns (uint256 _amountA, uint256 _amountB) {
        require(
            _lpIn > 0,
            "SwapAlgorithm: Insufficient lp token for liquidity removal"
        );
        // approve pair contract to router before doing this step
        (_amountA, _amountB) = IUniswapV2Router(_router).removeLiquidity(
            _tokenA,
            _tokenB,
            _lpIn,
            0,
            0,
            _receiver,
            block.timestamp + 1800
        );
    }

    function _swapEth(
        uint256 _amount,
        address _receiver,
        address _router,
        address[] memory _path
    ) internal returns (uint256) {
        return
            IUniswapV2Router(_router).swapExactETHForTokens{value: msg.value}(
                getOutputAmount(_amount, _path, _router),
                _path,
                _receiver,
                block.timestamp + 1800
            )[_path.length - 1];
    }

    function _swap(
        uint256 _amount,
        address _receiver,
        address _router,
        address[] memory _path
    ) internal returns (uint256) {
        return
            IUniswapV2Router(_router).swapExactTokensForTokens(
                _amount,
                getOutputAmount(_amount, _path, _router),
                _path,
                _receiver,
                block.timestamp + 1800
            )[_path.length - 1];
    }

    function getOutputAmount(
        uint256 _amountIn,
        address[] memory _path,
        address _router
    ) internal view returns (uint256 _output) {
        uint256[] memory amounts = IUniswapV2Router(_router).getAmountsOut(
            _amountIn,
            _path
        );
        return amounts[amounts.length - 1];
    }


    function getInputAmount(
        uint256 _amountOut,
        address[] memory _path,
        address _router
    ) internal view returns (uint256 _output) {
        uint256[] memory amounts = IUniswapV2Router(_router).getAmountsIn(
            _amountOut,
            _path
        );
        return amounts[0];
    }

    function getPairReserves(
        address _pair,
        address _tokenA,
        address _tokenB
    ) internal view returns (uint256 _tokenAReserves, uint256 _tokenBReserves) {
        (address token0, ) = sortTokens(_tokenA, _tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair)
            .getReserves();
        (_tokenAReserves, _tokenBReserves) = token0 == _tokenA
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "SwapAlgorithm: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "SwapAlgorithm: ZERO_ADDRESS");
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) internal pure returns (uint amountB) {
        require(amountA > 0, "SwapAlgorithm: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "SwapAlgorithm: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * (reserveB)) / reserveA;
    }
}
