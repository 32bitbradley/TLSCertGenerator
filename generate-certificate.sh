#!/bin/bash
#
# This script will generate a  CA signed TLS certificate for use on internal systems for SSL/TLS security
#

#Set Vars
debug="False"
domain="False"
default_domain_config_file="$(pwd)/resources/config/domain_default_config.ext"
ca_password="False"
ca_pem_file="$(pwd)/resources/ca/CA.pem"
ca_key_file="$(pwd)/resources/ca/private/CA.key"
info_country_name="GB"
info_local_name="Manchester"
info_state_name="Manchester"
info_org_name="None"
info_org_unit_name="None"
info_common_name="None"
domain_cer_valid_time="1852"
declare -a cert_common_names_array

show_usage() {

echo
echo "This script will generate a CA signed SSL/TLS certificate, for use on internal Systems."
echo "-h --help | Show this help page"
echo "-d --domain | specify the domain/certname for the certificate, For example -d test.test.local or -d elk-master-01"
echo "-an --alt-name | The common names (IPs only) to be added to the certificate, For example, the local IP and public IP to be used with this certificate. This flag can be specified multiple times."
echo "-pw --ca-password | The CA key password"
echo
echo "Optional Fields:"
echo "--domain-config-file | the full path to the default domain config file used when generating the crt. By default this is in resources/config/domain_default_config.ext. A new one will be generated for each SSL, this being used as the template."
echo "--domain-cer-valid-time | The length of time in days the generated crt is valid for."
echo "--ca-pem-file | The full path to the CA .pem file. By default, this is resources/ca/CA.pem"
echo "--ca-key-file | The full path to the CA .key file. By default this is resources/ca/private/CA.key"
echo "--country-name | The country name to use when making the certificate"
echo "--state-name | The state name to use when making the certificate"
echo "--local-name | The localisation name to use when making the certificate"
echo "--org-name | The organisation name to use when making the certificate"
echo "--org-unit-name | The organisation unit name to use when making the certificate"
echo "--debug | Enable debugging output"
echo

}


checkDepends() {
    
    if (echo "$info_country_name" | grep "\"" >> /dev/null) || (echo "$info_local_name" | grep "\"" >> /dev/null) || (echo "$info_state_name" | grep "\"" >> /dev/null) || (echo "$info_org_name" | grep "\"" >> /dev/null) || (echo "$info_org_unit_name" | grep "\"" >> /dev/null) || (echo "$info_common_name" | grep "\"" >> /dev/null); then
    
        echo
        echo "[Error] You have specified invalid attributes, Please done inclide quotes in attribites! Exiting..."
        echo
        exit 1
    
    fi
    
    if [ "$debug" = "True" ]; then
        echo
        echo "[Status] Starting depends checks..."
    fi

    if (! command -v openssl >> /dev/null); then
        echo
        echo "[Error] You don't have OpenSSL Installed. Please install OpenSSL to continue. Exiting..."
        echo
        exit 1
    
    fi
    
    if [ ! -f "$ca_pem_file" ]; then
        echo
        echo "[Error] Can't find CA.pem file at $ca_pem_file. You can specify a custom CA.pem with the --ca-pem-file flag. Exiting..."
        echo
        exit 1
    fi
    
    if [ ! -f "$ca_key_file" ]; then
        echo
        echo "[Error] Can't find CA.key file at $ca_key_file. You can specify a custom CA.pem with the --ca-key-file flag. Exiting..."
        echo
        exit 1
    fi
    
    if [ "$ca_password" = "False" ] || [ "$ca_password" = "" ]; then
        echo
        echo "[Error] No CA.key password specified. You can specify a custom CA password with the --pw/--ca-password flag. Exiting..."
        echo
        exit 1
    fi
    
    if [ "$domain" = "False" ] || [ "$domain" = "" ]; then
        echo
        echo "[Error] No domain specified. You can specify a domain password with the -d --domain flag. Exiting..."
        echo
        exit 1
    fi
    
}

generateDomainKey() {
    
export_location="$(pwd)/certs/$domain"

    
    if (! mkdir "$export_location"); then
    
        echo
        echo "[Error] Cannot create directory for new certs. Exiting"
        echo
        exit 1
    fi
    
    if [ "$debug" = "True" ]; then
        echo
        echo "[Status] Genrating Domain key for $domain"
        echo
    fi
    
    if (openssl genrsa -out "$export_location/$domain.key" 2048 >> /dev/null); then
    
        if [ "$debug" = "True" ]; then
            echo
            echo "[Status] Sucessfully Generated Domain key for $domain at $export_location/$domain.key"
            echo
        fi
        
        
    else
    
        echo
        echo "[Error] Unable to generate key for domain $domain. Exiting!"
        echo
        exit 1
    
    fi
}


generateDomainCSR() {
    
    if [ "$debug" = "True" ]; then
        echo
        echo "[Status] Genrating CSR for $domain"
        echo
    fi
    
    if [ ! -f "$export_location/$domain".key ]; then
    
        echo
        echo "[Error] Unable to find generated domain key for $domain at $export_location/$domain.key Exiting!"
        echo
        exit 1

    elif [ "$debug" = "True" ]; then
        echo
        echo "[Status] Found generated generated domain key for $domain at $export_location/$domain.key continuing with CSR..."
        echo
    fi
    
    if (openssl req -new -key "$export_location/$domain".key -out "$export_location/$domain.csr" -subj "/C=$info_country_name/ST=$info_state_name/L=$info_local_name/O=$info_org_name/OU=$info_org_unit_name/CN=$domain" >> /dev/null); then
    
        if [ "$debug" = "True" ]; then
            echo
            echo "[Status] Sucessfully Generated Domain CSR for $domain"
            echo
        fi
        
        else
    
        echo
        echo "[Error] Unable to generate CSR for domain $domain. Exiting!"
        echo
        exit 1
    
    fi
}

generateDomainCertificate() {

	if (! cp "$default_domain_config_file" "$export_location/$domain.ext"); then

		echo
		echo "[Error] Unable to create domain configuration profile. Exiting!"
		echo
		exit1
		
	elif [ "$debug" = "True" ]; then
		echo
		echo "[Status] Created domain configuration profile at $export_location/$domain.ext"
		echo
		
		counter=0
	fi
		
	if (! for i in "${cert_common_names_array[@]}"; do counter=$((counter + 1)); echo "IP.$counter = $i"; done >> "$export_location/$domain.ext"); then
	
		echo 
		echo "[Error] Unable to add common names to config file, exiting."
		echo
		exit 1
	elif [ "$debug" = "True" ]; then
		echo
		echo "[Status] CSucessfully added common names to config file at $export_location/$domain.ext"
		echo
	
    fi

    if [ ! -f "$export_location/$domain".csr ]; then
    
        echo
        echo "[Error] Unable to find domain CSR file at $export_location/$domain.key Exiting!"
        echo
        exit 1

    elif [ "$debug" = "True" ]; then
        echo
        echo "[Status] Found CSR at $export_location/$domain.csr"
        echo
    fi
    
    if [ ! -f "$export_location/$domain.ext" ]; then
    
        echo
        echo "[Error] Unable to find domain config file at $export_location/$domain.ext Exiting!"
        echo
        exit 1

    elif [ "$debug" = "True" ]; then
        echo
        echo "[Status] Found domain config file at $export_location/$domain.ext"
        echo
    fi
    
    
    if (openssl x509 -req -in "$export_location/$domain.csr" -CA "$ca_pem_file" -CAkey "$ca_key_file" -CAcreateserial -out "$export_location/$domain.crt" -days "$domain_cer_valid_time" -sha256 -extfile "$export_location/$domain.ext" -passin pass:"$ca_password" >> /dev/null); then
    
        if [ "$debug" = "True" ]; then
            echo
            echo "[Status] Sucessfully generated certificate for $domain"
            echo
        fi
        
    else
    
        echo
        echo "[Error] Unable to generate certificate for domain $domain. Exiting!"
        echo
        exit 1
        
    fi
}

getExportedFiles() {
    
    if (! chmod -R 700 "$export_location"); then
            echo
            echo "[WARN] Unable to set 700 permissions on $export_location . Please set thease manually!"
            echo
    fi
    
    
        if [ ! -f "$export_location/$domain.crt" ]; then
    
            echo
            echo "[Error] Unable to find domain config file at $export_location/$domain.crt"
            echo
            exit 1
        else
            echo
            echo "[Success] Sucessfully created new TLS Certifcate at: $export_location/$domain.crt"
            
    fi
    
    if [ ! -f "$export_location/$domain.key" ]; then
    
            echo
            echo "[Error] Unable to find domain key file at $export_location/$domain.key"
            echo
            exit 1
        else
            echo "[Success] TLS Certifcate Key can be found at: $export_location/$domain.key"
    
    fi
    
    if [ ! -f "$ca_pem_file"  ]; then
    
            echo
            echo "[Error] Unable to find CA file at $ca_pem_file"
            echo
            exit 1
        else
            echo "[Success] Don't forget the CA file at: $ca_pem_file"
            echo
    
    fi
    
}

# Get command line data
while [ "$1" != "" ]; do
    case $1 in
        -d | --domain )         shift
                                domain=$1
                                ;;
        -an | --alt-name )      shift
                                cert_common_names_array+=("$1")
                                ;;
        --domain-config-file )  shift
                                default_domain_config_file=$1
                                ;;
        --domain-crt-valid-time ) shift
                                domain_cer_valid_time=$1
                                ;;
        -pw | --ca-password )   shift
                                ca_password=$1
                                ;;
        --ca-pem-file )         shift
                                ca_pem_file=$1
                                ;;
        --ca-key-file )         shift
                                ca_key_file=$1
                                ;;
        --country-name )     shift
                                info_country_name=$1
                                ;;
        --state-name | --province-name )     shift
                                info_state_name=$1
                                ;;
        --local-name )          shift
                                info_local_name=$1
                                ;;
        --org-name )         shift
                                info_org_name=$1
                                ;;
        --org-unit-name )       shift
                                info_org_unit_name=$1
                                ;;
        --debug )               debug="True"
                                ;;
        -h | --help )           show_usage
                                exit
                                ;;
        * )                     show_usage
                                exit 1
    esac
    shift
done

checkDepends

generateDomainKey

generateDomainCSR

generateDomainCertificate

getExportedFiles

exit 0
