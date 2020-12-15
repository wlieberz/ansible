# This playbook does the following:

* Ensures TLS directory is present.

* Creates key.

* Ensures key is locked down. with perms root:nginx '0440' 

* Creates csr from key.

* Requests cert form ssl-portal from csr via api. Caution: this is not idempotent, repeated calls will generate duplicate certs in the web portal.

* Writes the server-cert to the tls dir.

* Copies company internal ca root and issuing certs to dir.

* Builds the full pem chain.

* Ensures the cert is secure.


### Re-keying and creating new certificate:
This can be achieved by re-naming the cert root dir, then running the playbook. Alternately, you could just move all the old cert files elsewhere, then run the playbook.


*  Convert cer file to pem file:

`openssl x509 -inform der -in root.cer -out root.pem`
