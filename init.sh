#!/bin/sh

#check environmental variables
if [ "${DOMAIN}x" == "x" ];
then
    echo "DOMAIN not set, can't continue";
    exit 1
fi

if [ "${EMAIL}x" == "x" ];
then
    echo "EMAIL not set, can't continue";
    exit 1
fi

if [ "${BACKEND}x" == "x" ];
then
    echo "BACKEND not set, can't continue";
    exit 1
fi

if [ "${STAGING}x" == "x" ];
then
    #Production server
    SERVER=https://acme-v02.api.letsencrypt.org/directory
else
    #Staging server
    SERVER=https://acme-staging-v02.api.letsencrypt.org/directory
fi

#Run various file-related checks

#store if nginx was running in http-only mode
HTTPMODE=0

#check if we have the certificates already
echo -n "checking for existing certificates ..."
if [ ! -r "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" ];
then
    #no cert, start nginx in basic mode and attempt to get the cert

    echo " not found, requesting"

    cp /configs/nginx-http-only.conf /etc/nginx/nginx.conf
    supervisorctl start nginx 2>&1 >/dev/null

    #request the certificate
    echo "certbot certonly: start"
    echo "==============================================================================="
    certbot certonly --webroot -w /var/letsencrypt --agree-tos --keep -n --email $EMAIL -d $DOMAIN --server $SERVER --debug
    echo "==============================================================================="    
    echo "certbot certonly: done"
    HTTPMODE=1
else
    echo " found"
fi

#check if we have dhparam file
if [ ! -r /etc/letsencrypt/dhparam.pem ];
then
    openssl dhparam -out /etc/letsencrypt/dhparam.pem 2048
fi

#check if we have Let's Encrypt cert for OCSP Stapling
if [ ! -r /etc/letsencrypt/lets-encrypt-x3-cross-signed.pem ];
then
    echo -n "fetching let's encrypt certificatate: lets-encrypt-x3-cross-signed.pem ... "
    curl -s -o /etc/letsencrypt/lets-encrypt-x3-cross-signed.pem https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt
    if [ $? -eq 0 ];
    then
        echo " done"
    else
        echo -n " can't fetch, using local copy ... "
        cp /lets-encrypt-x3-cross-signed.pem /etc/letsencrypt/lets-encrypt-x3-cross-signed.pem
        echo " done"
    fi
fi

#check if we have the correct nginx full config (with the domain)
echo -n "checking if nginx configuration contains ${DOMAIN} ... "
COUNT=$(grep ${DOMAIN} /etc/nginx/nginx.conf | wc -l)
if [ $COUNT -eq 0 ];
then
    echo -n " no, updating ... "
    #determine the resolver to use
    RESOLVER=$(grep nameserver /etc/resolv.conf | cut -d' ' -f2 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")

    sed -i -E 's/@@DOMAIN@@/'${DOMAIN}'/g' /configs/nginx-http-https.conf
    sed -i -E 's/@@RESOLVER@@/'${RESOLVER}'/g' /configs/nginx-http-https.conf
    sed -i -E 's/@@BACKEND@@/'${BACKEND}'/g' /configs/nginx-http-https.conf
    echo " done"
else 
    echo " yes"
fi

echo -n "checking if nginx config is ok ... " 
CHECK_RESULT=$(nginx -t -c /configs/nginx-http-https.conf 2>&1)

if [ $? -ne 0 ];
then
    echo " no, can't continue"
    echo $CHECK_RESULT
    sleep 1
    exit 1
else 
    echo " yes"
fi

echo -n "starting nginx using production config ... "
cp /configs/nginx-http-https.conf /etc/nginx/nginx.conf
if [ $HTTPMODE -eq 1 ];
then
    supervisorctl stop nginx 2>&1 >/dev/null
fi
supervisorctl start nginx 2>&1 >/dev/null
echo " done"

#start renewer script
supervisorctl start renewer 2>&1 >/dev/null




