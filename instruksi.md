--xmrig cc on arm ubuntu 20.04 with random cpu usage --

usage :
curl https://raw.githubusercontent.com/fuzzle20/all-about-cpu-mining/main/arm64-xmrigcc-install.sh | bash -s -- "[algo]" [pool] [address] [pass] [min] [max]


example :

curl https://raw.githubusercontent.com/fuzzle20/all-about-cpu-mining/main/arm64-xmrigcc-install.sh | bash -s -- "rx/0" rx.unmineable.com:3333 DOGE:DSPJWDQZX7HwJbXGYAigtspHAcg13m2U53.arm x 50 90


list algo :
https://github.com/Bendr0id/xmrigCC/blob/master/doc/ALGORITHMS.md


============================


-- hellminer mining verus with random cpu usage on ubuntu 20.04 --

usage :

curl https://raw.githubusercontent.com/fuzzle20/all-about-cpu-mining/main/verus-hellminer-random-cpu.sh | bash -s -- [pool] [address] [pass] [min] [max]

Example :

curl https://raw.githubusercontent.com/fuzzle20/all-about-cpu-mining/main/verus-hellminer-random-cpu.sh | bash -s -- na.luckpool.net:3956 RNyQTpxScwNevnFfwe8s1bBYMgYq7fWcC7 x 50 70
