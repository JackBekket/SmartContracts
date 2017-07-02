pragma solidity ^0.4.10;

contract Deal {

    address public customer;
    address public contractor;
    address public arbiter = "0x4C67EB86d70354731f11981aeE91d969e3823c39";
    uint public openTime;
    uint public closeTime;
    uint public deposit; //wei

    function Deal(address _customer, address _contractor, uint _openTime, uint _closeTime, uint _deposit) {
        assert(_closeTime >= _openTime);
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

}

contract DealFactory {

    address[256] public deals;
    uint public length=0;

    function DealFactory() { }

    function () payable {}

    function createDeal(address _contractor, uint _openTime, uint _closeTime, uint _deposit) payable {
        address dealAddress = new Deal(msg.sender, _contractor, _openTime, _closeTime, _deposit);
        deals[length]= dealAddress;
        length +=1;
    }

}

