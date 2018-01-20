# Lab 2 Cryptography Applications
The goal for this lab is to design a cryptographic scheme using the various cryptography tools from the OpenSSL library in order to provide confidentiality, integrity, and authenticity.

## Encryption
+ Encrypt plaintext w/ AES in CBC mode using 128-bit key and initialization vector
+ Hashing using SHA 256-bit
+ Sign using RSA private key of sender and SHA 256-bit
+ Encrypt key file that includes AES key, AES initialization vector, and hash using RSA public key of receiver
+ Zip signature file, key file, and ciphertext

## Decryption
+ Unzip encrypted file into signature file, key file, and ciphertext
+ Decrypt key file using private key of receiver
+ Decrypt ciphertext using AES in CBC mode with the 128-bit key and initialization vector from the key file
+ Check hash of the decrypted file with the hash from the key file
+ Verify signature file using sender's public key and SHA 256-bit

## Conclusion
I derived my scheme from the Pretty Good Privacy scheme. My cryptographic scheme best utilizes each cryptography by maximizing its best quality. AES is used to encrypt plaintext because symmetric cryptography is dramatically faster than asymmetric cryptography. However, the key is then encrypted with RSA because RSA is secure and can ensure confidentiality. The hash of the file is included for integrity. Lastly, the signature file is included for authenticity.
