export SOURCE=de2scvsearch00.services.coxlab.net:9200
export DESTINATION=10.8.172.139:9200
export TV=`curl -XGET "http://de2scvsearch00.services.coxlab.net:9200/_cat/indices/tv_*?pretty"  | awk '{ print $3 }'`

curl -XDELETE http://${DESTINATION}/tv_*
curl -XGET http://de2scvsearch00.services.coxlab.net:9200/${TV} -o "${TV}_settings.json"
sed -i "s/\"$TV\":{//" "${TV}_settings.json"
sed -i -r 's/^(.*?)}$/\1/' "${TV}_settings.json"
sed -i 's/"total_shards_per_node":"1"/"total_shards_per_node":"3"/' "${TV}_settings.json"
#sed -i 's/"member":{"type":"nested"/"member":{"type":"nested","include_in_parent":true/' "${TV}_settings.json"
curl -XPUT http://${DESTINATION}/${TV} -d @"${TV}_settings.json"


~/node_modules/elasticdump/bin/elasticdump --input=http://de2scvsearch00.services.coxlab.net:9200/${TV} --output=http://${DESTINATION}/${TV} --type=data --limit=100
#elasticdump --input=${TV}_data.json  --output=http://${DESTINATION}/${TV} --type=data --limit=100

