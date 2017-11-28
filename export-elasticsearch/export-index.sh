#!/bin/sh
MY_HOME=/home/vendors/kpatil
PATH=$PATH:/usr/local/nodejs/bin
SCRIPT_PATH=`dirname $(readlink -f $0)`
echo "Working directory to: $SCRIPT_PATH"
NODEJS_SCRIPT=${MY_HOME}/node_modules/elasticdump/bin/elasticdump
SOURCE=de2scvsearch00.services.coxlab.net:9200
DESTINATION=10.8.172.139:9200

if ! [ -x "$NODEJS_SCRIPT" ]; then
	echo "elasticdump NodeJS script to export/import data not found. Please install and try again"
	exit
fi

if [ "$1" == "" ]; then
	echo "Script requires Elasticsearch index name as command line parameter"
	exit
fi

SOURCE_INDEX=`curl -s -XGET "http://${SOURCE}/_cat/indices/${1}*?pretty"  | awk '{ print $3 }' `
SOURCE_INDEX=`echo $SOURCE_INDEX | sed -r "s/^(\w\S*)\s+.*$/\1/" `

DEST_INDEX=`curl -s -XGET "http://${DESTINATION}/_cat/indices/${1}*?pretty"  | awk '{ print $3 }' `
DEST_INDEX=`echo $DEST_INDEX | sed -r "s/^(\w\S*)\s+.*$/\1/" `

if [ "${SOURCE_INDEX}" == "" ]; then
	echo "No such index '${1}' exists on the source Elasticsearch server"
	exit
fi

echo .
echo "Please confirm we importing following index from source: \"${SOURCE_INDEX}\""
echo "and deleting following index from destination: \"${DEST_INDEX}\""
if [ "$2" == "y" ]
then
	echo "Found import confirmation on command line"
else
	echo "Do you want to continue with import (y/Y)?"
	read CONFIRM

	if ! [[ $CONFIRM == "y" || $CONFIRM == "Y" ]] 
	then
		echo "Aborting the import process ... "
		exit
	fi
fi

MAPPING_FILE=${SCRIPT_PATH}/${SOURCE_INDEX}_settings.json
echo "Getting index mappings from source in ${MAPPING_FILE}"
curl -XGET "http://${SOURCE}/${SOURCE_INDEX}" -o "${MAPPING_FILE}"
sed -i "s/\"$SOURCE_INDEX\":{//" "${MAPPING_FILE}"
sed -i -r 's/^(.*?)}$/\1/' "${MAPPING_FILE}"
sed -i 's/"total_shards_per_node":"1"/"total_shards_per_node":"3"/' "${MAPPING_FILE}"

echo "Deleting all existing index ${DEST_INDEX} from destination"
curl -XDELETE "http://${DESTINATION}/${DEST_INDEX}*"

echo "Creating new mapping on destination for index: ${SOURCE_INDEX}"
curl -XPUT "http://${DESTINATION}/${SOURCE_INDEX}" -d @"${MAPPING_FILE}"

${NODEJS_SCRIPT} --input=http://${SOURCE}/${SOURCE_INDEX} --output=http://${DESTINATION}/${SOURCE_INDEX} --type=data --limit=100
