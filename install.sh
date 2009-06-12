
# this ran OK ok centos 5
# it requires wgd for the database part and package part

# make sure this is the correct directory for the helpdesk files:

cd /data/helpdesk

# copy fines into the WebGUI area
# note: it may be desirable to create links rather than copy
WEBGUI=/data/WebGUI

cp -v /data/helpdesk/docs/helpdesk.sql $WEBGUI/docs
cp -v /data/helpdesk/docs/help_desk.wgpkg $WEBGUI/docs
find sbin/ -type f | xargs -I{} cp -v /data/helpdesk/{} $WEBGUI/{}
find www/ -type d | xargs -I{} mkdir $WEBGUI/{}
find www/ -type f | xargs -I{} cp -v /data/helpdesk/{} $WEBGUI/{}

cd /data/WebGUI/sbin

# be sure to edit the config file:
perl  installHelpDesk.pl --configFile localhost.conf

cd ../docs

wgd.old db < helpdesk.sql

wgd package --import help_desk.wgpkg


