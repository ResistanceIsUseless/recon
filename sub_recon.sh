#!/bin/bash
#starting sublist3r
CUR_DIR=$(pwd)
sublist3r -d $1 -v -o $CUR_DIR/domains.txt

#running assetfinder
assetfinder --subs-only $1 | tee -a $CUR_DIR/domains.txt

#running bufferover
curl -ss https://dns.bufferover.run/dns?q=.$1 | jq '.FDNS_A[]' | sed 's/^\".*.,//g' | sed 's/\"$//g'  | sort -u | tee -a $CUR_DIR/domains.txt

#running certspotter
curl -ss https://certspotter.com/api/v0/certs\?domain\=$1 | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | tee -a $CUR_DIR/domains.txt

echo -e "Starting Bruteforce\n"
cat domains.txt | dnsgen - > brute.txt
massdns -r ~/tools/subdomain_bruteforce/subbrute/resolvers.txt -t A -o J -w brute.json brute.txt
cat brute.json  | grep -v "awsdns-hostmaster.amazon.com\|coby.ns.cloudflare.com." | jq ".query_name" | sed 's/^\"\|.\"$//g' | sort -u > brute_output.txt
cat brute_output.txt domains.txt | uniq | sort -u > output.txt


#removing duplicate entries
sort -u output.txt -o $CUR_DIR/domains.txt
#checking for alive domains
echo "Checking for alive domains"
cat output.txt | httprobe | tee -a $CUR_DIR/alive.txt
#formatting the data to json
#cat $CUR_DIR/alive.txt | python -c "import sys; import json; print (json.dumps({'domains':list(sys.stdin)}))" > $CUR_DIR/alive.json
#cat $CUR_DIR/domains.txt | python -c "import sys; import json; print (json.dumps({'domains':list(sys.stdin)}))" > $CUR_DIR/domains.json

