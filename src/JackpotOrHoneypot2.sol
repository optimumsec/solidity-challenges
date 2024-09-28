pragma solidity 0.8.0;
// The prize is 10 eth, anyone can deposit during the deposit phase which lasts 7 days.
// After that, anyone can call payPrize, the first one to call this function and which had deposited the maximum amount
// (~9.22 eth) will get the 10 eth prize + deposit, the rest will get their deposit back.
contract JackpotOrHoneypot2 {
    mapping(address => int256) public amountsDue;
    uint256 initTime;
    bool prizePaid;
    constructor() payable {
        require(msg.value == 10 ether);
        initTime = block.timestamp;
    }
    function deposit() external payable {
        require(block.timestamp <= initTime + 7 days, "deposit phase ended");
        require(msg.value <= 9223372036854775808, "maximum deposit"); // type(int64).min
        require(amountsDue[msg.sender] == 0, "only single deposit is allowed");
        amountsDue[msg.sender] -= int256(msg.value);
    }

    function payPrize() external {
        require(
            block.timestamp > initTime + 7 days,
            "withdraw phase has not begun yet"
        );
        int256 amountDue = amountsDue[msg.sender];
        // safe casting to uint256 for the transfer call
        uint256 toPay = uint256(-amountDue);
        if (isMaxPrize(toPay) && !prizePaid) {
            toPay += 10 ether;
            prizePaid = true;
        }
        amountsDue[msg.sender] = 0;
        payable(msg.sender).transfer(toPay);
    }
    function isMaxPrize(uint256 _prize) internal pure returns (bool) {
        return _prize == uint64(-type(int64).min);
    }
}
