# Notes

**A demonstration of Secure PostgREST with Social Authentication**

This sets up a simple PostgREST application that uses Nginx for HTTPS encryption and [Auth0](https://auth0.com/)
for authentication from 3rd party credential providers such as Google and Facebook.

## Quickstart

1. `clone` the git repository
2. run `build-docker.sh` script to configure Nginx
3. Put TLS certifictate and key into `tls/`
4. Put Auth0 credentials into `notes.conf`
5. (_optional_) update `notes.conf` to refer to custom database definition file
5. run `start-notes.sh`

**Detailed start-to-finish instructions follow.**

## Install Docker

These instructions are for Debian Stretch.  We will install Docker Community Edition (CE) from the repository.

See <https://docs.docker.com/install/linux/docker-ce/debian/#install-using-the-repository>

#### Update the apt package index:

    sudo apt-get update

#### Install packages to allow apt to use a repository over HTTPS:

    sudo apt-get install \
      apt-transport-https ca-certificates curl gnupg2 software-properties-common

#### Add Docker’s official GPG key:

    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

#### Verify the key fingerprint

Search for the last 8 characters of the fingerprint:

    sudo apt-key fingerprint <last-8-characters>

#### Set up the stable repository. 

    sudo add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

#### Update the apt package index again

    sudo apt-get update

#### Install the latest version of Docker CE

    sudo apt-get install docker-ce

#### Verify that Docker CE is installed correctly

Run the `hello-world` image:

    sudo docker run hello-world

## Install Docker-Compose

### Check the version of the installed docker engine:

    sudo docker version

Go to https://github.com/docker/compose/releases and find the latest release.  Here it was version 1.22.0.

### Download and Install

    COMPOSE_EXECUTABLE=/usr/local/bin/docker-compose
    sudo curl --location "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" \
        --output $COMPOSE_EXECUTABLE
    sudo chmod +x $COMPOSE_EXECUTABLE

### Test the installed `docker-compose`

    docker-compose --version

### Build the custom NginX docker image:

    docker build -t custom-nginx -f Dockerfile docker-context

There is a script here named `build-docker.sh` that does the same thing.  Either way, be in the `docker` group
when doing this.

## Install a TLS(SSL) certificate

Here we generate a self-signed certificate:

    mkdir tls
    openssl req -x509 -newkey rsa:4096 -keyout tls/key.pem -out tls/cert.pem -days 365 -nodes

If you already have a certificate, make sure the filenames correspond to the configuration parameters in
`docker-context/tls.conf`

## Configure Auth0

See <https://auth0.com/docs/architecture-scenarios/mobile-api/part-2>

### Create the Auth0 Application

Applications > Create Application > Single Page Application

In the section for _Allowed Callback URLs_ provide the URL of the JavaScript
application we will create below `http://localhost:3000`.

Under Advanced Settings > Application Metadata add a Key `role` whose value is
the database role that PostgREST will use.  Here, we set Value to `notes_user`.

Alse in Advanced Settings, under _OAuth_ you can choose the _JsonWebToken Signature Algorithm_.
The options are `RS256` and `HS256`.  Here we will use `RS256` but you can use `HS256` if you want.
If you use `HS256` then you will copy the _Client Secret_ from the Auth0 website into the `notes.conf`
file. If you use `RS256` then you will download the Auth0 RSA public key.  The format of the provided
RSA key contains certains members that _PostgREST_ cannot read, so you must remove those.  Use the accompanying
script and name the file `auth0_rsa.pub`:

    ./auth0-pubkey.sh <auth0-subdomain> > auth0_rsa.pub

### Define a Rule to include the role in the JWT

    function (user, context, callback) {
      context.clientMetadata = context.clientMetadata || {};
      context.idToken["http://postgrest/role"] = context.clientMetadata.role;
      callback(null, user, context);
    }

### Copy the Signing Secret into PostgREST

Rename the `notes.conf.example` file to `notes.conf` and set the Auth0 application parameters:

    export JWT_APP_ID=<Client Id>

Only if you are using `HS256` signature algorithm you must also place the Auth0 application
client secret in this file.  Name it `JWT_SECRET`.

    export JWT_SECRET=<Client Secret>

## Create a Javascript App to generate tokens

Clone the login example application from Github:

    git clone https://github.com/auth0-samples/auth0-javascript-samples.git
    cd auth0-javascript-samples/01-Login

Rename the file `auth0-variables.js.example` to `auth0-variables.js` and edit it to include
your Auth0 application Client ID and domain.  The application Client ID must match the one
used in the previous step.  These values are JavaScript strings, so enclose them in quotes.

Then edit the `app.js` file and change one line in the `new auth0.WebAuth()` from

    scope: 'openid',

to

    scope: 'openid profile',

This will include end-user identification such as name and email in the JWT.

Finally install the dependencies for the JavaScript application.

    npm install

## Start the PostgREST services

    sh start-notes.sh

## Start the Javascript Client Application

    npm start

Point a browser to <http://localhost:3000>, log in and look for the `id_token` JWT in the browser local storage.
In Chromium you find this in the DevTools unter the _Application_ tab.

You can examine this JWT easily at <https://jwt.io/>.

If everything worked then you can now use this JWT to make an
authenticated request to PostgREST.  Here, we set the value a shell
variable named `TOKEN` to the JWT. and use the `--insecure` option to
tell `curl` to accept our self-signed certificate.

    curl --insecure https://localhost:14500/todos -H "Authorization: Bearer $TOKEN"

## Installing Your Own Database Definition

The database definition file will only be loaded if there is no `pgdata` directory. Each time you change this
file and want to reload it, you must move or delete the `pgdata` directory before running the
`start-notes.sh` script.  Otherwise it will start PostgREST using the existing database.

## Connecting to the Database

You can connect directly to the database interactively:

    docker exec -it notes_database_1 psql -U postgres notes_db
