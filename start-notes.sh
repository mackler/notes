# Shell script to start PostgreSQL and PostgREST in docker containers.
# Assumes docker-compose is installed.  Run this script as a user in the `docker` group.

# The name of the file containing the SQL commands to define & populate the database.
CONF_FILE=./notes.conf
export POSTGRES_USER=postgres
export POSTGRES_DB=notes_db
export POSTGRES_DATA=pgdata

if [ -r $CONF_FILE ]
    then . $CONF_FILE
else
    1>&2 echo "quitting because no valid configuration file found ($CONF_FILE)"
    exit 2
fi

if ! docker-compose config --quiet; then
    1>&2 echo "quitting because no valid compose file found"
    exit 1
fi

if [ ! -e pgdata ]; then
    load_data=true
else
    load_data=false
fi


docker-compose up --detach database
until docker-compose exec database pg_isready; do
    echo "Waiting for postgres"
    sleep 1;
done
if $load_data; then
    docker-compose exec -T database psql --username=${POSTGRES_USER} --dbname=${POSTGRES_DB} < $DB_DEFINITION
else
    echo "data directory already exists, skipping data load"
fi
docker-compose up --detach
