pragma solidity 0.8.20;
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
interface IReceiver {
    // stores the owner of the receiver contract, can only be called once
    function init(address _owner) external payable;
    // Allows only the owner defined in the init function to claim the contract balance
    function pullRewards() external;
}
// participants deposit 1 eth during the deposit phase which lasts 7 days.
// After that, the first depositor to call payPrize will be able to claim all the previous deposits.
// The contract will clone a Receiver contract for the winner (by using ReceiverFactory which relies on the Clones
// library)
// and will send the prize to this address. The prize will be claimable only by the _owner defined during deposit.
contract JackpotOrHoneypot3 is ReentrancyGuard {
    mapping(address => address) public depositsOwners;
    uint256 initTime;
    bool prizePaid;
    ReceiverFactory receiverFactory;
    constructor(ReceiverFactory _receiverFactory) {
        initTime = block.timestamp;
        // Assume receiverFactory is initialized correctly
        receiverFactory = _receiverFactory;
    }
    function deposit(address _owner) external payable nonReentrant {
        require(_owner != address(0));
        require(block.timestamp <= initTime + 7 days, "deposit phase ended");
        require(msg.value == 1 ether);
        require(
            depositsOwners[msg.sender] == address(0),
            "only single deposit is allowed"
        );
        depositsOwners[msg.sender] = _owner;
    }
    function payPrize() external nonReentrant {
        require(!prizePaid);
        require(
            block.timestamp > initTime + 7 days,
            "withdraw phase has not begun yet"
        );
        address owner = depositsOwners[msg.sender];
        require(owner != address(0), "no deposit made");
        prizePaid = true;
        depositsOwners[msg.sender] = address(0);
        address receiver = receiverFactory.createReceiverContract(owner);
        payable(receiver).transfer(address(this).balance);
    }
}
contract ReceiverFactory {
    IReceiver receiverImplementation;
    // Assume correctness of the IReceiver contract implementation
    constructor(IReceiver _implementation) {
        receiverImplementation = _implementation;
    }
    function createReceiverContract(
        address _owner
    ) public returns (address receiver) {
        receiver = Clones.cloneDeterministic(
            address(receiverImplementation),
            keccak256(abi.encode(_owner))
        );
        IReceiver(receiver).init(_owner);
    }
}
