#
# DNS Update for GoDaddy DNS Records
#
# syntax dnsup.sh <input file> <apikey> <apisecret>
#

# check if input file exists
[ ! -f $1 ] && { echo "$1 file not found"; exit 2; }

# check for correct variable count
if [ -z "$3" ] || [ -n "$4" ]
then
        echo "invalid variable list"
        echo "Syntax:"
        echo "dnsupd.sh <inputfilename> <apikey> <apisecret>"
        exit 3
fi

# INPUTS ARE OK, PROCEED

domain="coherentsecurity.com"
type="A"
ttl="600"
headers1="Authorization: sso-key $2:$3"

echo "=====================================" | tee -a dnsupd.log
echo "DNS Update run for $(date)" | tee -a dnsupd.log

while read hostname newip
do
        echo "A Record : " $hostname
        echo " IP Data : " $newip
# check current value

       currentdns=$(curl -s -X GET -H "$headers1" "https://api.godaddy.com/v1/domains/$domain/records/$type/$hostname")
       currentip=$(echo $currentdns | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
       echo "the change is $currentip to  $newip"
         if [ $currentip != $newip ];
         then
           curl -X PUT "https://api.godaddy.com/v1/domains/$domain/records/$type/$hostname" \
           -H "accept: application/json" \
           -H "Content-Type: application/json" \
           -H "$headers1" \
           -d "[ { \"data\": \"$newip\", \"ttl\": $ttl } ]"
           rc=$?
           echo "retcode is $rc"
           if [ $rc ];
           then
             echo "$hostname update to $newip success" | tee -a dnsupd.log
           else
             echo "ERROR - $hostname update to $newip failed" | tee -a dnsupd.log
           fi
        else
          echo "ERROR - Source and Dest IP are the same - $newip" | tee -a dnsupd.log
        fi

done < $1
