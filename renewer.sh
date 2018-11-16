#!/bin/sh

while [ 1 ]; 
do
    echo "certbot renew: start"
    echo "==============================================================================="
    certbot renew --renew-hook "supervisorctl restart nginx"
    echo "==============================================================================="
    echo "certbot renew: done"
    sleep 1209600
done