#!/opt/bin/bash
####################################################################
# rrdstorm v1.3 (c) 2007-2008 http://xlife.zuavra.net && cupacup at wl500g.info
# Adapted for RT-N66u by ryzhov_al @ wl500g.info
#
# Published under the terms of the GNU General Public License v2.
# This program simplifies the use of rrdtool and rrdupdate.
# Please, check WAN interface name at line #369 (default is "ppp0"), and
# your disk partitions names at lines #435, #436 (default is "sda1" and "sda2").
#
# Usage:
# first run "rrdstorm create 0 1 2 3 4 5 6" to create html an database files,
# then you must update databases ever 60s using "rrdstorm update 0 1 2 3 4 5 6".
# You may draw all graphs using "rrdstorm graph 0 1 2 3 4 5 6"
# or draw graphs for a some periode of time using "rrdstorm graph_cron s 0 1 2 3 4 5 6"
# where:
# s means 1 hour graphs,
# h means 4 hours graphs,
# d means 24 hours graphs,
# w means weekly graphs,
# m means monthly graphs,
# y means yearly graphs.
#
# and numbers means:
# 0 - Average system load,
# 1 - RAM usage,
# 2 - Wireless PHY's temperatures,
# 3 - CPU usage,
# 4 - WAN traffic statistics,
# 5 - Disk space,
# 6 - Wireless outgoing traffic.
#
####################################################################
VERSION="RT-N66u"
DATE=$(date '+%x %R')
####################################################################

#-------------------------------------------------------------------
# configuration
#-------------------------------------------------------------------

RRDTOOL=/opt/bin/rrdtool
RRDUPDATE=/opt/bin/rrdupdate
RRDDATA=/opt/var/rrd_storm
RRDOUTPUT=/opt/share/www/rrd
FORCEGRAPH=no

#-------------------------------------------------------------------
# data definition: Average system load
#-------------------------------------------------------------------

RRDcFILE[0]="load:60:System load graphs"
RRDcDEF[0]='
DS:l1:GAUGE:120:0:100
DS:l5:GAUGE:120:0:100
DS:l15:GAUGE:120:0:100
RRA:AVERAGE:0.5:1:576
RRA:AVERAGE:0.5:6:672
RRA:AVERAGE:0.5:24:732
RRA:AVERAGE:0.5:144:1460
'
RRDuSRC[0]="l1:l5:l15"
RRDuVAL[0]='
UT=$(head -n1 /proc/loadavg)
L1=$(echo "$UT"|awk "{print \$1}")
L5=$(echo "$UT"|awk "{print \$2}")
L15=$(echo "$UT"|awk "{print \$3}")
echo "${L1}:${L5}:${L15}"
'
RRDgUM[0]='proc/min'
RRDgLIST[0]="0 1 2 3 4 5"
RRDgDEF[0]=$(cat <<EOF
'DEF:ds1=\$RRD:l1:AVERAGE'
'DEF:ds2=\$RRD:l5:AVERAGE'
'DEF:ds3=\$RRD:l15:AVERAGE'
'CDEF:bo=ds1,UN,0,ds1,IF,0,GT,UNKN,INF,IF'
'AREA:bo#DDDDDD:'
'CDEF:bi=ds1,UN,0,ds1,IF,0,GT,INF,UNKN,IF'
'AREA:bi#FEFEED:'
'HRULE:1.0#44B5FF'
'AREA:ds3#FFEE00:Last 15 min'
  'VDEF:max1=ds1,MAXIMUM'
  'VDEF:min1=ds1,MINIMUM'
  'VDEF:avg1=ds1,AVERAGE'
  GPRINT:max1:"Max %6.2lf"
  GPRINT:min1:"Min %6.2lf"
  GPRINT:avg1:"Avg %6.2lf\n"
'LINE3:ds2#FFCC00:Last  5 min'
  'VDEF:max2=ds2,MAXIMUM'
  'VDEF:min2=ds2,MINIMUM'
  'VDEF:avg2=ds2,AVERAGE'
  GPRINT:max2:"Max %6.2lf"
  GPRINT:min2:"Min %6.2lf"
  GPRINT:avg2:"Avg %6.2lf\n"
'LINE1:ds1#FF0000:Last  1 min'
  'VDEF:max3=ds3,MAXIMUM'
  'VDEF:min3=ds3,MINIMUM'
  'VDEF:avg3=ds3,AVERAGE'
  GPRINT:max3:"Max %6.2lf"
  GPRINT:min3:"Min %6.2lf"
  GPRINT:avg3:"Avg %6.2lf\n"
EOF
)

RRDgGRAPH[0]='3600|load1|System load, last hour|[ "$M" = 30 ]'
RRDgGRAPH[1]='14400|load6|System load, last 4 hours|[ "$M" = 30 ]'
RRDgGRAPH[2]='86400|load24|System load, last day|[ "$H" = 04 ] && [ "$M" = 30 ]|--x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[3]='604800|loadW|System load, last week|[ "$H" = 04 ] && [ "$M" = 30 ]|--x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[4]='2678400|loadM|System load, last month|[ "$H" = 04 ] && [ "$M" = 30 ]'
RRDgGRAPH[5]='31536000|loadY|System load, last year|[ "$H" = 04 ] && [ "$M" = 30 ]'

#-------------------------------------------------------------------
# data definition: RAM usage
#-------------------------------------------------------------------

RRDcFILE[1]="mem:60:RAM usage graphs"
RRDcDEF[1]='
DS:cached:GAUGE:120:0:1000000
DS:buffer:GAUGE:120:0:1000000
DS:free:GAUGE:120:0:1000000
DS:total:GAUGE:120:0:1000000
DS:swapt:GAUGE:120:0:1000000
DS:swapf:GAUGE:120:0:1000000
RRA:AVERAGE:0.5:1:576
RRA:AVERAGE:0.5:6:672
RRA:AVERAGE:0.5:24:732
RRA:AVERAGE:0.5:144:1460
'
RRDuSRC[1]="cached:buffer:free:total:swapt:swapf"
RRDuVAL[1]='
C=$(grep ^Cached /proc/meminfo|awk "{print \$2}")
B=$(grep ^Buffers /proc/meminfo|awk "{print \$2}")
F=$(grep ^MemFree /proc/meminfo|awk "{print \$2}")
T=$(grep ^MemTotal /proc/meminfo|awk "{print \$2}")
ST=$(grep ^SwapTotal /proc/meminfo|awk "{print \$2}")
SF=$(grep ^SwapFree /proc/meminfo|awk "{print \$2}")
echo "${C}:${B}:${F}:${T}:${ST}:${SF}"
'
RRDgUM[1]='bytes'
RRDgLIST[1]="6 7 8 9 10 11"
RRDgDEF[1]=$(cat <<EOF
'DEF:dsC=\$RRD:cached:AVERAGE'
'DEF:dsB=\$RRD:buffer:AVERAGE'
'DEF:dsF=\$RRD:free:AVERAGE'
'DEF:dsT=\$RRD:total:AVERAGE'
'CDEF:bo=dsT,UN,0,dsT,IF,0,GT,UNKN,INF,IF'
'AREA:bo#DDDDDD:'
'CDEF:tot=dsT,1024,*'
'CDEF:fre=dsF,1024,*'
'CDEF:freP=fre,100,*,tot,/'
'CDEF:buf=dsB,1024,*'
'CDEF:bufP=buf,100,*,tot,/'
'CDEF:cac=dsC,1024,*'
'CDEF:cacP=cac,100,*,tot,/'
'CDEF:use=dsT,dsF,dsC,+,dsB,+,-,1024,*'
'CDEF:useP=use,100,*,tot,/'
'CDEF:l=use,1,1,IF'
'AREA:use#CC3300:User   '
'LINE2:l#AC1300::STACK'
  'VDEF:maxU=use,MAXIMUM'
  'VDEF:minU=use,MINIMUM'
  'VDEF:avgU=use,AVERAGE'
  'VDEF:curU=use,LAST'
  'VDEF:procU=useP,LAST'
  GPRINT:curU:"Last %6.2lf %s"
  GPRINT:procU:"%3.0lf%%"
  GPRINT:avgU:"Avg %6.2lf %s"
  GPRINT:maxU:"Max %6.2lf %s"
  GPRINT:minU:"Min %6.2lf %s\n"
'AREA:cac#FF9900:Cached :STACK'
'LINE2:l#DF7900::STACK'
  'VDEF:maxC=cac,MAXIMUM'
  'VDEF:minC=cac,MINIMUM'
  'VDEF:avgC=cac,AVERAGE'
  'VDEF:curC=cac,LAST'
  'VDEF:procC=cacP,LAST'
  GPRINT:curC:"Last %6.2lf %s"
  GPRINT:procC:"%3.0lf%%"
  GPRINT:avgC:"Avg %6.2lf %s"
  GPRINT:maxC:"Max %6.2lf %s"
  GPRINT:minC:"Min %6.2lf %s\n"
'AREA:buf#FFCC00:Buffers:STACK'
'LINE2:l#DFAC00::STACK'
  'VDEF:maxB=buf,MAXIMUM'
  'VDEF:minB=buf,MINIMUM'
  'VDEF:avgB=buf,AVERAGE'
  'VDEF:curB=buf,LAST'
  'VDEF:procB=bufP,LAST'
  GPRINT:curB:"Last %6.2lf %s"
  GPRINT:procB:"%3.0lf%%"
  GPRINT:avgB:"Avg %6.2lf %s"
  GPRINT:maxB:"Max %6.2lf %s"
  GPRINT:minB:"Min %6.2lf %s\n"
'AREA:fre#FFFFCC:Unused :STACK'
  'VDEF:maxF=fre,MAXIMUM'
  'VDEF:minF=fre,MINIMUM'
  'VDEF:avgF=fre,AVERAGE'
  'VDEF:curF=fre,LAST'
  'VDEF:procF=freP,LAST'
  GPRINT:curF:"Last %6.2lf %s"
  GPRINT:procF:"%3.0lf%%"
  GPRINT:avgF:"Avg %6.2lf %s"
  GPRINT:maxF:"Max %6.2lf %s"
  GPRINT:minF:"Min %6.2lf %s\n"
EOF
)

RRDgGRAPH[6]='3600|mem1|RAM usage, last hour|[ "$M" = 30 ]|-l 0 -r'
RRDgGRAPH[7]='14400|mem6|RAM usage, last 4 hours|[ "$M" = 30 ]|-l 0 -r'
RRDgGRAPH[8]='86400|mem24|RAM usage, last day|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r --x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[9]='604800|memW|RAM usage, last week|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r --x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[10]='2678400|memM|RAM usage, last month|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r'
RRDgGRAPH[11]='31536000|memY|RAM usage, last year|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r'

#-------------------------------------------------------------------
# data definition: Wireless PHY's temperatures
#-------------------------------------------------------------------

RRDcFILE[2]="temp:60:Wireless PHYs temperature graphs"
RRDcDEF[2]='
DS:temp24:GAUGE:120:0:100
DS:temp50:GAUGE:120:0:100
RRA:AVERAGE:0.5:1:576
RRA:AVERAGE:0.5:6:672
RRA:AVERAGE:0.5:24:732
RRA:AVERAGE:0.5:144:1460
'
RRDuSRC[2]="temp24:temp50"
RRDuVAL[2]='
TEMP_24=$(/usr/sbin/wl -i eth1 phy_tempsense)
TEMP_50=$(/usr/sbin/wl -i eth2 phy_tempsense)
if [ -z "$TEMP_24" ]; then
 TEMP_24=0
else
 TEMP_24=$(($(echo "$TEMP_24" | awk "{print \$1}") /2 + 20))
fi
if [ -z "$TEMP_50" ]; then
 TEMP_50=0
else
 TEMP_50=$(($(echo "$TEMP_50" | awk "{print \$1}") /2 + 20))
fi
echo "${TEMP_24}:${TEMP_50}"
'
RRDgUM[2]='degrees, C'
RRDgLIST[2]="12 13 14 15 16 17"
RRDgDEF[2]=$(cat <<EOF
'DEF:t24=\$RRD:temp24:AVERAGE'
'DEF:t50=\$RRD:temp50:AVERAGE'
'CDEF:bo=t24,UN,0,t24,IF,0,GT,UNKN,INF,IF'
'AREA:bo#DDDDDD:'
'CDEF:bi=t50,UN,0,t50,IF,0,GT,INF,UNKN,IF'
'AREA:bi#FEFEED:'
'HRULE:1.0#44B5FF'
'AREA:t24#0040A2:Temperature, 2,4GHz'
  'VDEF:maxN=t24,MAXIMUM'
  'VDEF:minN=t24,MINIMUM'
  'VDEF:avgN=t24,AVERAGE'
  GPRINT:maxN:"Max %6.2lf %s"
  GPRINT:minN:"Min %6.2lf %s"
  GPRINT:avgN:"Avg %6.2lf %s\n"
'AREA:t50#90C5CC:Temperature, 5GHz  '
  'VDEF:maxS=t50,MAXIMUM'
  'VDEF:minS=t50,MINIMUM'
  'VDEF:avgS=t50,AVERAGE'
  GPRINT:maxS:"Max %6.2lf %s"
  GPRINT:minS:"Min %6.2lf %s"
  GPRINT:avgS:"Avg %6.2lf %s\n"
EOF
)

RRDgGRAPH[12]='3600|temp1|Wireless PHYs temperature, last hour|[ "$M" = 30 ]|-l 0 -r'
RRDgGRAPH[13]='14400|temp6|Wireless PHYs temperature, last 4 hours|[ "$M" = 30 ]|-l 0 -r'
RRDgGRAPH[14]='86400|temp24|Wireless PHYs temperature, last day|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r --x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[15]='604800|tempW|Wireless PHYs temperature, last week|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r --x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[16]='2678400|tempM|Wireless PHYs temperature, last month|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r'
RRDgGRAPH[17]='31536000|tempY|Wireless PHYs temperature, last year|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r'


#-------------------------------------------------------------------
# data definition: CPU usage
#-------------------------------------------------------------------

RRDcFILE[3]="cpu:60:CPU usage graphs"
RRDcDEF[3]='
DS:user:DERIVE:120:0:U
DS:nice:DERIVE:120:0:U
DS:sys:DERIVE:120:0:U
DS:idle:DERIVE:120:0:U
RRA:AVERAGE:0.5:1:576
RRA:AVERAGE:0.5:6:672
RRA:AVERAGE:0.5:24:732
RRA:AVERAGE:0.5:144:1460
'
RRDuSRC[3]="user:nice:sys:idle"
RRDuVAL[3]='
cat /proc/stat|head -1|sed "s/^cpu\ \+\([0-9]*\)\ \([0-9]*\)\ \([0-9]*\)\ \([0-9]*\).*/\1:\2:\3:\4/"
'
RRDgUM[3]='jiffies'
RRDgLIST[3]="18 19 20 21 22 23"
RRDgDEF[3]=$(cat <<EOF
'DEF:uj=\$RRD:user:AVERAGE'
'DEF:nj=\$RRD:nice:AVERAGE'
'DEF:sj=\$RRD:sys:AVERAGE'
'DEF:ij=\$RRD:idle:AVERAGE'
'CDEF:l=uj,0.1,0.1,IF'
'CDEF:bo=uj,UN,0,uj,IF,0,GT,UNKN,INF,IF'
'AREA:bo#DDDDDD:'
'CDEF:tj=uj,nj,+,sj,+,ij,+'
'CDEF:usr=100,uj,*,tj,/'
'CDEF:nic=100,nj,*,tj,/'
'CDEF:sys=100,sj,*,tj,/'
'CDEF:idl=100,ij,*,tj,/'
'CDEF:tot=100,tj,*,tj,/'
'AREA:nic#0040A2:Nice  '
  'VDEF:maxN=nic,MAXIMUM'
  'VDEF:minN=nic,MINIMUM'
  'VDEF:avgN=nic,AVERAGE'
  GPRINT:maxN:"Max %6.2lf%%"
  GPRINT:minN:"Min %6.2lf%%"
  GPRINT:avgN:"Avg %6.2lf%%\n"
'AREA:sys#90C5CC:System:STACK'
'LINE2:l#70A5AC::STACK'
  'VDEF:maxS=sys,MAXIMUM'
  'VDEF:minS=sys,MINIMUM'
  'VDEF:avgS=sys,AVERAGE'
  GPRINT:maxS:"Max %6.2lf%%"
  GPRINT:minS:"Min %6.2lf%%"
  GPRINT:avgS:"Avg %6.2lf%%\n"
'AREA:usr#B0E5EC:User  :STACK'
'LINE2:l#90C5CC::STACK'
  'VDEF:maxU=usr,MAXIMUM'
  'VDEF:minU=usr,MINIMUM'
  'VDEF:avgU=usr,AVERAGE'
  GPRINT:maxU:"Max %6.2lf%%"
  GPRINT:minU:"Min %6.2lf%%"
  GPRINT:avgU:"Avg %6.2lf%%\n"
'AREA:idl#EEFFFF:Idle  :STACK'
  'VDEF:maxI=idl,MAXIMUM'
  'VDEF:minI=idl,MINIMUM'
  'VDEF:avgI=idl,AVERAGE'
  GPRINT:maxI:"Max %6.2lf%%"
  GPRINT:minI:"Min %6.2lf%%"
  GPRINT:avgI:"Avg %6.2lf%%\n"
EOF
)

RRDgGRAPH[18]='3600|cpu1|CPU usage, last hour|[ "$M" = 30 ]|-l 0 -r -u 99.99'
RRDgGRAPH[19]='14400|cpu6|CPU usage, last 4 hours|[ "$M" = 30 ]|-r -l 0 -u 99.99'
RRDgGRAPH[20]='86400|cpu24|CPU usage, last day|[ "$H" = 04 ] && [ "$M" = 30 ]|-r -l 0 -u 99.99 --x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[21]='604800|cpuW|CPU usage, last week|[ "$H" = 04 ] && [ "$M" = 30 ]|-r -l 0 -u 99.99 --x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[22]='2678400|cpuM|CPU usage, last month|[ "$H" = 04 ] && [ "$M" = 30 ]|-r -l 0 -u 99.99'
RRDgGRAPH[23]='31536000|cpuY|CPU usage, last year|[ "$H" = 04 ] && [ "$M" = 30 ]|-r -l 0 -u 99.99'

#-------------------------------------------------------------------
# data definition: WAN traffic statistics
#-------------------------------------------------------------------

RRDcFILE[4]="wan:60:WAN Traffic graphs"
RRDcDEF[4]='
DS:in:DERIVE:600:0:12500000
DS:out:DERIVE:600:0:12500000
RRA:AVERAGE:0.5:1:576
RRA:AVERAGE:0.5:6:672
RRA:AVERAGE:0.5:24:732
RRA:AVERAGE:0.5:144:1460
'
RRDuSRC[4]="in:out"
RRDuVAL[4]='
IF="ppp0"
IN=$(grep "${IF}" /proc/net/dev|awk -F ":" "{print \$2}"|awk "{print \$1}")
OUT=$(grep "${IF}" /proc/net/dev|awk -F ":" "{print \$2}"|awk "{print \$9}")
echo "${IN}:${OUT}"
'
RRDgUM[4]='bytes/s'
RRDgLIST[4]="24 25 26 27 28 29"
RRDgDEF[4]=$(cat <<EOF
'DEF:ds1=\$RRD:in:AVERAGE'
'DEF:ds2=\$RRD:out:AVERAGE'
  'VDEF:max1=ds1,MAXIMUM'
'CDEF:ui=ds1,UN,0,ds1,IF,0,GT,UNKN,NEGINF,IF'
'CDEF:uo=0,ds1,UN,0,ds1,IF,0,GT,max1,50,/,UNKN,IF,-'
'CDEF:bi=ds1,UN,0,ds1,IF,0,GT,INF,UNKN,IF'
'CDEF:bo=ds1,UN,0,ds1,IF,0,GT,UNKN,INF,IF'
'AREA:bi#EDFEED:'
'AREA:ds1#00B5E3:Incoming'
'LINE1:ds1#0085B3:'
  'VDEF:min1=ds1,MINIMUM'
  'VDEF:avg1=ds1,AVERAGE'
  'VDEF:tot1=ds1,TOTAL'
  GPRINT:max1:"  Max %6.2lf %s"
  GPRINT:min1:"  Min %6.2lf %s"
  GPRINT:avg1:"  Avg %6.2lf %s"
  GPRINT:tot1:"  Sum %6.2lf %s"
'AREA:ui#FF6666:Offline\n'
'LINE2:ds2#E32D00:Outgoing'
  'VDEF:max2=ds2,MAXIMUM'
  'VDEF:min2=ds2,MINIMUM'
  'VDEF:avg2=ds2,AVERAGE'
  'VDEF:tot2=ds2,TOTAL'
  GPRINT:max2:"Max %6.2lf %s"
  GPRINT:min2:"Min %6.2lf %s"
  GPRINT:avg2:"Avg %6.2lf %s"
  GPRINT:tot2:"Sum %6.2lf %s"
'AREA:bo#FEEDED:'
'AREA:uo#00FE00:Online'
'HRULE:0#000000'
EOF
)  
   
RRDgGRAPH[24]='3600|wan1|WAN Traffic, last hour|[ "$M" = 30 ]|-r'
RRDgGRAPH[25]='14400|wan6|WAN Traffic, last 4 hours|[ "$M" = 30 ]|-r'
RRDgGRAPH[26]='86400|wan24|WAN Traffic, last day|[ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r --x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[27]='604800|wanW|WAN Traffic, last week|[ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r --x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[28]='2678400|wanM|WAN Traffic, last month|[ "$H" = 04 ] && [ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r '
RRDgGRAPH[29]='31536000|wanY|WAN Traffic, last year|[ "$H" = 04 ] && [ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r '

#-------------------------------------------------------------------
# data definition: Disk space
#-------------------------------------------------------------------

RRDcFILE[5]="hdd:60:Disk space graphs"
RRDcDEF[5]='
DS:optprosto:GAUGE:600:0:U
DS:optzasede:GAUGE:600:0:U
DS:mntprosto:GAUGE:600:0:U
DS:mntzasede:GAUGE:600:0:U
RRA:AVERAGE:0.5:1:576
RRA:AVERAGE:0.5:6:672
RRA:AVERAGE:0.5:24:732
RRA:AVERAGE:0.5:144:1460
'
RRDuSRC[5]="optprosto:optzasede:mntprosto:mntzasede"
RRDuVAL[5]='
SP=$(/opt/bin/df "-B1")
echo -n $(echo "$SP"|grep sda1|awk "{print \$4\":\"\$3}"):
echo -n $(echo "$SP"|grep sda2|awk "{print \$4\":\"\$3}")
echo
'
RRDgUM[5]='bytes'
RRDgLIST[5]="30 31 32 33 34 35"
RRDgDEF[5]=$(cat <<EOF
'DEF:optzasede=\$RRD:optzasede:AVERAGE'
'DEF:optprosto=\$RRD:optprosto:AVERAGE'
'DEF:mntzasede=\$RRD:mntzasede:AVERAGE'
'DEF:mntprosto=\$RRD:mntprosto:AVERAGE'
'CDEF:bo=mntzasede,UN,0,mntzasede,IF,0,GT,UNKN,INF,IF'
'AREA:bo#DDDDDD:'
'AREA:mntzasede#CC0033:sda1:'
  'CDEF:root=mntzasede,mntprosto,+'
  'VDEF:sumr=root,LAST'
  GPRINT:sumr:"Total %6.2lf %sB"
  'VDEF:lasr=mntzasede,LAST'
  GPRINT:lasr:"Used %6.2lf %sB"
  'CDEF:rootPu=mntzasede,100,*,root,/'
  'VDEF:procr=rootPu,LAST'
  GPRINT:procr:"%6.2lf%%"
'AREA:mntprosto#EC2053:Free:STACK'
  'VDEF:lasra=mntprosto,LAST'
  GPRINT:lasra:"%6.2lf %sB"
  'CDEF:rootPa=100,rootPu,-'
  'VDEF:procar=rootPa,LAST'
  GPRINT:procar:"%6.2lf%%\n"
'AREA:optzasede#33CC00:sda2:STACK'
  'CDEF:home=optzasede,optprosto,+'
  'VDEF:sumh=home,LAST'
  GPRINT:sumh:"Total %6.2lf %sB"
  'VDEF:lash=optzasede,LAST'
  GPRINT:lash:"Used %6.2lf %sB"
  'CDEF:homePu=optzasede,100,*,home,/'
  'VDEF:proch=homePu,LAST'
  GPRINT:proch:"%6.2lf%%"
'AREA:optprosto#53EC20:Free:STACK'
  'VDEF:lasha=optprosto,LAST'
  GPRINT:lasha:"%6.2lf %sB"
  'CDEF:homePa=100,homePu,-'
  'VDEF:procah=homePa,LAST'
  GPRINT:procah:"%6.2lf%%\n"
EOF
)

RRDgGRAPH[30]='3600|hdd1|Disk space, last hour|[ "$M" = 30 ]|-r -l 0'
RRDgGRAPH[31]='14400|hdd6|Disk space, last 4 hours|[ "$M" = 30 ]|-r -l 0'
RRDgGRAPH[32]='86400|hdd24|Disk space, last day|[ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r -l 0 --x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[33]='604800|hddW|Disk space, last week|[ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r -l 0 --x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[34]='2678400|hddM|Disk space, last month|[ "$H" = 04 ] && [ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r -l 0'
RRDgGRAPH[35]='31536000|hddY|Disk space, last year|[ "$H" = 04 ] && [ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r -l 0'

#-------------------------------------------------------------------
# data definition: Wireless outgoing traffic
#-------------------------------------------------------------------

RRDcFILE[6]="wlan:60:Wireless outgoing traffic graphs"
RRDcDEF[6]='
DS:out24:DERIVE:600:0:U
DS:out50:DERIVE:600:0:U
RRA:AVERAGE:0.5:1:576
RRA:AVERAGE:0.5:6:672
RRA:AVERAGE:0.5:24:732
RRA:AVERAGE:0.5:144:1460
'
RRDuSRC[6]="out24:out50"
RRDuVAL[6]='
OUT_24=$(grep eth1 /proc/net/dev|awk -F ":" "{print \$2}"|awk "{print \$9}")
OUT_50=$(grep eth2 /proc/net/dev|awk -F ":" "{print \$2}"|awk "{print \$9}")
echo "${OUT_24}:${OUT_50}"
'
RRDgUM[6]='bytes/s'
RRDgLIST[6]="36 37 38 39 40 41"
RRDgDEF[6]=$(cat <<EOF
'DEF:ds1=\$RRD:out24:AVERAGE'
'DEF:ds2=\$RRD:out50:AVERAGE'
  'VDEF:max1=ds1,MAXIMUM'
'CDEF:ui=ds1,UN,0,ds1,IF,0,GT,UNKN,NEGINF,IF'
'CDEF:uo=0,ds1,UN,0,ds1,IF,0,GT,max1,50,/,UNKN,IF,-'
'CDEF:bi=ds1,UN,0,ds1,IF,0,GT,INF,UNKN,IF'
'CDEF:bo=ds1,UN,0,ds1,IF,0,GT,UNKN,INF,IF'
'AREA:bi#EDFEED:'
'AREA:ds1#00B5E3:Outgoing 2,4GHz'
'LINE1:ds1#0085B3:'
  'VDEF:min1=ds1,MINIMUM'
  'VDEF:avg1=ds1,AVERAGE'
  'VDEF:tot1=ds1,TOTAL'
  GPRINT:max1:"Max %6.2lf %s"
  GPRINT:min1:"Min %6.2lf %s"
  GPRINT:avg1:"Avg %6.2lf %s"
  GPRINT:tot1:"Sum %6.2lf %s"
'AREA:ui#FF6666:Offline\n'
'LINE2:ds2#E32D00:Outgoing 5GHz  '
  'VDEF:max2=ds2,MAXIMUM'
  'VDEF:min2=ds2,MINIMUM'
  'VDEF:avg2=ds2,AVERAGE'
  'VDEF:tot2=ds2,TOTAL'
  GPRINT:max2:"Max %6.2lf %s"
  GPRINT:min2:"Min %6.2lf %s"
  GPRINT:avg2:"Avg %6.2lf %s"
  GPRINT:tot2:"Sum %6.2lf %s"
'AREA:bo#FEEDED:'
'AREA:uo#00FE00:Online'
'HRULE:0#000000'
EOF
)

RRDgGRAPH[36]='3600|wlan1|WLAN outgoing traffic, last hour|[ "$M" = 30 ]|-r'
RRDgGRAPH[37]='14400|wlan6|WLAN outgoing traffic, last 4 hours|[ "$M" = 30 ]|-r'
RRDgGRAPH[38]='86400|wlan24|WLAN outgoing traffic, last day|[ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r --x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[39]='604800|wlanW|WLAN outgoing traffic, last week|[ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r --x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[40]='2678400|wlanM|WLAN outgoing traffic, last month|[ "$H" = 04 ] && [ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r '
RRDgGRAPH[41]='31536000|wlanY|WLAN outgoing traffic, last year|[ "$H" = 04 ] && [ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r '

####################################################################
# STOP MODIFICATIONS HERE, UNLESS YOU REALLY KNOW WHAT YOU'RE DOING
####################################################################

#-------------------------------------------------------------------
# functions
#-------------------------------------------------------------------

#1=rrdfile 2=step 3=definition
CreateRRD()
{	
	"$RRDTOOL" create "$1" --step "$2" $3
}

#1=file, 2=data sources, 3=values
UpdateRRD()
{
	"$RRDUPDATE" "$1" -t "$2" "N:${3}"
}

#1=imgfile, 2=secs to go back, 3=um text, 4=title text,
#5=rrdfile, 6=definition, 7=extra params
CreateGraph()
{
  RRD="$5"
	DEF=$(echo "${6} "|sed 's/"/\\"/g'|sed '/[^ ]$/s/$/ \\/')
  eval "DEF=\"$DEF\""
	eval "\"$RRDTOOL\" graph \"$1\" $7 -M -a PNG -s \"-${2}\" -e -20 -w 550 -h 240 -v \"$3\" -t \"$4\" $DEF"
}

#-------------------------------------------------------------------
# main code
#-------------------------------------------------------------------

# TODO: examine parameters and output help if any mistake

# grab command
COMMAND="$1"
CRON_GRAPH_TIME="$2"
shift

# prepare main HTML index file
[ "$COMMAND" = create ] && {
	HTMLINDEX="${RRDOUTPUT}/index.html"
	[ -f "$HTMLINDEX" ] || {
		echo "<head><title>RRDStorm</title>
			<style>body{background:white;color:black}</style></head>
			<body><h1>RRDStorm</h1><ul>" > "$HTMLINDEX"
		MAKEINDEX=yes
	}
}
# cycle numbers
for N in "$@"; do
	# does this N exist?
	[ -z "${RRDcFILE[$N]}" ] && continue
	# extract common data
	FILEBASE=$(echo "${RRDcFILE[$N]}"|awk -F: '{print $1}')
	RRDFILE="${RRDDATA}/${FILEBASE}.rrd"
	# honor command
	case "$COMMAND" in
		create)
			# extract base data
			HTMLFILE="${RRDOUTPUT}/${FILEBASE}.html"
			STEP=$(echo "${RRDcFILE[$N]}"|awk -F: '{print $2}')
			HTITLE=$(echo "${RRDcFILE[$N]}"|awk -F: '{print $3}')
			# check RRD archive
			[ -d "$RRDDATA" ] || mkdir -p "$RRDDATA"
			[ -f "$RRDFILE" ] || CreateRRD  "$RRDFILE" "$STEP" "${RRDcDEF[$N]}"
			# check individual HTML file
			[ -d "$RRDOUTPUT" ] || mkdir -p "$RRDOUTPUT"
			[ -f "$HTMLFILE" ] || {
				echo "<head><title>${HTITLE}</title>
					<style>body{background:white;color:black}</style></head>
					<body><h1>${HTITLE}</h1><center>" > "$HTMLFILE"
				for P in ${RRDgLIST[$N]}; do
					[ -z "${RRDgGRAPH[$P]}" ] && continue
					IMGBASE=$(echo "${RRDgGRAPH[$P]}"|cut -d'|' -f2)
					echo "<img src=\"${IMGBASE}.png\"><br>" >> "$HTMLFILE"
				done
				echo "</center><p>RRDStorm for ${VERSION} / ${DATE}</p></body>" >> "$HTMLFILE"
			}
			# update the main HTML index
			[ ! -z "$MAKEINDEX" ] && {
				echo "<li><a href=\"${FILEBASE}.html\">${HTITLE}</a>" >> "$HTMLINDEX"
			}
		;;
		update)
			VAL=$(eval "${RRDuVAL[$N]}")
			echo "Updating ($N) $RRDFILE with $VAL .."
			UpdateRRD "$RRDFILE" "${RRDuSRC[$N]}" "$VAL"
		;;
		help)
			echo "Usage: rrdstorm {create|update|graph|graph_cron[s h d w m y]} 0 1 2 .."
			echo "graph_cron is for cron to quicky update just one graph [1h=s 4h=h 24h=d 1week=w 1 month=m 1year=y]} 0 1 2 .."
		;;
		graph)
			# grab hour and minute
			M=$(date "+%M")
			H=$(date "+%H")
			# do graphs
			for P in ${RRDgLIST[$N]}; do
				[ -z "${RRDgGRAPH[$P]}" ] && continue
				BACK=$(echo "${RRDgGRAPH[$P]}"|cut -d'|' -f1)
				IMGBASE=$(echo "${RRDgGRAPH[$P]}"|cut -d'|' -f2)
				TITLE=$(echo "${RRDgGRAPH[$P]}"|cut -d'|' -f3)
				EXTRA=$(echo "${RRDgGRAPH[$P]}"|cut -d'|' -f5)
				[ ! -z "$FORCEGRAPH" ] && {
					RET=1
				} || {
					COND=$(echo "${RRDgGRAPH[$P]}"|cut -d'|' -f4)
					[ -z "$COND" ] && RET=1 || {
						COND="if ${COND}; then RET=1; else RET=0; fi"
						eval "$COND"
					}
				}
				[ "$RET" = 1 ] && {
					echo "Making graph (${N}:${P}) ${RRDOUTPUT}/${IMGBASE}.png .."
					CreateGraph "${RRDOUTPUT}/${IMGBASE}.png" "$BACK" "${RRDgUM[$N]}" "$TITLE" "$RRDFILE" "${RRDgDEF[$N]}" "$EXTRA" "--graph-render-mode mono"
				}
			done
		;;
		graph_cron)
			if [[ $N =~ ^[0-9]{1,3}$ ]]; then
				# grab hour and minute
				M=$(date "+%M")
				H=$(date "+%H")
				# do graphs
				if [ $CRON_GRAPH_TIME == "s" ]; then
    					CRON_SUB_GRAPH=0
				elif [ $CRON_GRAPH_TIME == "h" ]; then
    					CRON_SUB_GRAPH=1
				elif [ $CRON_GRAPH_TIME == "d" ]; then
    					CRON_SUB_GRAPH=2
				elif [ $CRON_GRAPH_TIME == "w" ]; then
    					CRON_SUB_GRAPH=3
				elif [ $CRON_GRAPH_TIME == "m" ]; then
    					CRON_SUB_GRAPH=4
				elif [ $CRON_GRAPH_TIME == "y" ]; then
    					CRON_SUB_GRAPH=5
				else
					exit 1
				fi
				P=$((((($N+1)*6)-6)+$CRON_SUB_GRAPH))
				[ -z "${RRDgGRAPH[$P]}" ] && continue
				BACK=$(echo "${RRDgGRAPH[$P]}"|cut -d'|' -f1)
				IMGBASE=$(echo "${RRDgGRAPH[$P]}"|cut -d'|' -f2)
				TITLE=$(echo "${RRDgGRAPH[$P]}"|cut -d'|' -f3)
				EXTRA=$(echo "${RRDgGRAPH[$P]}"|cut -d'|' -f5)
				[ ! -z "$FORCEGRAPH" ] && {
					RET=1
				} || {
					COND=$(echo "${RRDgGRAPH[$P]}"|cut -d'|' -f4)
					[ -z "$COND" ] && RET=1 || {
						COND="if ${COND}; then RET=1; else RET=0; fi"
						eval "$COND"
					}
				}
				[ "$RET" = 1 ] && {
					echo "Making graph (${N}:${P}) ${RRDOUTPUT}/${IMGBASE}.png .."
					CreateGraph "${RRDOUTPUT}/${IMGBASE}.png" "$BACK" "${RRDgUM[$N]}" "$TITLE" "$RRDFILE" "${RRDgDEF[$N]}" "$EXTRA"
				}
			fi
		;;
		*)
			echo "Usage: rrdstorm {create|update|graph|graph_cron[s h d w m y]} 0 1 2 .."
			exit 1
		;;
	esac
done

# close the main HTML index
[ ! -z "$MAKEINDEX" ] && {
	echo "</ul><p>RRDStorm for ${VERSION} / ${DATE}</p></body>" >> "$HTMLINDEX"
}

exit 0