#!/bin/bash
#
# Checks the block height with JSON-RPC, and does error handling if it did not increase
# since last check. Requires that RPC is enabled in the neo-cli service.
#
# Usage: check-neo-cli-blockheight.sh [<host:port>]
#
# Defaults to localhost:10332
#
FILE_LAST_HEIGHT="/tmp/.neo-cli-height-last.txt"
FILE_ERROR_LOG="/tmp/.neo-cli-height-last-errors.txt"

# Set a default host, can be overwritten by cli argument
HOST="localhost:10332"
if [ ! -z "$1" ]; then
    HOST=$1
fi

# Error handler
function error_block_height_not_increasing {
    echo "ERROR - block height is the same as last!"
    date >> $FILE_ERROR_LOG
    systemctl restart neonode
}

# Start normal check
echo "Checking block height of $HOST"

# If file exists, read last saved height
if [ -f $FILE_LAST_HEIGHT ]; then
    HEIGHT_LAST=`cat $FILE_LAST_HEIGHT`
fi

# Do the POST request to get the block height. Error out if unsuccessful
json_response=`curl -s -X POST $HOST -d '{ "jsonrpc": "2.0", "id": 5, "method": "getblockcount", "params": [] }'`
if [ $? != 0 ]; then
    echo "ERROR: did not receive a valid response"
    height="-1"
else
    # After successful query, extract the block height from the JSON response
    height=`echo $json_response | python -c "import sys, json; print json.load(sys.stdin)['result']"`
fi

echo "height: $height (last: $HEIGHT_LAST)"

# Save the latest height to file
echo $height > $FILE_LAST_HEIGHT

# Error / restart neo-cli if block is stuck
if [ ! -z "$HEIGHT_LAST" ] && [ $height == $HEIGHT_LAST ]; then
    error_block_height_not_increasing
fi
