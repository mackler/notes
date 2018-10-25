# build with docker build -t custom-nginx .
FROM nginx:1.15.5
RUN rm /etc/nginx/conf.d/default.conf
COPY tls.conf /etc/nginx/conf.d/tls.conf
COPY cert.pem /etc/tls/
COPY key.pem /etc/tls/
