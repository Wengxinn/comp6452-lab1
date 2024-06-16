// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.8.00 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/LunchVenue_updated.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
/// Inherit 'LunchVenue_updated' contract
contract LunchVenue_updatedTest is LunchVenue_updated(100) {
    
    // Variables used to emulate different accounts  
    address acc0;   
    address acc1;
    address acc2;
    address acc3;
    address acc4;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // Initiate account variables
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
    }

    /// Check manager
    /// account-0 is the default account that deploy contract, so it should be the manager (i.e., acc0)
    function testManager() public {
        Assert.equal(manager, acc0, 'Manager should be acc0');
    }

    /// Check timeout block number
    function testTimeoutBlockNumber() public {
        Assert.greaterThan(timeoutBlockNumber, block.number, 'Timeout block number should be set');
    }

    /// Set timeout duration block as manager
    /// When msg.sender isn't specified, default account (i.e., account-0) is the sender
    function testsetTimeoutDuration() public {
        Assert.equal(setTimeoutDuration(100), true, 'Should be equal to true');
    }

    /// Try to set timeout duration as a user other than manager. This should fail
    /// this represents contract address which is not manager's address
    function testSetTimeoutDurationFailure() public {
        // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try this.setTimeoutDuration(100) returns (bool status) {
            Assert.notEqual(status, true, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } catch Panic(uint /* errorCode */) { // In case of a panic
            Assert.ok(false, 'Failed unexpected with error code');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpected');
        }
    }
    
    /// Add restaurants as manager
    /// When msg.sender isn't specified, default account (i.e., account-0) is the sender
    function testAddRestaurant() public {
        Assert.equal(addRestaurant('Courtyard Cafe'), 1, 'Should be equal to 1');
        Assert.equal(addRestaurant('Uni Cafe'), 2, 'Should be equal to 2');
    }
    
    /// Try to add a restaurant as a user other than manager. This should fail
    /// this represents contract address which is not manager's address
    function testAddRestaurantFailure() public {
        // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try this.addRestaurant('Atomic Cafe') returns (uint v) {
            Assert.notEqual(v, 3, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } catch Panic(uint /* errorCode */) { // In case of a panic
            Assert.ok(false, 'Failed unexpected with error code');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpected');
        }
    }
    
    /// Add friends as manager
    /// #sender doesn't need to be specified explicitly for account-0
    function testAddFriend() public {
       Assert.equal(addFriend(acc0, 'Alice'), 1, 'Should be equal to 1');
       Assert.equal(addFriend(acc1, 'Bob'), 2, 'Should be equal to 2');
       Assert.equal(addFriend(acc2, 'Charlie'), 3, 'Should be equal to 3');
       Assert.equal(addFriend(acc3, 'Eve'), 4, 'Should be equal to 4');
    }
    
    /// Try adding friend as a user other than manager. This should fail
    function testAddFriendFailure() public {
        try this.addFriend(acc4, 'Daniels') returns (uint f) {
            Assert.notEqual(f, 5, 'Method execution did not fail');
        } catch Error(string memory reason) { // In case revert() called
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } catch Panic( uint /* errorCode */) { // In case of a panic
            Assert.ok(false , 'Failed unexpected with error code');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpected');
        }
    }

    /// Try to enable voting as a user other than manager. This should fail
    function testEnableVotingFailure() public {
        try this.enableVoting() {
            Assert.notEqual(voteOpen, false, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } catch Panic( uint /* errorCode */) { // In case of a panic
            Assert.ok(false , 'Failed unexpected with error code');        
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpectedly');
        }
    }

    /// Enable voting as manager
    /// When msg.sender isn't specified, default account (i.e., account-0) is the sender
    function testEnableVoting() public {
        Assert.equal(voteOpen, false, 'Voting should initially be closed');
        enableVoting();
        Assert.equal(voteOpen, true, 'Voting should be open');
    }
    
    /// Vote as Bob (acc1)
    /// #sender: account-1
    function testDoVote() public {
        Assert.ok(doVote(2), 'Voting result should be true');
    }

    /// Try voting as a user not in the friends list. This should fail
    function testDoVoteAsUnexistedFriendFailure() public {
        try this.doVote(1) returns (bool validVote) {
            Assert.notEqual(validVote, true, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Friend does not exist', 'Failed with unexpected reason');
        } catch Panic( uint /* errorCode */) { // In case of a panic
            Assert.ok(false , 'Failed unexpected with error code');        
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpectedly');
        }
    }

    /// Vote as Charlie
    /// #sender: account-2
    function testDoVote2() public {
        Assert.ok(doVote(1), 'Voting result should be true');
    }

    /// Vote as Eve
    /// #sender: account-3
    function testDoVote3() public {
        Assert.ok(doVote(2), 'Voting result should be true');
    }

    /// Verify lunch venue is set correctly after quorum met
    function testVotedRestaurant() public {
        Assert.equal(votedRestaurant, 'Uni Cafe', 'Selected restaurant should be Uni Cafe');
    }
    
    /// Verify voting is closed after quorum met
    function testVoteOpenAfterVotingClosed() public {
        Assert.equal(voteOpen, false, 'Voting should be closed');
    }
    
    /// Verify voting after vote closed. This should fail
    function testDoVoteAfterVotingClosedFailure() public {
        try this.doVote(1) returns (bool validVote) {
            Assert.notEqual(validVote, true, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Can vote only while voting is open', 'Failed with unexpected reason');
        } catch Panic( uint /* errorCode */) { // In case of a panic
            Assert.ok(false , 'Failed unexpected with error code');        
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpectedly');
        }
    }

    /// Try to disable contract as a user other than manager. This should fail
    function testDisableContractFailure() public {
        // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try this.disableContract() {
            Assert.notEqual(isActive, false, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } catch Panic(uint /* errorCode */) { // In case of a panic
            Assert.ok(false, 'Failed unexpected with error code');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpected');
        }
    }

    /// Disable contract as manager
    /// When msg.sender isn't specified, default account (i.e., account-0) is the sender
    function testDisableContract() public {
        Assert.equal(isActive, true, 'Should be equal to 1');
        disableContract();
        Assert.equal(isActive, false, 'Should be equal to 1');
    }
}

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
/// Inherit 'LunchVenue_updated' contract
// This contract acts as the manager
contract LunchVenue_updatedTest2 {

    LunchVenue_updated lv;
    
    // Variables used to emulate different accounts  
    address acc0;   
    address acc1;
    address acc2;
    address acc3;
    address acc4;

    // Variables used emulate different restaurants
    uint resta1;
    uint resta2;

    // Variables used emulate different friends
    uint friend1;
    uint friend2;
    uint friend3;
    uint friend4;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // Initialise instance for testing
        lv = new LunchVenue_updated(100);

        // Initiate account variables
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);

        // Initialise restaurant variables
        resta1 = lv.addRestaurant('Courtyard Cafe');
        resta2 = lv.addRestaurant('Uni Cafe');

        // Initialise friends variables
        friend1 = lv.addFriend(lv.getManager(), 'aaaa');
        friend2 = lv.addFriend(acc0, 'bbbb');
        friend3 = lv.addFriend(acc1, 'cccc');
        friend4 = lv.addFriend(acc2, 'dddd');
    }

    /// Try to add an existed restaurant. This should fail
    function testAddExistedRestaurantFailure() public {
        // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try lv.addRestaurant('Courtyard Cafe') returns (uint v) {
            Assert.notEqual(v, 3, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Restaurant already exists', 'Failed with unexpected reason');
        }
    }

    /// Try to add an existed friend. This should fail
    function testAddExistedFriendFailure() public {
        // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try lv.addFriend(acc0, 'aaaa') returns (uint f) {
            Assert.notEqual(f, 5, 'Method execution did not fail');
        } catch Error(string memory reason) { // In case revert() called
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Friend already exists', 'Failed with unexpected reason');
        }
    }

    /// Try to add a restaurant after voting open. This should fail
    function testAddRestaurantAfterVotingOpenFailure() public {
        // Enable voting
        lv.enableVoting();

        // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try lv.addRestaurant('Plume Cafe') returns (uint v) {
            Assert.notEqual(v, 3, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Can add friends or restaurants only when voting is disabled', 'Failed with unexpected reason');
        }
    }
    

    /// Try adding a friend after voting open. This should fail
    function testAddFriendAfterVotingOpenFailure() public {
        // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try lv.addFriend(acc3, 'eeee') returns (uint f) {
            Assert.notEqual(f, 5, 'Method execution did not fail');
        } catch Error(string memory reason) { // In case revert() called
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Can add friends or restaurants only when voting is disabled', 'Failed with unexpected reason');
        }
    }

    /// Try voting a restaurant not in the restaurants list. This should fail
    function testDoVoteUnexistedRestaurantFailure() public {
        // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try lv.doVote(3) returns (bool validVote) {
            Assert.notEqual(validVote, true, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Restaurant voted does not exist', 'Failed with unexpected reason');
        }
    }

    /// Try voting after voted. This should fail
    function testDoVoteAfterVotedFailure() public {
        // Do valid vote
        lv.doVote(1);

    // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try lv.doVote(1) returns (bool validVote) {
            Assert.notEqual(validVote, true, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Friend has voted already', 'Failed with unexpected reason');
        }
    }

    /// Verify voting is closed after timeout reached
    function testVoteOpenAfterTimeoutReached() public {
        // Set timeout to now
        lv.setTimeoutDuration(0);

        Assert.equal(lv.getVoteOpen(), false, 'Voting should be closed');
    }

    /// Try to add a restaurant after timeout reached. This should fail
    function testAddRestaurantAfterTimeoutReached() public {
        // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try lv.addRestaurant('Plume Cafe') returns (uint v) {
            Assert.notEqual(v, 3, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Timeout reached', 'Failed with unexpected reason');
        }
    }

    /// Try adding a friend after timeout reached. This should fail
    function testAddFriendAfterTimeoutReached() public {
        // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try lv.addFriend(acc3, 'eeee') returns (uint f) {
            Assert.notEqual(f, 5, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Timeout reached', 'Failed with unexpected reason');
        }
    }

    /// Try to add a restaurant after contract disabled. This should fail
    function testAddRestaurantAfterContractDisable() public {
        // Set timeout
        lv.setTimeoutDuration(100);

        // Disable contract
        lv.disableContract();

        // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try lv.addRestaurant('Plume Cafe') returns (uint v) {
            Assert.notEqual(v, 3, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Only when contract is active', 'Failed with unexpected reason');
        }
    }

    /// Try adding a friend after contract disabled. This should fail
    function testAddFriendAfterContractDisable() public {
        // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try lv.addFriend(acc3, 'eeee') returns (uint f) {
            Assert.notEqual(f, 5, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Only when contract is active', 'Failed with unexpected reason');
        }
    }

    /// Try to enable voting after contract disabled. This should fail
    function testEnableVotingAfterContractDisable() public {
        // Try to catch reason for failure using try-catch . When using
        // try-catch we need 'this' keyword to make function call external
        try lv.enableVoting() {
            Assert.notEqual(lv.getVoteOpen(), true, 'Method execution did not fail');
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Only when contract is active', 'Failed with unexpected reason');
        }
    }
}