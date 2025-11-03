pragma solidity ^0.8.0;

contract DAOTreasury {

    struct Proposal {
        uint id;
        string desc;
        uint deadline;
        uint yes;
        uint no;
        bool done;
        address creator;
        address to;
        uint amount;
        mapping(address => bool) voted;
    }

    address public admin;
    mapping(address => bool) public members;
    Proposal[] public proposals;
    uint public propCount;

    event ProposalCreated(uint id, string desc, uint deadline);
    event Voted(uint id, address voter, bool support);
    event ProposalExecuted(uint id, address to, uint amount);

    constructor() {
        admin = msg.sender;
        members[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "admin:!");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "member:!");
        _;
    }

    receive() external payable {}

    function addMember(address _member) public onlyAdmin {
        require(_member != address(0), "zero:!");
        members[_member] = true;
    }

    function createProposal(string memory _desc, uint _duration, address _to, uint _amount) public onlyMember {
        require(_duration > 0, "time:!");
        uint deadline = block.timestamp + _duration;

        Proposal storage p = proposals.push();
        p.id = propCount;
        p.desc = _desc;
        p.deadline = deadline;
        p.creator = msg.sender;
        p.to = _to;
        p.amount = _amount;

        propCount++;

        emit ProposalCreated(p.id, _desc, deadline);
    }

    function vote(uint _id, bool _support) public onlyMember {
        require(_id < propCount, "id:!");
        Proposal storage p = proposals[_id];
        require(!p.voted[msg.sender], "voted:!");
        require(block.timestamp < p.deadline, "deadline:!");

        p.voted[msg.sender] = true;

        if (_support) p.yes++;
        else p.no++;

        emit Voted(_id, msg.sender, _support);
    }

    function executeProposal(uint _id) public onlyMember {
        require(_id < propCount, "id:!");
        Proposal storage p = proposals[_id];
        require(!p.done, "done:!");
        require(block.timestamp >= p.deadline, "active:!");
        require(p.yes > p.no, "failed:!");

        p.done = true;

        if (p.to != address(0) && p.amount > 0) {
            require(address(this).balance >= p.amount, "funds:!");
            (bool sent, ) = p.to.call{value: p.amount}("");
            require(sent, "send:!");
        }

        emit ProposalExecuted(_id, p.to, p.amount);
    }

    function getProposal(uint _id) public view returns (
        uint, string memory, uint, uint, uint, bool, address, address, uint
    ) {
        require(_id < propCount, "id:!");
        Proposal storage p = proposals[_id];
        return (
            p.id,
            p.desc,
            p.deadline,
            p.yes,
            p.no,
            p.done,
            p.creator,
            p.to,
            p.amount
        );
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
