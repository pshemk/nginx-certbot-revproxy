FROM alpine

COPY ./*.sh /
COPY ./*.py /
COPY ./configs/nginx* /configs/
COPY ./configs/supervisord.conf /etc/supervisord.conf

RUN apk add nginx certbot curl openssl supervisor && \
    chmod +x /*.sh /*.py && \
    mkdir -p /var/run/nginx/ && \
    mkdir -p /var/letsencrypt

ADD https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt /lets-encrypt-x3-cross-signed.pem

EXPOSE 80
EXPOSE 443

CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]

