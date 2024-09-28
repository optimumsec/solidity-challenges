pragma solidity 0.8.0;

contract JackpotOrHoneypot1 {
    address private jackpotProxy;

    constructor(address _jackpotProxy) payable {
        jackpotProxy = _jackpotProxy;
    }

    modifier onlyJackpotProxy() {
        require(msg.sender == jackpotProxy);
        _;
    }

    function claimPrize(uint amount) external payable onlyJackpotProxy {
        payable(msg.sender).transfer(amount * 2);
    }

    fallback() external payable {}
}

contract JackpotProxy {
    function claimPrize(address _jackpot) external payable {
        uint amount = msg.value;
        require(amount > 0, "zero deposit");
        (bool success, ) = _jackpot.call{value: amount}(
            abi.encodeWithSignature("claimPrize(uint)", amount)
        );
        require(success, "failed");
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}
