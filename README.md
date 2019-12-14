# TLSCertGenerator

A simple bash script to quickly generate private CA signed SSL/TLS x.509 Certitificates

-h --help | Show this help page

-d --domain | specify the domain/certname for the certificate, For eample -d test.website.local or -d elk-master-01

-pw --ca-password | The CA key password

## Optional Fields:

--domain-config-file | the full path to the domain confg file used when generating the crt. By deault this is in 
resources/config/domain_default_config.ext

--domain-cer-valid-time | The length of time in days the the generated crt is valid for.

--ca-pem-file | The full path to the CA .pem file. By default this is resources/ca/CA.pem

--ca-key-file | The full path to the CA .key file. By default this is resources/ca/private/CAPriv.pem

--country-name | The country name to use when making the certificate

--state-name | The state name to use when making the certificate

--local-name | The localisation name to use when making the certificate

--org-name | The orginisation name to use when making the certificate

--org-unit-name | The orginisation unit name to use when making the certificate

--common-name | The common name to use when making the certificate

--debug | Enable debugging output
