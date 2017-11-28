export SOURCE=de2scvsearch00.services.coxlab.net:9200
export DESTINATION=10.8.172.139:9200
export COXVOD=`curl -XGET "http://de2scvsearch00.services.coxlab.net:9200/_cat/indices/coxvod_*?pretty"  | awk '{ print $3 }'`

curl -XDELETE http://${DESTINATION}/coxvod_*
curl -XGET http://de2scvsearch00.services.coxlab.net:9200/${COXVOD} -o "${COXVOD}_settings.json"
sed -i "s/\"$COXVOD\":{//" "${COXVOD}_settings.json"
sed -i -r 's/^(.*?)}$/\1/' "${COXVOD}_settings.json"
sed -i 's/"total_shards_per_node":"1"/"total_shards_per_node":"3"/' "${COXVOD}_settings.json"
curl -XPUT http://${DESTINATION}/${COXVOD} -d @"${COXVOD}_settings.json"

~/node_modules/elasticdump/bin/elasticdump --input=http://de2scvsearch00.services.coxlab.net:9200/${COXVOD}/assets --output=${COXVOD}_assets_data.json --type=data --limit=100
~/node_modules/elasticdump/bin/elasticdump --input=${COXVOD}_assets_data.json  --output=http://${DESTINATION}/${COXVOD} --type=data --limit=100

