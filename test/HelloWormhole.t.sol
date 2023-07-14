// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/HelloWormhole.sol";

import "wormhole-solidity-sdk/testing/WormholeRelayerTest.sol";

contract HelloWormholeTest is WormholeRelayerBasicTest {
    event GreetingReceived(string greeting, uint16 senderChain, address sender);

    HelloWormhole helloSource;
    HelloWormhole helloTarget;

    function setUpSource() public override {
        helloSource = new HelloWormhole(address(relayerSource));
    }

    function setUpTarget() public override {
        helloTarget = new HelloWormhole(address(relayerTarget));
    }

    function testGreeting_Step1() public {

        bytes32 sourceAddress = toWormholeFormat(address(helloSource));
        address sender = address(this);

        vm.selectFork(targetFork);

        vm.expectEmit(true, true, true, true, address(helloTarget));
        emit GreetingReceived("Hello Wormhole!", sourceChain, sender);
        vm.prank(address(relayerTarget));
        helloTarget.receiveWormholeMessages(
            abi.encode("Hello Wormhole!", sender),
            new bytes[](0),
            sourceAddress,
            sourceChain,
            keccak256("Arbitrary Delivery Hash")
        );

        assertEq(helloTarget.latestGreeting(), "Hello Wormhole!");
    }

    function testGreeting_Complete() public {

        uint256 cost = helloSource.quoteCrossChainGreeting(targetChain);

        vm.recordLogs();

        helloSource.sendCrossChainGreeting{value: cost}(targetChain, address(helloTarget), "Hello Wormhole!");

        performDelivery();

        vm.selectFork(targetFork);
        assertEq(helloTarget.latestGreeting(), "Hello Wormhole!");
    }
}
