pragma solidity 0.8.20;
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
// Assume correctness of the IReceiver contract implementation
interface IReceiver {
    // stores the owner of the receiver contract, can only be called once
    function init(address _owner) external payable;
    // Allows only the owner defined in the init function to claim the contract balance
    function pullRewards() external;
}
// The prize is 10 eth, anyone can deposit during the deposit phase which lasts 7 days.
// After that, anyone can call payPrize, the first one to call this function will be able to claim the prize.
// The contract will clone a Receiver contract for the winner (by using ReceiverFactory which relies on the Clones
// library)
// and will send the prize to this address. The prize will be claimable only by the _owner defined during deposit.
contract JackpotOrHoneypot3 {
    mapping(address => address) public depositsOwners;
    uint256 initTime;
    bool prizePaid;
    ReceiverFactory receiverFactory;
    constructor(ReceiverFactory _receiverFactory) payable {
        require(msg.value == 10 ether);
        initTime = block.timestamp;
        receiverFactory = _receiverFactory;
    }
    function deposit(address _owner) external payable {
        require(_owner != address(0));
        require(block.timestamp <= initTime + 7 days, "deposit phase ended");
        require(msg.value == 1 ether);
        require(
            depositsOwners[msg.sender] == address(0),
            "only single deposit is allowed"
        );
        depositsOwners[msg.sender] = _owner;
    }
    function payPrize() external {
        require(
            block.timestamp > initTime + 7 days,
            "withdraw phase has not begun yet"
        );
        require(block.timestamp < initTime + 8 days, "withdraw phase is over");
        address owner = depositsOwners[msg.sender];
        require(owner != address(0), "no deposit made");
        uint256 toPay = 1 ether;

        if (!prizePaid) {
            toPay += 10 ether;
            prizePaid = true;
        }
        depositsOwners[msg.sender] = address(0);
        receiverFactory.sendPrizeToReceiverContract(owner, toPay);
    }
}
contract ReceiverFactory {
    address receiverImplementation;
    constructor(address _implementation) {
        receiverImplementation = _implementation;
    }
    function sendPrizeToReceiverContract(address _owner, uint256 toPay) public {
        address receiver = Clones.cloneDeterministic(
            receiverImplementation,
            keccak256(abi.encode(_owner))
        );
        IReceiver(receiver).init{value: toPay}(_owner);
    }
}
