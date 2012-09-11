RRDStorm - A RRDTool graph tool for routers
==================================

This shell script helps you to collect and visualize various statistics about
your router.

First version was written for www.wl500g.info in 2005 for Asus WL-500G
<http://wl500g.info/showthread.php?2848-RRDTool-Traffic-Graph-Tutorial-Extremely-easy-to-follow-!>
and now it evolved to use on Asus RT-N66U.


Requirements
-----------------------

rrdtool - a package from Entware/Optware/OpenWRT repositories,
bash - required bacause of arrays, shell from busybox is not sufficient,
cron - to collect data periodically,
web server - to serve static HTML files and PNG images with stat visualization.


Installation and configuration
-----------------------

 1) Place rrdstorm.sh to router and make sure it executable.

 2) Look into rrdstorm.sh and change path to Round Robin DB storage,
path to WWW root, check HDD partition names and other sensors definitions.

Default values is for Entware/Optware.

 3) Initialize RRD database

    $ rrdsorm.sh create 0 1 2 3 4 5 6

where 0..6 is sensor numbers. You may use only some of them:

 * 0 - Average system load,
 * 1 - RAM usage,
 * 2 - Wireless PHY's temperatures,
 * 3 - CPU usage,
 * 4 - WAN traffic statistics,
 * 5 - Disk space,
 * 6 - Wireless outgoing traffic.

 4) Create a cron job to collect sensors data every minute:

    $ rrdstorm.sh update 0 1 2 3 4 5 6

 5) Crease a cron job to update graphs as soon as you wish, i.e. every hour:

    $ rrdstorm.sh graph_cron h 0 1 2 3 4 5 6

where h is a drawing period. Avaliable periods:

 * s - 1 hour graphs,
 * h - 4 hours graphs,
 * d - 24 hours graphs,
 * w -  weekly graphs,
 * m - monthly graphs,
 * y - yearly graphs.

If you want to draw graphs for all those periods then use:

    $ rrdstorm.sh graph 0 1 2 3 4 5 6

On my Asus RT-N66U last one takes ~3,5 minutes. See WIKI pages for graph
examples.

Feel free to use and to discuss rrdstorm.sh here or at www.wl500g.info

License
-------

See the LICENSE file in the source code for the license terms.
