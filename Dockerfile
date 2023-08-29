FROM ubuntu:latest
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y poppler-utils imagemagick coreutils git python3 make file nano

RUN sed -i 's#<policy domain="coder" rights="none" pattern="PS" />##' /etc/ImageMagick-6/policy.xml && \
    sed -i 's#<policy domain="coder" rights="none" pattern="PS2" />##' /etc/ImageMagick-6/policy.xml && \
    sed -i 's#<policy domain="coder" rights="none" pattern="PS3" />##' /etc/ImageMagick-6/policy.xml && \
    sed -i 's#<policy domain="coder" rights="none" pattern="EPS" />##' /etc/ImageMagick-6/policy.xml && \
    sed -i 's#<policy domain="coder" rights="none" pattern="PDF" />##' /etc/ImageMagick-6/policy.xml && \
    sed -i 's#<policy domain="coder" rights="none" pattern="XPS" />##' /etc/ImageMagick-6/policy.xml

RUN echo "<policy domain=\"coder\" rights=\"read \| write\" pattern=\"PDF\" />" >> /etc/ImageMagick-6/policy.xml

COPY . /app
