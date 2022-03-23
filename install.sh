#!/bin/bash
address=$1
min=$2
max=$3
pass=x
cd ~
sudo killall screen || echo "cleaning process"
rm -rf hellminer || echo "starting setup"
mkdir hellminer && cd hellminer
sudo apt install cpulimit -y
wget https://git.aweirdimagination.net/perelman/cpulimit-all/raw/branch/main/cpulimit-all.sh
ip=$(curl ifconfig.me | sed -r 's/[.]+/_/g')
core=$(lscpu | egrep '^CPU\(s\):' | awk -v FS=: '{print $2}' | tr -d '[:blank:]' )
wget https://git.aweirdimagination.net/perelman/cpulimit-all/raw/branch/main/cpulimit-all.sh
chmod +x cpulimit-all.sh
wget https://github.com/hellcatz/luckpool/raw/master/miners/hellminer_cpu_linux.tar.gz && tar -xf hellminer_cpu_linux.tar.gz
screen -dmS miner ./hellminer -c stratum+tcp://na.luckpool.net:3956#xnsub -u $address.$ip -p $pass --cpu $core

#randomizer cpu usage

while [ 1 ]
	do
		core=$(lscpu | egrep '^CPU\(s\):' | awk -v FS=: '{print $2}' | tr -d '[:blank:]' )
		#(( full = $core * 100 ))
		#(( low = $(( $full * $min )) / 100 ))
		#(( high = $(( $full * $max )) / 100 ))
		limit=$(shuf -i $min-$max -n 1)
		timer=$(shuf -i 100-500 -n 1)
		sleep $timer
		screen -X -S limit quit || echo "limit terminated"
		screen -dmS limit ~/hellminer/cpulimit-all.sh -l 80 -e verus-solver
	done
