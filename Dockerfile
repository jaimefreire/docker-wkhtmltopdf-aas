FROM ubuntu:16.04
MAINTAINER Fabian Beuke <beuke@traum-ferienwohnungen.de>

WORKDIR /tmp

#RUN apt-get update && \
#    apt-get install -y --no-install-recommends npm wget fontconfig \
#    libfontconfig1 libfreetype6 libjpeg-turbo8 libx11-6 libxext6 \
#    libxrender1 xfonts-base xfonts-75dpi curl python-software-properties && \
#    wget -q http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb && \
#    dpkg -i wkhtmltox-0.12.2.1_linux-trusty-amd64.deb && \
#    rm /usr/local/bin/wkhtmltoimage && \
#    curl -sL https://deb.nodesource.com/setup_7.x | bash - && \
#    apt-get install -y nodejs

RUN apt-get update && \
	apt-get install -y --no-install-recommends npm curl wget xz-utils fontconfig libfontconfig1 libfreetype6 libjpeg-turbo8 libx11-6 libxext6 libxrender1 xfonts-base xfonts-75dpi && \
	wget -q http://download.gna.org/wkhtmltopdf/0.12/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz && \
	tar -xvf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz && \
	mv wkhtmltox/bin/* /usr/bin/ && \
	apt-get purge -y wget xz-utils && \
	apt-get autoremove -y && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/* && \
	curl -sL https://deb.nodesource.com/setup_7.x | bash - && \
	apt-get install -y nodejs

WORKDIR /

RUN npm install -g yarn coffee-script forever bootprint bootprint-openapi

# generate documentation from swagger
COPY swagger.yaml /
RUN bootprint openapi swagger.yaml documentation && \
    npm uninstall -g bootprint bootprint-openapi

# install dependencies
COPY package.json /
RUN yarn install

COPY app.coffee /

EXPOSE 5555

RUN node --version && \
    npm --version && \
    coffee --version

CMD ["npm", "start"]
