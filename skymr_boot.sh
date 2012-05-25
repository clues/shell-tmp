#! /bin/sh
# run master: sh dev.sh master localnode
# run snode: sh dev.sh snode localnode masternode

TYPE=""
NODE_LOCAL=""
NODE_MASTER=
if [ $# -gt 3 -o $# -lt 2 ]; then
	echo "[error] shell args number is 2-3\nshell will exit..."
	exit
elif [ "$1" = "master" ]; then
	ok
elif [ "$1" = "snode" ]; then
	${3:?'[error] snode lose 3th args as master node shell will exit'}
	NODE_MASTER="'$3'"		
else
	echo "[error] first args must 'master' or 'snode'\nshell will exit..."
	exit
fi

NODE_LOCAL="$2"
TYPE="$1"

PROJECT_ROOT="/home/wave/git/skyFS-mapreduce"

CLIENT_APP_FILE="$PROJECT_ROOT/deps/client/ebin/client.app"
CE_APP_FILE="$PROJECT_ROOT/deps/ce/ebin/ce.app"
MR_APP_FILE="$PROJECT_ROOT/ebin/mr.app"

echo "[info] compile app"
make compile

echo "[info] start replace $CLIENT_APP_FILE...."
cat > $CLIENT_APP_FILE << CLIENT_APP_DOC
{application,client,
             [{description,[]},
              {vsn,"1"},
              {registered,[]},
              {applications,[kernel,stdlib]},
              {mod,{client_app,[]}},
  			{env, [{snport,29000},
			{cnip,['192.168.204.101']},
			{cnport,29009},
			{indexport,29001},
			{packetsize,256},
			{blocklength,64},
			{alive,5000},
			{rack,"/root/rack"}]},
              {modules,[]}]}.
CLIENT_APP_DOC

echo "[info] start replace $CE_APP_FILE...."
cat > $CE_APP_FILE << CE_APP_DOC
{application,ce,
             [{description,"cluster engine"},
              {vsn,"0.1.0"},
              {modules,[ce,ce_app,ce_clock_exchange,ce_cluster,ce_kernel,
                        ce_monitor,ce_register,ce_sup,ce_util]},
              {registered,[ce_kernel]},
              {mod,{ce_app,[]}},
              {env,[{known_nodes,[${NODE_MASTER}]},
                    {clock_time,6000},
                    {ping_interval,3000},
                    {notify_node_type,controller_NT}]},
              {applications,[kernel,stdlib]}]}.
CE_APP_DOC

echo "[info] start replace $MR_APP_FILE...."
cat > $MR_APP_FILE << MR_APP_DOC
{application,mr,
             [{description,[]},
              {vsn,"1"},
              {registered,[]},
              {applications,[kernel,stdlib]},
              {mod,{mr_app,[]}},
              {env,[{start_mod,${TYPE}},
                    {socket_timeout,5000},
                    {local_type,snode_NT},
                    {want_type,mr_master_NT}]},
              {modules,[]}]}.
MR_APP_DOC

COOKIE='12345'
echo "*******************************************************************"
echo "[info] start app type: $TYPE cookie: $COOKIE  node: $NODE_LOCAL"
echo "*******************************************************************"

erl -name $NODE_LOCAL \
-setcookie $COOKIE \
-pa "$PROJECT_ROOT/ebin" \
"$PROJECT_ROOT/deps/ce/ebin" \
"$PROJECT_ROOT/deps/client/ebin" \
"$PROJECT_ROOT/deps/lager/ebin" \
"$PROJECT_ROOT/deps/meck/ebin" \
"$PROJECT_ROOT/deps/protobuffs/ebin" \
 -eval 'application:start(client)','application:start(ce)','application:start(mr)'	


