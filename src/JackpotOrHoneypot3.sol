pragma solidity 0.8.0;
// The prize is 10 eth, anyone can deposit during the deposit phase which lasts 7 days.
// After that, anyone can call payPrize, the first one to call this function will
contract JackpotOrHoneypot3 {
    mapping(address => address) public depositsOwners;
    uint256 initTime;
    bool prizePaid;
    constructor() payable {
        require(msg.value == 10 ether);
        initTime = block.timestamp;
    }
    function deposit(address _owner) external payable {
        require(_owner != address(0));
        require(block.timestamp <= initTime + 7 days, "deposit phase ended");
        require(msg.value == 1 ether);
        require(depositsOwners[msg.sender] == address(0), "only single deposit is allowed");
        depositsOwners[msg.sender] = _owner;
    }

    function payPrize() external {
        address owner = depositsOwners[msg.sender];
        require(owner != address(0), "no deposit made");
        uint256 toPay = 1 ether;
        require(
            block.timestamp > initTime + 7 days,
            "withdraw phase has not begun yet"
        );
        if (!prizePaid) {
            toPay += 10 ether;
            prizePaid = true;
        }
        depositsOwners[msg.sender] = address(0);
        payable(msg.sender).transfer(toPay);
    }
    function isMaxPrize(uint256 _prize) external returns (bool) {
        return _prize == uint64(-type(int64).min);
    }
}
