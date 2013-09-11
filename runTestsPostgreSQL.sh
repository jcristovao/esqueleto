#!/bin/bash
# This script configures Esqueleto for PostgreSQL support,
# enables and runs tests accordingly
host="localhost"
port=5432
testdb="esqueleto-test"
user=`whoami`

# Auxiliary functions
function error {
	echo $1
	exit 1
}

# Help menu
if [ "$1" == "--help" -o "$1" == "-?" ]; then
	echo "PostgreSQL Esqueleto testsuite:"
	echo ""
	echo -e "\trunTestPostgreSQL [username]"
	echo ""
	echo "Creates a esqueleto-test database"
	echo ""
	exit 0
fi

# Check for PostgreSQL presence
psql --version > /dev/null  \
	|| error "No PostgreSQL psql command found, is PostgreSQL installed?"

createdb --version > /dev/null  \
	|| error "No PostgreSQL psql command found, is PostgreSQL installed?"

# Check optional username
if [ "$1" != "" ]; then
	user=$1
fi

# Create database, if necessary
psql -c "drop schema public cascade; create schema public;" \
	 -h ${host} -p ${port} ${testdb} ${user} 2&>1 /dev/null

if [ $? != 0 ]; then
	createdb -O ${user} ${testdb}
fi

if [ $? != 0 ]; then
	error "Failed to create database. Perhaps insuficient permissions or wrong user?"
fi

# From now on, stop on errors
set -e

# Configure with tests
cabal configure --enable-tests

# Patch test file
sed -i "s/withSqliteConn \":memory:\" ./withPostgresqlConn \"host=${host} port=${port} user=${user} dbname=${testdb}\" ./" test/Test.hs

# Build
cabal build

# Run tests
#cabal test
# I prefer the color output from the test itself
./dist/build/test/test

# Clean up
dropdb -O ${user} ${testdb}




