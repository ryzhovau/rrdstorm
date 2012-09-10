#!/opt/bin/bash
####################################################################
# rrdstorm v1.3 (c) 2007-2008 http://xlife.zuavra.net && cupacup at wl500g.info
# Published under the terms of the GNU General Public License v2.
# This program simplifies the use of rrdtool and rrdupdate.
# The vanilla version is tweaked by default for use on the
# For running this script you should also have bash installed, and check for right grep functions in disk stats
# Type "rrdstorm.sh help" for more info. Quick usage first run "rrdstorm create 0 1 2 3 4 5 6 7" to create html an database files,
# then you must update databases ever 60s usnig "rrdstorm update 0 1 2 3 4 5 6 7", graphs can be generated every time using command
# "rrdstorm graph 0 1 2 3 4 5 6 7" or "rrdstorm graph_cron s 0 1 2 3 4 5 6 7"
# s means 1 hour graph, check help command for more info.
####################################################################
VERSION="wl500gpv2"
DATE=$(date '+%x %R')
####################################################################

#-------------------------------------------------------------------
# configuration
#-------------------------------------------------------------------

RRDTOOL=/opt/bin/rrdtool
RRDUPDATE=/opt/bin/rrdupdate
RRDDATA=/mnt/www
RRDOUTPUT=/mnt/www
FORCEGRAPH=no

#-------------------------------------------------------------------
# data definition: average load
#-------------------------------------------------------------------

RRDcFILE[0]="load:60:Load graphs"
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

RRDgGRAPH[0]='3600|load1|Load last hour|[ "$M" = 30 ]'
RRDgGRAPH[1]='14400|load6|Load last 4H|[ "$M" = 30 ]'
RRDgGRAPH[2]='86400|load24|Load last 24H|[ "$H" = 04 ] && [ "$M" = 30 ]|--x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[3]='604800|loadW|Load last week|[ "$H" = 04 ] && [ "$M" = 30 ]|--x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[4]='2678400|loadM|Load last month|[ "$H" = 04 ] && [ "$M" = 30 ]'
RRDgGRAPH[5]='31536000|loadY|Load last year|[ "$H" = 04 ] && [ "$M" = 30 ]'

#-------------------------------------------------------------------
# data definition: memory allocation
#-------------------------------------------------------------------

RRDcFILE[1]="mem:60:Memory allocation"
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

RRDgGRAPH[6]='3600|mem1|RAM last hour|[ "$M" = 30 ]|-l 0 -r'
RRDgGRAPH[7]='14400|mem6|RAM last 4H|[ "$M" = 30 ]|-l 0 -r'
RRDgGRAPH[8]='86400|mem24|RAM last 24H|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r --x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[9]='604800|memW|RAM last week|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r --x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[10]='2678400|memM|RAM last month|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r'
RRDgGRAPH[11]='31536000|memY|RAM last year|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r'

#-------------------------------------------------------------------
# data definition: CPU temp and fan
#-------------------------------------------------------------------

##no way to go(maybe wlan data SNR,RATE...)

#-------------------------------------------------------------------
# data definition: cpu usage
#-------------------------------------------------------------------

RRDcFILE[3]="cpu:60:CPU Usage"
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

RRDgGRAPH[18]='3600|cpu1|CPU Usage (1H)|[ "$M" = 30 ]|-l 0 -r -u 99.99'
RRDgGRAPH[19]='14400|cpu6|CPU Usage (4H)|[ "$M" = 30 ]|-r -l 0 -u 99.99'
RRDgGRAPH[20]='86400|cpu24|CPU Usage (24H)|[ "$H" = 04 ] && [ "$M" = 30 ]|-r -l 0 -u 99.99 --x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[21]='604800|cpuW|CPU Usage (last week)|[ "$H" = 04 ] && [ "$M" = 30 ]|-r -l 0 -u 99.99 --x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[22]='2678400|cpuM|CPU Usage (last month)|[ "$H" = 04 ] && [ "$M" = 30 ]|-r -l 0 -u 99.99'
RRDgGRAPH[23]='31536000|cpuY|CPU Usage (last year)|[ "$H" = 04 ] && [ "$M" = 30 ]|-r -l 0 -u 99.99'

#-------------------------------------------------------------------
# network stats
#-------------------------------------------------------------------

RRDcFILE[4]="wan:60:WAN Traffic"
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
IF="vlan1"
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
  GPRINT:max1:"Max %6.2lf %s"
  GPRINT:min1:"Min %6.2lf %s"
  GPRINT:avg1:"Avg %6.2lf %s"
  GPRINT:tot1:"Sum %6.2lf %s"
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
   
RRDgGRAPH[24]='3600|wan1|WAN Traffic (1H)|[ "$M" = 30 ]|-r'
RRDgGRAPH[25]='14400|wan6|WAN Traffic (4H)|[ "$M" = 30 ]|-r'
RRDgGRAPH[26]='86400|wan24|WAN Traffic (24H)|[ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r --x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[27]='604800|wanW|WAN Traffic (last week)|[ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r --x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[28]='2678400|wanM|WAN Traffic (last month)|[ "$H" = 04 ] && [ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r '
RRDgGRAPH[29]='31536000|wanY|WAN Traffic (last year)|[ "$H" = 04 ] && [ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r '

#-------------------------------------------------------------------
# disk space
#-------------------------------------------------------------------

RRDcFILE[5]="hdd:60:Disk space"
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
SP=$(/opt/bin/coreutils-df "-B1")
echo -n $(echo "$SP"|grep opt|awk "{print \$3\":\"\$2}"):
echo -n $(echo "$SP"|grep mnt|awk "{print \$3\":\"\$2}")
echo
'
RRDgUM[5]='space (bytes)'
RRDgLIST[5]="30 31 32 33 34 35"
RRDgDEF[5]=$(cat <<EOF
'DEF:optzasede=\$RRD:optzasede:AVERAGE'
'DEF:optprosto=\$RRD:optprosto:AVERAGE'
'DEF:mntzasede=\$RRD:mntzasede:AVERAGE'
'DEF:mntprosto=\$RRD:mntprosto:AVERAGE'
'CDEF:bo=mntzasede,UN,0,mntzasede,IF,0,GT,UNKN,INF,IF'
'AREA:bo#DDDDDD:'
'AREA:mntzasede#CC0033:/mnt:'
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
'AREA:optzasede#33CC00:/opt:STACK'
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

RRDgGRAPH[30]='3600|hdd1|Disk space (1H)|[ "$M" = 30 ]|-r -l 0'
RRDgGRAPH[31]='14400|hdd6|Disk space (4H)|[ "$M" = 30 ]|-r -l 0'
RRDgGRAPH[32]='86400|hdd24|Disk space (24H)|[ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r -l 0 --x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[33]='604800|hddW|Disk space (last week)|[ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r -l 0 --x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[34]='2678400|hddM|Disk space (last month)|[ "$H" = 04 ] && [ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r -l 0'
RRDgGRAPH[35]='31536000|hddY|Disk space (last year)|[ "$H" = 04 ] && [ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r -l 0'

#-------------------------------------------------------------------
# network stats
#-------------------------------------------------------------------

RRDcFILE[6]="wlan:60:WLAN Traffic"
RRDcDEF[6]='
DS:in:DERIVE:600:0:U
DS:out:DERIVE:600:0:U
RRA:AVERAGE:0.5:1:576
RRA:AVERAGE:0.5:6:672
RRA:AVERAGE:0.5:24:732
RRA:AVERAGE:0.5:144:1460
'
RRDuSRC[6]="in:out"
RRDuVAL[6]='
IF="eth1"
IN=$(grep "${IF}" /proc/net/dev|awk -F ":" "{print \$2}"|awk "{print \$1}")
OUT=$(grep "${IF}" /proc/net/dev|awk -F ":" "{print \$2}"|awk "{print \$9}")
echo "${IN}:${OUT}"
'
RRDgUM[6]='bytes/s'
RRDgLIST[6]="36 37 38 39 40 41"
RRDgDEF[6]=$(cat <<EOF
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
  GPRINT:max1:"Max %6.2lf %s"
  GPRINT:min1:"Min %6.2lf %s"
  GPRINT:avg1:"Avg %6.2lf %s"
  GPRINT:tot1:"Sum %6.2lf %s"
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
   
RRDgGRAPH[36]='3600|wlan1|WLAN Traffic (1H)|[ "$M" = 30 ]|-r'
RRDgGRAPH[37]='14400|wlan6|WLAN Traffic (4H)|[ "$M" = 30 ]|-r'
RRDgGRAPH[38]='86400|wlan24|WLAN Traffic (24H)|[ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r --x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[39]='604800|wlanW|WLAN Traffic (last week)|[ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r --x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[40]='2678400|wlanM|WLAN Traffic (last month)|[ "$H" = 04 ] && [ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r '
RRDgGRAPH[41]='31536000|wlanY|WLAN Traffic (last year)|[ "$H" = 04 ] && [ "$M" -ge 30 ] && [ "$M" -le 45 ]|-r '

#-------------------------------------------------------------------
# swap allocation
#-------------------------------------------------------------------

RRDcFILE[7]="mem:60:Swap allocation"
RRDgUM[7]='bytes'
RRDgLIST[7]="42 43 44 45 46 47"
RRDgDEF[7]=$(cat <<EOF
'DEF:sT=\$RRD:swapt:AVERAGE'
'DEF:sF=\$RRD:swapf:AVERAGE'
'CDEF:sU=sT,sF,-'
'CDEF:bo=sT,UN,0,sT,IF,0,GT,UNKN,561936,IF'
'AREA:bo#FFCCCC:'
'AREA:sU#9999FF:Used'
'AREA:sF#FFFF99:Free:STACK'
'LINE:sU#7777DD:'
'HRULE:31832#FF0000'
'HRULE:561936#FF0000'
EOF
)

RRDgGRAPH[42]='3600|swap1|Swap last hour|[ "$M" = 30 ]|-l 0 -r'
RRDgGRAPH[43]='14400|swap6|Swap last 4H|[ "$M" = 30 ]|-l 0 -r'
RRDgGRAPH[44]='86400|swap24|Swap last 24H|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r --x-grid HOUR:1:DAY:1:HOUR:1:0:%H'
RRDgGRAPH[45]='604800|swapW|Swap last week|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r --x-grid HOUR:4:DAY:1:DAY:1:0:"%a %d/%m"'
RRDgGRAPH[46]='2678400|swapM|Swap last month|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r'
RRDgGRAPH[47]='31536000|swapY|Swap last year|[ "$H" = 04 ] && [ "$M" = 30 ]|-l 0 -r'




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