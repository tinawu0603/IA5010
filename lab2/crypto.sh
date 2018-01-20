#!/bin/bash
# For encrypting and signing a file:
# bash crypto.sh -e <receiver public> <sender private> <plaintext> <encrypted>

# For decrypting and verifying the signature of the file:
# bash crypto.sh -d <receiver private> <sender public> <encrypted> <decrypted>

# check for valid argument
if [ $# -ne 5 ]
then
	echo Please pass in the correct arguments
	exit 1
fi
if [ $1 != -e ] && [ $1 != -d ]
then
	echo First argument must be -e or -d
	exit 1
fi

# variables for command line arguments
# decrypt or encrypt
MODE=$1
# encrypt -> public key; decrypt -> private key
R_KEY=`cat $2`
# encrypt -> private key; decrypt -> public key
S_KEY=`cat $3`
# encrypt -> plaintext file; decrypt -> encrypted file
# if file is a zip file, unzip and run this script on every file
PRESENT=$4
# encrypt -> encrypted file; decrypt -> decrypted file
RESULT=$5

# if -e encrypt or -d decrypt mode
if [ $MODE = -e ]; then
	# generating AES key
	AES_KEY=`openssl rand 16 | hexdump -e '16/1 "%02x" "\n"'`
	# generating AES initialization vector
	AES_IV=`openssl rand 16 | hexdump -e '16/1 "%02x" "\n"'`
	# generate file that has AES key and RSA encrypted hash
	touch key
	`echo $AES_KEY >> key`
	`echo $AES_IV >> key`
	touch e_key
	# encrypting plaintext using 128-bit AES in CBC mode
	`openssl aes-128-cbc -K $AES_KEY -iv $AES_IV -e -in $PRESENT -out ciphertext`
	# generate hash of the plaintext
	HASH=`openssl dgst -sha256 $PRESENT | awk {'print $2'}`
	`echo $HASH >> key`
	# generate signature file
	touch sign
	`openssl dgst -sha256 -sign $3 -out sign $PRESENT`
	# encrypt key file using public key of receiver
	`openssl rsautl -encrypt -inkey $2 -pubin -in key -out e_key`
	# outputs one encrypted zip file
	zip $RESULT e_key ciphertext sign
	# remove temp files
	rm key
	rm e_key
	rm ciphertext
	rm sign
# -d decrypt mode
else
	# unzips encrypted file
	unzip $PRESENT
	# decrypt key file using private key of receiver
	touch key
	`openssl rsautl -decrypt -inkey $2 -in e_key -out key`
	# change STDIN to 5 and key file to STDIN
	exec 5<&0
	exec < key
	# first line of key file is the AES key
	read LINE
	D_KEY=$LINE
	# second line of key file is the AES initialization vector
	read LINE
	D_IV=$LINE
	# third line of key file is the hash of the plaintext
	read LINE
	D_HASH=$LINE
	# decrypting ciphertext using 128-bit AES in CBC mode
	`openssl aes-128-cbc -K $D_KEY -iv $D_IV -d -in ciphertext -out $RESULT`
	# check hash of decrypted file and hash in the key file
	HASH=`openssl dgst -sha256 $RESULT | awk {'print $2'}`
	if [ $D_HASH != $HASH ]
	then
		echo hashes do not match
		exit 1
	fi
	SIGN_MATCH=`openssl dgst -sha256 -verify $3 -signature sign $RESULT`
	if [ "$SIGN_MATCH" != "Verified OK" ]
	then
		echo signature does not verify identity
		exit 1
	fi
	# remove temp files and restore STDIN
	exec 0<&5 5<&-
	rm e_key
	rm key
	rm sign
	rm ciphertext
	rm $PRESENT
fi
