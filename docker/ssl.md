openssl genrsa > privkey.pem
openssl req -new -x509 -key privkey.pem > fullchain.pem