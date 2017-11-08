pragma solidity ^0.4.11;
import "./vidamintToken.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "zeppelin-solidity/contracts/token/MintableToken.sol";
import "zeppelin-solidity/contracts/token/TokenTimelock.sol";
import "zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol";
import "zeppelin-solidity/contracts/crowdsale/RefundableCrowdsale.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";


contract VidamintSale is CappedCrowdsale, Pausable {
    using SafeMath for uint256;
    bool public preSaleIsStopped = false;
   // TokenTimelock[] public timelockTokens;
    event TransferredPreBuyersReward(address  preBuyer, uint amount);
    event TransferredlockedTokens (address vault, uint amount);

    function VidamintSale(
        address _owner,
        uint256 _startTime, 
        uint256 _endTime, 
        uint256 _rate,
        uint256 _goal, 
        uint256 _cap, 
        address _wallet)
        CappedCrowdsale(_cap)
        //FinalizableCrowdsale()
        //RefundableCrowdsale(_goal)
        Crowdsale(_startTime, _endTime, _rate, _wallet) {
            //As goal needs to be met for a successful crowdsale
            //the value needs to less or equal than a cap which is limit for accepted funds
            require(_goal <= _cap);
            owner = _owner;
            //pause();
    
        }
 
    modifier preSaleRunning() {
        assert(preSaleIsStopped == false);
        _;
    }
  
    function () whenNotPaused payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public whenNotPaused payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);
    
        // update state
        weiRaised = weiRaised.add(weiAmount);
        
        //tokens = tokens.mul(10**uint(18));
        require(tokens != 0);
        
        assert(token.mint(beneficiary, tokens));
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    /// @dev distributeFoundersRewards(): private utility function called by constructor
    /// @param _preBuyers an array of addresses to which awards will be distributed
    /// @param _preBuyersTokens an array of integers specifying preBuyers rewards
    function distributePreBuyersRewards(
        address[] _preBuyers,
        uint[] _preBuyersTokens
    ) public onlyOwner preSaleRunning { 
        for (uint i = 0; i < _preBuyers.length; i++) {
            uint tokenAmount = _preBuyersTokens[i].mul(10**uint(18));
            assert(token.mint(_preBuyers[i], tokenAmount));
            TransferredPreBuyersReward(_preBuyers[i], _preBuyersTokens[i]);
        }
        
    }

    function distributeTimeLockRewards(
        address[] _rewardees,
        uint[] _rewardeesTokens,
        uint64[] _rewardeeTimelocks
    ) public onlyOwner preSaleRunning { 
       
    for (uint j = 0; j < _rewardees.length; j++) {
        uint tokenAmount = _rewardeesTokens[j].mul(10**uint(18));
        MintableToken newToken = createTokenContract();
        TokenTimelock timeVault = new TokenTimelock(newToken, _rewardees[j], _rewardeeTimelocks[j]);
       // timelockTokens.push(timeVault);
        assert(token.mint(timeVault, tokenAmount));
        TransferredlockedTokens(_rewardees[j], tokenAmount);
    }

       
    }

     /*
     * Owner-only functions
     */
    function changeTokenUpgradeMaster(address _upgradeMaster) onlyOwner {
        require(_upgradeMaster != 0);
        VidamintToken tokenInstance = VidamintToken(token);
        tokenInstance.setUpgradeMaster(_upgradeMaster);
    }

    function changeOwner(address _newOwner) onlyOwner {
        require(_newOwner != 0);
        owner = _newOwner;
    }

    function changeRate(uint _newRate) onlyOwner {
        require(_newRate != 0);
        rate = _newRate;
    }

    function changeWallet(address _wallet) onlyOwner {
        require(_wallet != 0);
        wallet = _wallet;
    }

    function changeStartTime(uint _startTime) onlyOwner {
        require(_startTime != 0);
        startTime = _startTime;
    }

    function changeEndTime(uint _endTime) onlyOwner {
        require(_endTime != 0);
        endTime = _endTime;
    }

    function preSaleToggle() onlyOwner {
        preSaleIsStopped = !preSaleIsStopped;
    }

    function createTokenContract()  internal returns (MintableToken) {
        return  new VidamintToken();
    }

}
