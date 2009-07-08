
helpdesk=/data/helpdesk
WEBGUI=/data/WebGUI

# this ran OK ok centos 5
# it requires wgd for the database part and package part

# copy files into the WebGUI area
# note: it may be desirable to create links rather than copy

cd $helpdesk

# these commands can be used to un-install the modules & extras for helpdesk
# remember to incldue the assignments above
# find sbin/ -type f | xargs -I{} rm -f $WEBGUI/{}
# find www/ -type f | xargs -I{} rm -f $WEBGUI/{}
# find lib/ -type f | xargs -I{} rm -f $WEBGUI/{}

# these commands can be used to diff the modules & extras for helpdesk
# remember to incldue the assignments above
# find sbin/ -type f | xargs -I{} diff -u $helpdesk/{} $WEBGUI/{}
# find www/ -type f | xargs -I{} diff -u $helpdesk/{} $WEBGUI/{}
# find lib/ -type f | xargs -I{} diff -u $helpdesk/{} $WEBGUI/{}

find sbin/ -type f | xargs -I{} ln $helpdesk/{} $WEBGUI/{}
find www/ -type d | xargs -I{} mkdir $WEBGUI/{} 2> /dev/null
find www/ -type f | xargs -I{} ln $helpdesk/{} $WEBGUI/{}
find lib/ -type f | xargs -I{} ln $helpdesk/{} $WEBGUI/{}
# note that it is necessary to re-create the hard links any time you update the git repo...

# be sure to edit the config file:
cd $WebGUI/sbin
perl  installHelpDesk.pl --configFile localhost.conf

wgd.old db < $helpdesk/helpdesk.sql

wgd package --import $helpdesk/help_desk.wgpkg

