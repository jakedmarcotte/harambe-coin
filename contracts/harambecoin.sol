pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


contract HarambeCoin is owned{
    // Public variables of the token
    string public name;
    string public symbol;
    uint256 public decimals = 18;
    uint256 public totalSupply;
    bool public isTradable;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function HarambeCoin(
        string tokenName,
        string tokenSymbol,
        address centralMinter
    ) public {
        totalSupply = 0;                                    // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        isTradable = false;                                   //blocks trading functions until after the ICO
        if(centralMinter != 0 ) owner = centralMinter;      // Set the owner of the contract

    }

    /**
     * Modifier used to block the transfer of HarambeCoin until aftr the ICO ends.
     */
    modifier tradable() {
        if (isTradable) {
            _;
        }
    }

    /**
     * Updates tradable status, for use after the ICO ends
     *
     * @param status the new bool value of tradable
     */
    function updateTradable(bool status) onlyOwner public {
        isTradable = status;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Returns total supply of the contract
     */
    function totalSupply() constant public returns (uint256 total){
        return totalSupply;
    }

    /**
     * Returns balance of particular address of account
     */
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balanceOf[_owner];
    }



    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public tradable returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev ERC20 transferFrom, modified such that an allowance of MAX_UINT represents an unlimited allowance.
    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint _value)
        public tradable returns (bool success)
    {
        uint allowance_amount = allowance[_from][msg.sender];
        require(balanceOf[_from] >= _value
                && allowance_amount >= _value
                && balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public tradable returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    /**
     * Returns allowance of the owner to the pro
     */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }


    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    /**
     * Mints coins directly to wallet address
     *
     * Allows the contract owner to mint `mintedAmount` tokens to an address
     *
     * @param _to The address reciving the coins
     * @param mintedAmount The amount of coin being minted
     */
    function mintToken(address _to, uint256 mintedAmount) onlyOwner public {
        uint256 total = mintedAmount * (10 ** decimals);
        balanceOf[_to] += total;
        totalSupply += mintedAmount;
        Transfer(0, owner, total);
        Transfer(owner, _to, total);
    }

}

