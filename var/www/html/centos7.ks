#version=DEVEL
# System authorization information
auth --enableshadow --passalgo=sha512
# Use CDROM installation media
cdrom
# Use graphical install
graphical
# Run the Setup Agent on first boot
firstboot --enable
ignoredisk --only-use=sda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
#network  --bootproto=dhcp --device=ens33 --ipv6=auto --activate
network  --bootproto=static --ip=172.16.92.250 --netmask=255.255.255.0 --gateway=172.16.92.2 --nameserver=172.16.92.2 --device=ens33 --ipv6=auto --activate
network  --hostname=guac.localdomain

# Root password
rootpw --iscrypted $6$B4JpuFwr1EtvvQiv$UQjczzsJUDHxJzIctzIQegFAX/WpGLhRFpahYNY0.mLH2V4ragr8a1nNG0GFC3.B33ZEcQob/7zDbvNeikUam1
# System services
services --enabled="chronyd"
# System timezone
timezone America/Chicago --isUtc
# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
autopart --type=lvm
# Partition clearing information
clearpart --none --initlabel

%packages
@^minimal
@core
chrony
kexec-tools
# Install openssh
ca-certificates
openssl
openssh-server
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

%post
#---- Install our SSH key ----
mkdir -m0700 /root/.ssh/

cat <<EOF >/root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkORyodNDQO3TDH09pTr+fDsPFdsoJL2rK7JnsVPtAvaHFGp59N7YSKrn240AL6lIvTGvnQ+0k/hU4lusweW1x/K2+VV3G7BXxW+nB5AQofMXRieoKT6VKqNJcrnVOftEtKIDjz2FWItXxPTKkVduAkvn73Fu+NUc5cK0NLYEtURvyPuOCmCSFYgRuOf4QH3cO4zgESZMUtkD7xg/0fY+dlTuzhhc7oJREobzIlWnNuI+TYgbF6GXHFYxiI7er4zBhnSG8OH+XaHt7d/4XeH+az9k69XEXtAVW4l7+7Jvv/eqyfyDCfpdrWfR1uCPdrKEuUMRX2gp0Q86lCcAXNYZ/ rac3rx@localhost.localdomain
EOF

cat <<EOF>/root/.screenrc

# Messages ####################################################################
nethack on              # be careful! new screen tonight.
sorendition "kg"        # makes screen messages stand out, black on green
msgwait 2               # default message display is too long
startup_message off     # boooring!
version                 # echo version on startup, 'cause it's nice to know


# Misc ########################################################################
autodetach on           # A.K.A. the "save your bacon" option
altscreen on            # full-screen programs (less, Vim) should be cleared once quit
vbell off               # visual bells are hard to do right. screen's isn't good
defutf8 on              # allow utf characters

defnonblock 5
defflow off             # try to disable flow control (buggy)
bind s                  # free ctrl-s
bind > eval writebuf "exec sh -c 'xsel -bi </tmp/screen-exchange'"
bind < eval "exec sh -c 'xsel -bo >/tmp/screen-exchange'" readbuf
# Scroll-back mode ############################################################
ignorecase on           # case insensitive search in scroll-back mode
defscrollback 9999      # default scroll-back buffer is tiny. (no. of lines.)
bufferfile $HOME/.screen-exchange  # keep the buffer exchange file out of /tmp

attrcolor b ".I"
termcapinfo xterm-256color 'Co#256:AB=\E[48;5;%dm:AF=\E[38;5;%dm'

# tput colors   <-- should equal 256
term screen-254color

# Create windows on startup ###################################################
select 0
screen -t root          0 sudo su - root
screen -t lsof          1 sudo watch lsof -i
screen -t netstat       2 sudo watch netstat -tulpnwe
screen -t top           3 sudo /home/linuxbrew/.linuxbrew/bin/vtop
screen -t root          4 sudo su - root

# Hardstatus ##################################################################
hardstatus alwayslastline '%{= kG}[ %{G}%H %{g}][%= %{= kw}%?%-Lw%?%{r}(%{W}%n*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%? %= %{g}][%{ky}%D %{ky}%d%M%y %{ky}%6c %{kr}%l %{g}]'
EOF

### set permissions
chmod 0600 /root/.ssh/authorized_keys

### fix up selinux context
restorecon -R /root/.ssh/
%end
