export SOURCE=de2scvsearch00.services.coxlab.net:9200
export DESTINATION=10.8.172.139:9200
export TMSENTITIES=`curl -XGET "http://${SOURCE}/_cat/indices/tmsentities*?pretty"  | awk '{ print $3 }'`

curl -XDELETE http://${DESTINATION}/${TMSENTITIES}
curl -XGET http://${SOURCE}/${TMSENTITIES} -o "${TMSENTITIES}_settings.json"
sed -i "s/\"$TMSENTITIES\":{//" "${TMSENTITIES}_settings.json"
sed -i -r 's/^(.*?)}$/\1/' "${TMSENTITIES}_settings.json"
sed -i 's/"total_shards_per_node":"1"/"total_shards_per_node":"3"/' "${TMSENTITIES}_settings.json"
#sed -i 's/"member":{"type":"nested"/"member":{"type":"nested","include_in_parent":true/' "${TMSENTITIES}_settings.json"
curl -XPUT http://${DESTINATION}/${TMSENTITIES} -d @"${TMSENTITIES}_settings.json"


~/node_modules/elasticdump/bin/elasticdump --input=http://${SOURCE}/${TMSENTITIES} --output=http://${DESTINATION}/${TMSENTITIES} --type=data --limit=100
#elasticdump --input=${TMSENTITIES}_data.json  --output=http://${DESTINATION}/${TMSENTITIES} --type=data --limit=100

