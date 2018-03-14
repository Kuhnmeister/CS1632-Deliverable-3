require_relative("Billcoin")

class Verifier

end

if(!ARGV.empty?)
	verifier = Billcoin::new
	verifier.start ARGV[0]
else
	raise("No file specified")
end