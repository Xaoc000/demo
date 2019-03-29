#!/usr/bin/env sh

export NODE_ENV=development

CONTROLLER_HOST="http://localhost:51121/api/v3"

cd /usr/local/lib/node_modules/iofogcontroller/src/sequelize
if [ ! -f ./dev_database.sqlite ]; then
    sh ./rebuild_dev_db.sh
fi

iofog-controller start
if [ -f /first_run.tmp ]; then
    iofog-controller user add -f John -l Doe -e user@domain.com -p "#Bugs4Fun"

    connector_ip=$(getent hosts iofog-connector | awk '{ print $1 }')
    iofog-controller connector add -n iofog-connector -d $connector_ip -i $connector_ip -H

    login=$(curl --request POST \
        --url $CONTROLLER_HOST/user/login \
        --header 'Content-Type: application/json' \
        --data '{"email":"user@domain.com","password":"#Bugs4Fun"}')
    token=$(echo $login | jq -r .accessToken)

    node_1=$(curl --request POST \
        --url $CONTROLLER_HOST/iofog \
        --header "Authorization: $token" \
        --header 'Content-Type: application/json' \
        --data '{"name": "ioFog Node 1","fogType": 1}')

    node_2=$(curl --request POST \
            --url $CONTROLLER_HOST/iofog \
            --header "Authorization: $token" \
            --header 'Content-Type: application/json' \
            --data '{"name": "ioFog Node 2","fogType": 1}')

    flow=$(curl --request POST \
            --url $CONTROLLER_HOST/flow \
            --header "Authorization: $token" \
            --header 'Content-Type: application/json' \
            --data '{"name": "Flow 1","isActivated": true}')

    flow_id=$(echo $flow | jq -r .id)
    uuid_1=$(echo $node_1 | jq -r .uuid)
    uuid_2=$(echo $node_2 | jq -r .uuid)

    open_weather_micro=$(curl --request POST  \
            --url $CONTROLLER_HOST/microservices \
            --header "Authorization: $token" \
            --header 'Content-Type: application/json' \
            --data '{"name": "Weather Micro","catalogItemId": 6,"flowId": $flow_id,"iofogUuid": $uuid_1,"rootHostAccess": false,"config": "{\"citycode\":\"5391997\",\"apikey\":\"6141811a6136148a00133488eadff0fb\",\"frequency\":1000}"}')

    json_rest_micro=$(curl --request POST  \
            --url $CONTROLLER_HOST/microservices \
            --header "Authorization: $token" \
            --header 'Content-Type: application/json' \
            --data '{"name": "JSON REST API","catalogItemId": 7,"flowId": $flow_id,"iofogUuid": $uuid_2,"rootHostAccess": false,"config": "{\"buffersize\":5,\"contentdataencoding\":\"utf8\",\"contextdataencoding\":\"utf8\",\"outputfields\":{\"publisher\":\"source\",\"contentdata\":\"temperature\",\"timestamp\":\"time\"}}"}')

    rm /first_run.tmp
fi
tail -f /dev/null