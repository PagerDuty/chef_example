#!/bin/bash

set -e
export RUBYLIB="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

usage()
{
cat << EOF
usage: $0 options

This script assembles all the cookbook using berkshelf and then upload them, 
along with roles, databags and environments

OPTIONS:
   -h              Show this message
   -c knife.rb     Knife configuration file
   -p vendor_dir   Cookbook vendor directory
EOF
}

VENDOR="vendor"
KNIFE_CONFIG=
while getopts “hc:p:” OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    c)
      KNIFE_CONFIG=$OPTARG
      ;;
    p)
      VENDOR=$OPTARG
      ;;
  esac
done

if [ ! -z "$KNIFE_CONFIG" ]
then
  KNIFE_CONFIG=" -c ${KNIFE_CONFIG}"
fi

CWD=$(pwd)
REPO=$(dirname "${BASH_SOURCE[0]}")

cd $REPO

#cookbooks
if [ ! -d vendor ]
then
  mkdir vendor
fi

bundle exec berks install -p $VENDOR
bundle exec knife cookbook bulk delete '.' -y $KNIFE_CONFIG
bundle exec knife cookbook upload -o $VENDOR -a $KNIFE_CONFIG

#data_bags
for data_bag in $(find data_bags/ -mindepth 1 -maxdepth 1 -type d | sed -e 's/.*\/\(.*\)/\1/');
do
	bundle exec knife data bag create ${data_bag} $KNIFE_CONFIG
done

bundle exec knife data bag from file -a $KNIFE_CONFIG

#environments
bundle exec knife environment from file -a $KNIFE_CONFIG

#roles
bundle exec knife role from file roles/* $KNIFE_CONFIG

cd $CWD
