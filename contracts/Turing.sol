//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// This is the main building block for smart contracts.
contract Turing is ERC20 {

    // Quem fez o deploy. Antes esta variável nunca era preenchida (ficava em 0x0),
    // então o ramo "msg.sender == owner" do modifier jamais era verdadeiro.
    address public owner;

    // Endereço da professora. Os poderes de superusuário dependem DESTE endereço
    // (e do owner), e não mais do codinome 'roberta' no livro de nomes, que pode
    // ser apagado/movido por _setUser.
    address public professor;

    // Those I created for the dApp
    mapping(string => address) public users;
    mapping(address => string) public addresses;

    bool public voting = true;
    mapping(address => mapping(address => bool)) public hasVoted;
    mapping(address => uint256) public voteAmount;

    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == professor, "You're not allowed to use this operation.");
        _;
    }

    /**
     * Contract initialization.
     */
    constructor() ERC20("Turing", "TTK") {
        owner = msg.sender;
        professor = 0x502542668aF09fa7aea52174b9965A7799343Df7;

        _setUser('owner', msg.sender);
        _setUser('roberta', professor);
        _setUser('nome1', 0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        _setUser('nome2', 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
        _setUser('nome3', 0x90F79bf6EB2c4f870365E785982E1f101E93b906);
        _setUser('nome4', 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
        _setUser('nome5', 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
    }

    function _setUser(string memory codename, address addr) internal {
        require(addr != address(0), "Invalid address.");

        // Libera o endereço antigo deste codinome
        address oldAddr = users[codename];
        if (oldAddr != address(0)) delete addresses[oldAddr];

        // Libera o codinome antigo deste endereço
        if (bytes(addresses[addr]).length > 0) delete users[addresses[addr]];

        users[codename] = addr;
        addresses[addr] = codename;
    }

    function updateUser(string memory codename, address user_addr) external onlyOwner {
        require(bytes(codename).length > 0, "Unfortunately, I'm unable to update an empty username!");
        _setUser(codename, user_addr);

        // Se o codinome da professora mudou de endereço, o poder acompanha.
        if (keccak256(bytes(codename)) == keccak256(bytes("roberta"))) professor = user_addr;
    }

    function votingOn() onlyOwner external {
        voting = true;
    }

    function votingOff() onlyOwner external {
        voting = false;
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function issueToken(string memory codename, uint256 amount) external onlyOwner {
        address target = users[codename];
        require(target != address(0), "Do I know you?");
        _mint(target, amount);
    }

    function vote(string memory codename, uint256 amount) external {
        address target = users[codename];

        require(voting, "Vote is off. Then get off!");
        require(bytes(addresses[msg.sender]).length > 0, "YOUR NAME ISN'T IN THE BOOK!");
        require(target != address(0), "I've never seen this user in my entire code life.");
        require(target != msg.sender, "I wish you could vote for yourself. But you can't.");
        require(amount > 0 && amount <= 2, "You must vote with a value of 1 or 2.");
        require(!hasVoted[msg.sender][target], "You've already voted for this one darling <3");

        hasVoted[msg.sender][target] = true;
        voteAmount[msg.sender] += 1;
        _mint(target, amount);

        if (voteAmount[msg.sender] % 10 == 0) _mint(msg.sender, 1);
    }

}
