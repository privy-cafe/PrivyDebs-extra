#!/bin/bash

#
# harbian audit 9/10 or CentOS Hardening
#

#
# 8.1.27 Record Events That Modify configuration files (Scored)
# Author: Samson-W (sccxboy@gmail.com) author add this 
#

set -u # One variable unset, it's over

HARDENING_LEVEL=4

AUDIT_PARAMS='-a always,exit -F path=$(find / -name audisp-remote.conf) -F perm=wa -k config_file_change
-a always,exit -F path=$(find / -name auditd.conf) -F perm=wa -k config_file_change
-a always,exit -F dir=$(find /etc/audit/ -name rules.d) -F perm=wa -k config_file_change
-a always,exit -F path=$(find / -name grub) -F perm=wa -k config_file_change
-a always,exit -F path=$(find / -name fstab) -F perm=wa -k config_file_change
-a always,exit -F path=$(find / -name hosts.deny) -F perm=wa -k config_file_change
-a always,exit -F path=$(find / -name login.defs) -F perm=wa -k config_file_change
-a always,exit -F dir=/etc/pam.d/ -F perm=wa -k config_file_change
-a always,exit -F path=/etc/profile -F perm=wa -k config_file_change
-a always,exit -F dir=/etc/profile.d/ -F perm=wa -k config_file_change
-a always,exit -F dir=/etc/security/ -F perm=wa -k config_file_change
-a always,exit -F dir=/etc/iptables/ -F perm=wa -k config_file_change
-a always,exit -F path=/etc/sysctl.conf -F perm=wa -k config_file_change'

set -e # One error, it's over
FILE='/etc/audit/rules.d/audit.rules'

# This function will be called if the script status is on enabled / audit mode
audit () {
    # define custom IFS and save default one
    d_IFS=$IFS
    c_IFS=$'\n'
    IFS=$c_IFS
    for AUDIT_VALUE in $AUDIT_PARAMS; do
		check_audit_path $AUDIT_VALUE 
		if [ $FNRET -eq 1 ];then
			crit "path is not exsit! Please check file path is exist!"
			continue
		else
        	debug "$AUDIT_VALUE should be in file $FILE"
        	IFS=$d_IFS
        	does_pattern_exist_in_file $FILE "$AUDIT_VALUE"
        	IFS=$c_IFS
        	if [ $FNRET != 0 ]; then
            	crit "$AUDIT_VALUE is not in file $FILE"
        	else
            	ok "$AUDIT_VALUE is present in $FILE"
        	fi
		fi
    done
    IFS=$d_IFS
}

# This function will be called if the script status is on enabled mode
apply () {
    IFS=$'\n'
    for AUDIT_VALUE in $AUDIT_PARAMS; do
		check_audit_path $AUDIT_VALUE 
		if [ $FNRET -eq 1 ];then
			crit "path is not exsit! Please check file path is exist!"
			continue
		else
        	debug "$AUDIT_VALUE should be in file $FILE"
        	does_pattern_exist_in_file $FILE "$AUDIT_VALUE"
        	if [ $FNRET != 0 ]; then
            	warn "$AUDIT_VALUE is not in file $FILE, adding it"
            	add_end_of_file $FILE $AUDIT_VALUE
				check_auditd_is_immutable_mode
        	else
            	ok "$AUDIT_VALUE is present in $FILE"
        	fi
		fi
    done
}

# This function will check config parameters required
check_config() {
    :
}

# Source Root Dir Parameter
if [ -r /etc/default/cis-hardening ]; then
    . /etc/default/cis-hardening
fi
if [ -z "$CIS_ROOT_DIR" ]; then
     echo "There is no /etc/default/cis-hardening file nor cis-hardening directory in current environment."
     echo "Cannot source CIS_ROOT_DIR variable, aborting."
    exit 128
fi

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
if [ -r $CIS_ROOT_DIR/lib/main.sh ]; then
    . $CIS_ROOT_DIR/lib/main.sh
else
    echo "Cannot find main.sh, have you correctly defined your root directory? Current value is $CIS_ROOT_DIR in /etc/default/cis-hardening"
    exit 128
fi
