# GeoQuery module

## Usage 

Import the module using typical CommonJS style.
Set the options serialized parameters object:

* ip - ip to be resolved (REQUIRED)
* timeout - timeout in ms (OPTIONAL) 
* serviceHost = ip of Telize geolocation server (OPTIONAL)
* servicePort = port of Telize geolocation server (OPTIONAL)
* servicePath = default set to 'location'

Example:

    var geoquery = require('./geoquery');

    geoquery.geoquery({ip: '46.19.37.108'}, function(err, data) {
        console.log(JSON.stringify(data));
    });

## Telize server installation

### Linux setup

    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get install build-essential

### Nginx setup

    ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.42.tar.gz
    tar -zxf pcre-8.42.tar.gz
    cd pcre-8.42/
    ./configure
    make
    sudo make install
    cd ..
    wget http://zlib.net/zlib-1.2.11.tar.gz
    tar -zxf zlib-1.2.11.tar.gz
    cd zlib-1.2.11/
    ./configure
    make
    sudo make install
    cd ..
    wget http://www.openssl.org/source/openssl-1.0.2o.tar.gz
    tar -zxf openssl-1.0.2o.tar.gz
    cd openssl-1.0.2o/
    ./Configure linux-x86_64 --prefix=/usr
    make
    sudo make install
    cd ..
    wget https://nginx.org/download/nginx-1.13.12.tar.gz
    tar zxf nginx-1.13.12.tar.gz
    wget http://luajit.org/download/LuaJIT-2.0.5.tar.gz
    tar zxf LuaJIT-2.0.5.tar.gz
    cd LuaJIT-2.0.5/
    make
    sudo make install
    cd ..
    wget https://github.com/simplresty/ngx_devel_kit/archive/v0.3.0.tar.gz
    mv v0.3.0.tar.gz ngx_devel_kit-v0.3.0.tar.gz
    wget https://github.com/openresty/lua-nginx-module/archive/v0.10.12.tar.gz
    mv v0.10.12.tar.gz lua-nginx-module-v0.10.12.tar.gz
    tar zxf lua-nginx-module-v0.10.12.tar.gz
    tar zxf ngx_devel_kit-v0.3.0.tar.gz
    export LUAJIT_LIB=/usr/local/lib/
    export LUAJIT_INC=/usr/local/include/luajit-2.0
    sudo add-apt-repository ppa:maxmind/ppa
    sudo apt update
    sudo apt install libmaxminddb0 libmaxminddb-dev mmdb-bin
    git clone https://github.com/leev/ngx_http_geoip2_module.git

    cd nginx-1.13.12/
    ./configure --with-ld-opt="-Wl,-rpath,/usr/local/lib" --with-pcre=../pcre-8.42 --with-zlib=../zlib-1.2.11 --with-http_ssl_module --with-http_realip_module --add-module=../ngx_devel_kit-0.3.0 --add-module=../lua-nginx-module-0.10.12 --add-module=../ngx_http_geoip2_module

### Telize setup

Basically follow the instructions on https://github.com/fcambus/telize

    git clone https://github.com/fcambus/telize.git

Copy telize and database conf into /etc/local/nignx.
Modify /usr/local/nginx/conf/nignx.conf:

    include /etc/nginx/country-code3.conf;
    include /etc/nginx/timezone-offset.conf;
    include /etc/nginx/telize.conf;



