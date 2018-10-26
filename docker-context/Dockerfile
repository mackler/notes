# build with docker build -t custom-nginx .
FROM nginx:1.15.5
RUN rm /etc/nginx/conf.d/default.conf
COPY tls.conf /etc/nginx/conf.d/tls.conf
