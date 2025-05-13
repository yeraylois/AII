#!/bin/sh

# WAIT FOR THE MySQL DATABASE TO BE READY
if [ "$DATABASE_ENGINE" = "mysql" ]; then
    /wait-for-it.sh db-green:3306 -t 60
fi

# WAIT FOR THE PostgreSQL DATABASE TO BE READY
if [ "$DATABASE_ENGINE" = "postgresql" ]; then
    /wait-for-it.sh db-green:5432 -t 60
fi

# APPLY THE MIGRATIONS
python manage.py migrate

python manage.py add_questions

exec "$@"
