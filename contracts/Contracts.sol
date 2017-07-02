pragma solidity ^0.4.10;

contract ArbiterPool {
    Arbiter[] public arbiters;
    address public manager;
    uint public length = 0;

    struct Arbiter{address adr; uint id;}

    function ArbiterPool(address _manager) {
        manager = _manager;
    }

    function addArbiter(address _adr, uint _id) {
        Arbiter memory arbiter = Arbiter({adr: _adr, id: _id });
        arbiters.push(arbiter);
        length +=1;
    }

    function showArbiter(uint index) returns(address adr) {
        adr = arbiters[index].adr;
    }

    modifier onlyManager {
        assert(msg.sender == manager);
        _;
    }
}

contract Deal {

    string public title;
    string public description;

    address public customer;
    address public contractor;
    address public arbiter;
    address public commissionHolder = '0x97212D91e54cB4bf986a18f10A5630828f186F52';

    uint public openTime;
    uint public closeTime;
    uint public customerDeposit; //wei
    uint public deposit; //wei
    uint public commission = 5; //percents
	uint public decideTime;
    ArbiterPool public arbiterPool;

    bool public accepted = false;
    bool public closed = false;
    bool public customerConfirmed = false;
    bool public contractorConfirmed = false;
    bool public customerWon;
    bool public contractorWon;
    bool public arbitraged = false;

    function Deal(string _title, string _description, address _customer, address _contractor, uint _openTime, uint _closeTime, uint _deposit, address _arbiterPoolAddress) payable {
        assert(_closeTime >= _openTime);
        customerDeposit = msg.value;
        arbiterPool = ArbiterPool(_arbiterPoolAddress);
        title = _title;
        description = _description;
        customer = _customer;
        contractor = _contractor;
        if (_openTime != 0) {
            assert(_openTime > now);
            openTime = _openTime;
        } else {
            openTime = now + 600;
        }
        if (_closeTime != 0) {
            closeTime = _closeTime;
        } else {
            closeTime = now + 1200;
        }
        deposit = _deposit;
    }

    function() payable onlyCustomer notAccepted {
        assert(now < openTime);
        customerDeposit += msg.value;
    }

    function decide(address _winner) onlyArbiter {
        assert(now > decideTime);
        if (_winner == customer) {
            customerWon = true;
        } else if (_winner == contractor) {
            contractorWon = true;
        } else {
            throw;
        }
    }

    function confirm() onlyParty {
        assert(now > openTime);
        if (msg.sender == customer) {
            customerConfirmed = true;
        } else if (msg.sender == contractor) {
            contractorConfirmed = true;
        } else {
            throw;
        }
        if (customerConfirmed && contractorConfirmed) {
            successfulClose();
            closed = true;
        }
    }

    function openArbitrage() onlyParty notArbitraged {
        arbitraged = true;
        arbiter = arbiterPool.showArbiter((uint(block.blockhash(10)) + uint(sha3(now))) % arbiterPool.length());
    }

    function successfulClose() internal {
        contractor.transfer(this.balance);
    }

    function cancelDeal() onlyCustomer notAccepted {
        suicide(customer);
    }

    function accept() onlyContractor notAccepted {
        assert(now < openTime);
        assert(customerDeposit == deposit);
        accepted = true;
    }

    function voteCustomer() onlyArbiter {
        uint fee = commission*this.balance/200;
        commissionHolder.transfer(fee); // may throw, send should be used
        arbiter.transfer(fee);
        customerWon = true;
        customer.transfer(this.balance);
    }

    function voteContractor() onlyArbiter {
        uint fee = commission*this.balance/200;
        commissionHolder.transfer(fee); // may throw, send should be used
        arbiter.transfer(fee);
        contractorWon = true;
        successfulClose();
    }

    modifier notArbitraged {
        assert(!arbitraged);
        _;
    }

    modifier notAccepted() {
        assert(!accepted);
        _;
    }

    modifier onlyParty() {
        assert(msg.sender == customer || msg.sender == contractor);
        _;
    }

    modifier onlyContractor() {
        assert(msg.sender == contractor);
        _;
    }
    
    modifier onlyCustomer() {
        assert(msg.sender == customer);
        _;
    }
    
    modifier onlyFromArbiterPool() {
        //assert(arbiterPool.arbiters(msg.sender));
        _;
    }

    modifier onlyArbiter() {
        assert(msg.sender == arbiter);
        _;
    }
}

contract DealFactory {

    address[256] public deals;
    uint public length=0;

    function DealFactory() { }

    function () payable {}

    function createDeal(string _title, string _description, address _contractor, uint _openTime, uint _closeTime, uint _deposit) payable {
        address dealAddress = (new Deal).value(msg.value)(_title, _description, msg.sender, _contractor, _openTime, _closeTime, _deposit,"0x934eBEc7a0596B8B3D4B28613b1BdbD8AC198102");
        deals[length]= dealAddress;
        length +=1;
    }

}

