require 'minitest/autorun'
require_relative "Billcoin"


#To test the billcoin blockchain verifier the aborts in that class must
#be converted to raises.  This was the only way I was able to maintain
#the requirement of no stack traces visible to the user as well have
#testable error raising

class Billcoin_Tests < Minitest::Test
	
	#This tests that the verifier will recognize a bad timestamp in the seconds granularity
	def test_verify_timing_bad_seconds
		the_Billcoin = Billcoin.new()
		split_line = ["","","","-12345.12345"]
		assert_raises ("Bad timestamp") { the_Billcoin.verify_timing(split_line) }
	end
	
	#This tests that the verifier will recognize a bad timestamp in the nanoseconds granularity
	def test_verify_timing_bad_nanoseconds
		the_Billcoin = Billcoin.new()
		split_line = ["","","","0.-12345"]
		assert_raises ("Bad timestamp") { the_Billcoin.verify_timing(split_line) }
	end
	
	#This tests that the verifier will recognize a good timestamp
	def test_verify_timing_good
		the_Billcoin = Billcoin.new()
		split_line = ["","","","0.4561"]
		assert_equal [0, 4561], the_Billcoin.verify_timing(split_line)
	end
	
	#This tests that the verifier will recognize a bad block order
	def test_verify_count_bad
		the_Billcoin = Billcoin.new()
		split_line = ["100"]
		assert_raises ("Line order is faulty") { the_Billcoin.verify_count(split_line) }
	end

	#This tests that the verifier will recognize a correct block order
	def test_verify_count_good
		the_Billcoin = Billcoin.new()
		split_line = ["0"]
		assert_equal 1, the_Billcoin.verify_count(split_line)
	end

	#This tests that the verifier will recognize a bad log of the previous hash in the current block	
	def test_verify_hash_bad
		the_Billcoin = Billcoin.new()
		split_line = ["","1234"]
		assert_raises ("Previous hash not correct") { the_Billcoin.verify_hash(split_line) }
	end
	
	#This tests that the verifier will recognize a correct log of the previous hash in the current block	
	def test_verify_hash_good
		the_Billcoin = Billcoin.new()
		split_line = ["","0","","","1"]
		assert_equal 1, the_Billcoin.verify_hash(split_line)
	end
	
	#This tests that the verifier will recognize a bad account name has been used
	def test_check_account_name_bad
		the_Billcoin = Billcoin.new()
		transaction = ["MoreThanSix"]
		assert_raises ("Bad account name") { the_Billcoin.check_account_name(transaction) }
	end
	
	#This tests that the verifier will recognize a valid account name has been used
	def test_check_account_name_good
		the_Billcoin = Billcoin.new()
		transaction = ["=toSix", ">six"]
		assert_nil the_Billcoin.check_account_name(transaction)
	end
	
	#This tests that the verifier will accurately create a transaction withdrawal for a new account
	#and an existing account
	def test_account_withdraw_new_and_existing
		the_Billcoin = Billcoin.new()
		the_account = "bob"
		billcoins_traded = 5
		assert_equal [true, -5], the_Billcoin.account_withdraw(the_account, billcoins_traded)
		
		assert_equal [false, -10], the_Billcoin.account_withdraw(the_account, billcoins_traded)
	end
	
	#This tests that the verifier will recognize when a block has ended with a negative
	#account balance for one or more accounts
	def test_update_negative_check_negs
		the_Billcoin = Billcoin.new()
		the_Billcoin.account_withdraw("ham", 10)
		assert_raises("Invalid block") the_Billcoin.update_negative_check "ham"
	end
	
	#This tests that the verifier will recognize when a block has ended with no negative
	#account balances
	def test_update_negative_check_no_negs
		the_Billcoin = Billcoin.new()
		the_Billcoin.account_deposit("sam", 5)
		assert_nil the_Billcoin.update_negative_check "sam"
	end
	
	#This tests that the verifier will accurately create a transaction deposit for a new account
	#and an existing account
	def test_account_deposit_new_and_existing
		the_Billcoin = Billcoin.new()
		the_account = "jim"
		billcoins_traded = 20
		assert_equal [true, 20], the_Billcoin.account_deposit(the_account, billcoins_traded)
		
		assert_equal [false, 40], the_Billcoin.account_deposit(the_account, billcoins_traded)
	end
	
end

