# Castle engine

## Introduction

Castle API is RESTful by design, which by itself should say a lot. JSON is
used as the default data interchange format for both requests (including `POST` and `PUT`)
and responses (where applicable); `Content-Type` header value will be
`application/json` in most cases.

The API is versioned; a version identifier should be prepended to resource
paths. The current version of the API is `1`, which gives us version identifier
`v1`; for example:

    GET /v1/users/123456

In case of an error, root will have a single `error` property structured as follows:

* `type` (type of the error)
* `description` (description of the problem)
* `uri` (URI to additional resources on the matter; optional)
* `data` (data associated with the error; optional)

For example:

```javascript
{
    "error": {
        "type": "NOT_FOUND",
        "description": "Resource id:1234567890 was not found"
        "data": {
            "id": "1234567890"
        }
    }
}
```

Currently the root for all API calls is `https://api.castlerevenge.com`. SSL is
mandatory for security reasons.

Castle API supports HTTP compression of both requests and responses (HTTP 200 only). To send a compressed body, specify `Content-Encoding: gzip` header. To receive compressed response, specify `Accept-Encoding: gzip` header in each request.

### Examples

##### List all users

``

###### Request

```
Accept: application/json
Accept-Charset: UTF-8
Accept-Encoding: gzip
Connection: keep-alive
User-Agent: Castle App
X-Castle-Auth: 
```

###### Response

```
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
ETag: "222396556"
Date: Mon, 14 Jan 2013 15:08:27 GMT
Transfer-Encoding: chunked
Content-Encoding: gzip

<GZIPPED DATA>
```

## Authentication

The authentication mechanism is based on OAuth 2.0, however it only supports
a small subset of the actual spec. This will change as Castle growths and more
reliable means of authentication are required.

Castle API supports two authentication/security levels:

* **application**
* **user**

App authentication requires from the client to provide a valid
(`CLIENT_ID`, `CLIENT_SECRET`) pair with each request. This security level
allows for a limited access to the API and currently supports only one
application vendor, i.e. `Castle App`; client credentials can be found in
`castle/web/api/config.coffee` (search for `Castle App`).

User-level access, through the usage of access token, enables the client to
interact with the API on behalf of a user, which ultimately grants access to
much more complex API endpoints. This mode of operation supersedes app-only mode;
access token identifies the application and it is not required to provide app
credentials once access token has been obtained.

There are two ways of obtaining OAuth access token:

* Creating a new user account
* Executing **password grant** authentication

Client credentials can be provides either in request's header:

    X-Castle-Auth: CLIENT_ID:CLIENT_SECRET

and

    X-Castle-Auth: ACCESS_TOKEN

or as a query part of a URL:

    ?client_id=CLIENT_ID&client_secret=CLIENT_SECRET

and

    ?access_token=ACCESS_TOKEN

### Creating user accounts

Castle supports three ways of creating new user accounts:
* via a unique **username**
* via a unique **email**
* a combination of the above

To create a new user account, send `POST` request to `/v1/users` with parameters
encoded in requests body as a JSON document:

```javascript
{
    "username": USERNAME,
    "password": PASSWORD
}
```

or:

```javascript
{
    "email": EMAIL,
    "password": PASSWORD
}
```

or:

```javascript
{
    "username": USERNAME,
    "email": EMAIL,
    "password": PASSWORD
}
```

The server will respond with the following `201` response:

```javascript
{
    "access_token": ACCESS_TOKEN,
    "user": {
      "id": USER_ID,
      "username": USERNAME,
      "email": EMAIL,
      "roles": ["user"],
    }
}
```

Both `email` and `username` have to be unique. Additionally, `email` is validated against RFC specification, while `username` is required to:

* Start with a letter
* Contain only alphanumerics and dots
* Contain at most one consecutive dot (e.g. '..' is not allowed)
* Be at least 3 characters long
* Be at most 32 characters long

There are not restrictions placed on the `password`; it can even be empty, if required.

### Password grant

Send POST request to `/v1/auth` with the following parameters:

* `username` or `email`
* `password`
* `grant_type` (set to `password`)

For example:

```javascript
{
    "username": USERNAME,
    "password": PASSWORD,
    "grant_type": "password"
}

or

```javascript
{
    "email": EMAIL,
    "password": PASSWORD,
    "grant_type": "password"
}

```

Response format is as follows:

```javascript
{
  "access_token": ACCESS_TOKEN,
  "user": {
    "id": ID,
    "username": USERNAME,
    "email": EMAIL,
  }
}
```

## Resources

Note: Query string parameters should be URI-encoded.

Update 07.06.2016: Moved into docs/API_methods.html (Was entirely unreadable in Readme.md file)


# Installation

## Manual deployment

Make sure that ubuntu user exists on the target system and has SSH keys set up (on AWS it is automatically done).

Also, make sure the NTP is synchronised (AWS - already done)

    sudo apt-get install -y ntp ntpdate

    sudo service ntp stop
    sudo ntpdate -s time.nist.gov
    sudo service ntp start
    sudo ntpq -p
    sudo timedatectl set-timezone UTC

### System configuration

In this instructions, we assume ubuntu user is created and everything is on AWS EC2 machine

Rise file descriptors limit to at least 100k for most of the services. To do so
add these line to the `/etc/security/limits.conf` file:

    mongodb         soft    nofile          100000
    mongodb         hard    nofile          100000

    redis           soft    nofile          100000
    redis           hard    nofile          100000

    haproxy         soft    nofile          100000
    haproxy         hard    nofile          100000

    stud            soft    nofile          100000
    stud            hard    nofile          100000

    castle      soft    nofile          100000
    castle      hard    nofile          100000

Enable PAM limits. Uncomment or add the following line to `/etc/pam.d/su`:

    session    required    pam_limits.so

When in trouble, consult [Linux Scalability Guide by Engineyard](http://www.engineyard.com/blog/2012/linux-scalability/).

### Syslog configuration 

Enable udp, add a sender, add a source, restart syslog

    sed -i '/^#.*module(load="imudp")/s/^#//' /etc/rsyslog.conf
    sed -i '/^#.*input(type="imudp" port="514")/s/^#//' /etc/rsyslog.conf
    sed -i '/type="imudp" port="514"/a $AllowedSender UDP, 127.0.0.1' /etc/rsyslog.conf
    sed -i -e 's/\*\.\*;auth,authpriv.none/\*\.\*;auth,authpriv.none;local2.none/g' /etc/rsyslog.d/50-default.conf
    systemctl restart rsyslog
    echo "Rsyslog reconfigured"

### Node LTS install

Install latest LTS version, set permissions for ubuntu user to global install npm packages the right way:

    curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
    apt-get install -y nodejs
    mkdir /home/ubuntu/.npm-global
    chown ubuntu:ubuntu /home/ubuntu/.npm-global
    echo "export PATH=~/.npm-global/bin:$PATH" >> /home/ubuntu/.profile
    sudo -Hu ubuntu npm config set prefix '~/.npm-global'
    sudo -Hu ubuntu npm install -g coffee-script eslint typescript node-gyp

### Castle API Service Description 

As Castle API is invoked as a systemd service, remember to set Environment VARIABLES right!! (Should be localhost for dev environments)

    cat << EOF > /etc/systemd/system/castle-api.service

    [Unit]
    Description=Castle Revenge API Backend
    After=network.target

    [Service]
    User=ubuntu
    Group=ubuntu
    ExecStart=/home/ubuntu/.npm-global/bin/coffee /home/ubuntu/castle-server/castle/web/api/app.coffee
    SyslogIdentifier=castle-api
    Environment=NODE_ENV=production
    Environment=CASTLE_MONGODB_HOST=X.X.X.X
    Environment=CASTLE_REDIS_HOST=X.X.X.X
    Restart=always

    [Install]
    WantedBy=multi-user.target

    EOF

## Database packages

These can (and should) be run on different server with proper rsyslog configuration as above.

### Redis install and config

Redis is installed and configured for taking all the traffic - remember this is a SECURITY CONCERN if not operated by AWS Security Groups!

    cd /tmp
    curl -O http://download.redis.io/redis-stable.tar.gz
    tar xzvf redis-stable.tar.gz
    cd redis-stable/
    make && make test && make install
    mkdir /etc/redis
    cp /tmp/redis-stable/redis.conf /etc/redis/

    sed -i -e 's/^bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf
    sed -i -e 's/^supervised no/supervised systemd/g' /etc/redis/redis.conf
    sed -i -e 's/^dir \.\//dir \/var\/lib\/redis/g' /etc/redis/redis.conf
    sed -i -e 's/^protected-mode yes/protected-mode no/g' /etc/redis/redis.conf

    cat << EOF > /etc/systemd/system/redis.service

    [Unit]
    Description=Redis In-Memory Data Store
    After=network.target

    [Service]
    User=redis
    Group=redis
    ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
    ExecStop=/usr/local/bin/redis-cli shutdown
    Restart=always

    [Install]
    WantedBy=multi-user.target

    EOF

    adduser --system --group --no-create-home redis
    mkdir /var/lib/redis
    chown redis:redis /var/lib/redis
    chmod 770 /var/lib/redis
    systemctl start redis
    systemctl enable redis

### MongoDB install and config

    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
    echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" >> /etc/apt/sources.list.d/mongodb-org-3.2.list

    apt-get update
    apt-get install -y mongodb-org
    sed -i -e 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf

    cat << EOF > /etc/systemd/system/mongodb.service

    [Unit]
    Description=High-performance, schema-free document-oriented database
    After=network.target

    [Service]
    User=mongodb
    ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf

    [Install]
    WantedBy=multi-user.target

    EOF

    systemctl start mongodb
    systemctl enable mongodb

Note: As of Ubuntu 16.04 this is no longer necessary, but for older systems you need to make sure to prevent MongoDB and Redis from starting on system boot. This can be done by removing their `init.d` scripts or, as it is in case
of MongoDB, creating override file in `/etc/init`:

    sudo sh -c "echo 'manual' > /etc/init/mongodb.override"

Default Redis configuration, located at `/etc/redis/redis.conf`, has to be adjusted:

    daemonize no

### Running Castle API

Castle API should be enabled as a systemd service:

    sudo systemctl start castle-api
    sudo systemctl status castle-api
    sudo systemctl enable castle-api

Making sure it restarts everytime.


## Maintenance mode

* Open AWS Console -> EC2 -> Load Balancers

* Go to Castle-Production-LB "Instances" tab. Click "Edit Instances"

* Uncheck Production API(s), check Maintenance server

* After few seconds, Instance Status should change to InService (may need reload)

# Testing

## Functional

The following are required to run tests:

1. Working Node.js environment (including `npm` tool)
2. [`mocha`](http://visionmedia.github.com/mocha) and [`should`](https://github.com/visionmedia/should.js) libraries (installed via `npm`)
3. Local or remote server running the core Castle stack (MongoDB, Redis, Castle API, Castle Console)

To run **functional** tests for Castle API, do the following:

1. Navigate to the root of <code>api</code> application source.
2. Set the correct `API_URL` property in `test/_config.coffee`. Should point to the host running core Castle stack.
3. Set the correct `CLIENT_ID` and `CLIENT_SECRET` in `test/_config.coffee`. Required only if the remote server uses different client credentials than those specified in the source code.
4. Type <code>mocha</code> to run all tests or specify additional parameters to customize testing procedure (see [`mocha`](http://visionmedia.github.com/mocha) docs).

## Load

Castle API comes with a basic suite of load tests that utilize `siege` to measure server performance. The following scenarios are covered:

* Client downloads a list of levels
* Client downloads a level (with data)
* Client authenticates with the API (password grant)

To run any of the given tests, first install `siege` tool and make sure that open file descriptor limits are set to at least 10000 for the user that runs the tests. Scripts are located at `castle/web/api/test-load`.

##### List levels (list-levels.sh)

Accepts the following parameters:

* Number of concurrent connection
* Number of requests per connection
* Valid access token

##### Download levels (download-levels.sh)

Accepts the following parameters:

* Number of concurrent connection
* Number of requests per connection
* Valid access token

Set the correct level URLs in `urls/download-levels`. Each line represents a level to download.

##### Sign in (sign-in.sh)

Accepts the following parameters:

* Number of concurrent connection
* Number of requests per connection

Set the correct request body in `urls/sign-in` prior to running tests.

