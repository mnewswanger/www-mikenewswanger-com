#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"
hugo --source ${DIR} --cleanDestinationDir \
 && time rsync -rv --delete ${DIR}/public/ root@www.mikenewswanger.com:/var/www/www.mikenewswanger.com/html

