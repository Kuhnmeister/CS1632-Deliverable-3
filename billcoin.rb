class Billcoin
	
	#necessary global variables for comparisons between current and previous block
	$line_count = 0
	$prev_hash = 0
	$prev_time = [0, 0]
	$accounts = Hash.new()
	$billcoin_balance = 0
	$negative_balances = 0
	$balance_is_neg = Hash.new()

	#Initializes the verification process for a block
	def begin_verify line
		split_line = line.split("|")
		verify_line split_line
		split_line
	end

	#Calls the individual methods for block verification
	def verify_line split_line
		verify_count split_line
		verify_timing split_line
		verify_hash split_line
	end

	#Verifies that the timing of the blocks is in order
	def verify_timing split_line
		time = split_line[3].split(".")
		time[0] = time[0].to_i
		time[1] = time[1].to_i
		if($prev_time[0] > time[0])
			abort("Bad timestamp")
		elsif($prev_time[0] == time[0])
			if($prev_time[1] > time[1])
				abort("Bad timestamp")
			end
		end
		$prev_time = time
	end

	#Verifies the order of blocks is maintained
	def verify_count split_line
		if (split_line[0].to_i != $line_count)
			abort("Line order is faulty")
		end
		$line_count += 1
	end

	#Verifies the hash in this block matches the hash in the previous block
	def verify_hash split_line
		if $prev_hash != split_line[1].to_i(16)
			abort("Previous hash not correct")
		else
			$prev_hash = split_line[4].gsub("\n","").to_i(16)
		end
	end

	#Separates the individual transactions in the given block
	def split_transactions split_line
		transactions = split_line[2].split(":")
		transactions
	end

	#Separates the two traders in the transaction then moves on to next step in
	#transaction processing
	def split_traders transactions
		transactions.each do |traders|
			traders = traders.split(">")
			separate_trader_billcoin traders
		end
	end

	#Separates the transaction portions and then calls update account methods
	def separate_trader_billcoin traders
		trader1 = traders[0]
		transaction_half = traders[1].split("(")
		trader2 = transaction_half[0]
		num_billcoins = transaction_half[1].split(")")
		transaction = [trader1, trader2, num_billcoins[0].to_i]
		check_account_name transaction
		update_sender transaction
		update_receiver transaction
	end

	#Ensures no account name violates the requirements otherwise program is aborted
	def check_account_name transaction
		if(transaction[0].length > 6)
			abort("Bad account name")
		elsif(transaction[1].length > 6)
			abort("Bad account name")
		end
	end
	
	#Intermediary that calls the withdraw methods and the check for negative balances
	def update_sender transaction
		billcoins_traded = transaction[2]
		if(transaction[0] != "SYSTEM")
			account_withdraw(transaction[0], billcoins_traded)
			update_negative_check transaction[0]
		end
	end
	
	#Intermediary that calls the deposit methods and the check for negative balances
	def update_receiver transaction
		billcoins_traded = transaction[2]
		account_deposit(transaction[1], billcoins_traded)
		update_negative_check transaction[1]
	end
		
	#Creates an account if necessary and subtracts the traded amount
	#from the account balance
	#Returns true and false as well as account balance to signify 
	#different operations occurred for testing verification purposes.
	def account_withdraw the_account, billcoins_traded
		if($accounts[the_account].nil?)
			$accounts[the_account] = -billcoins_traded
			[true, $accounts[the_account]]
		else
			$accounts[the_account] -= billcoins_traded
			[false, $accounts[the_account]]
		end
	end

	#Updates the negative transaction counter to ensure
	#the end of the block contains no negative balances
	def update_negative_check the_account
		if($accounts[the_account] < 0)
			$balance_is_neg[the_account] = true
			$negative_balances += 1
		elsif($balance_is_neg[the_account])
			$negative_balances -= 1
			$balance_is_neg[the_account] = false
		end	
	end

	#Creates an account if necessary and adds the traded amount
	#from the account balance
	#Returns true and false as well as account balance to signify 
	#different operations occurred for testing verification purposes.
	def account_deposit the_account, billcoins_traded
		if($accounts[the_account].nil?)
			$accounts[the_account] = billcoins_traded
			[true, $accounts[the_account]]
		else
			$accounts[the_account] += billcoins_traded
			[false, $accounts[the_account]]
		end
	end

	#Checks the calculated hash value to ensure it matches the value
	#in the block
	#ends the program if the block was seen to have a bad hash
	def check_hash split_line
		hash_val = 0
		character_values = "#{split_line[0]}|#{split_line[1]}|#{split_line[2]}|#{split_line[3]}".unpack('U*')
		threads = Array.new()
		character_values.each do |character|
			hash_val += (character ** 2000) * ((character + 2) ** 21) - ((character + 5) ** 3)
		end
		hash_val = hash_val%65536
		if(hash_val.to_s(16) != split_line[-1].gsub("\n",""))
			abort("Bad hash")
		end
	end

	#Initializes the file read and calls all the necessary methods
	#to verify and process a block in the blockchain
	#Ends the program if there's no file by the name passed in
	#in an attempt to speed up this program the hashing was done
	#in a thread but some better organization could have been done
	#earlier because the joining of the threads essentially negates
	#the speed advantages of threading
	def start blockchain
		if(File.file?(blockchain))
			threads = Array.new()
			File.readlines(blockchain).each do |line|
				split_line = begin_verify line
				threads.push(Thread.new{check_hash split_line})
				transactions = split_transactions split_line
				split_traders transactions
				if($negative_balances > 0)
					abort("Invalid block")
				end
			end
			threads.each do |thread|
				thread.join()
			end
			$accounts.each do |account, billcoins|
				puts "#{account}: #{billcoins} billcoins"
			end
		else
			abort("No such file exists")
		end
	end
end