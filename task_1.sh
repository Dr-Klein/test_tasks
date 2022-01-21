#!/bin/bash
RUN_PATH=`pwd`
MY_NAME=`basename "$0"`
MY_USER=`whoami`
LOGFILE="/var/log/timeweb.log";
DESTINATION_PATH="/data/archive";
let "expiration_date = 86400 * 7" # 86400 seconds in 1 days
 
# -----------------------------------------
# ------    Get input parameters  ---------
# -----------------------------------------
for i in "$@"
do
    case $i in

        -target_dir=*)
                PATH_TO_DIR="${i#*=}"
                shift
                ;;
 
        esac
done
# -----------------------------------------
 
# -----------------------------------------
# ------  Check input parameters  ---------
# -----------------------------------------

if [[ -z $PATH_TO_DIR ]]; then
        echo -e "-target_dir parameter is not set. \n 
        Use: ./$MY_NAME -target_dir=<your_path> \n Exiting." && exit
fi

function set_files {
FILES=($(ls -lt "$PATH_TO_DIR" | awk '{print $9}' | tail -n 3))

if [ ${#FILES[*]} -eq 0 ]
then
	echo "In $PATH_TO_DIR not files. Exit, nothing to do.." >> $LOGFILE 2>&1
	exit
fi	
}
# -----------------------------------------

function write_file_info {

echo "------------------------------------------------" >> $LOGFILE 2>&1
echo "Information from ${FILES[i]}:" >> $LOGFILE 2>&1
echo "Current date: `date`" >> $LOGFILE 2>&1
echo "Path: $PATH_TO_DIR/${FILES[i]}" >> $LOGFILE 2>&1
echo "Name: ${FILES[i]}" >> $LOGFILE 2>&1
echo "Volume: $volume" >> $LOGFILE 2>&1	
echo " " >> $LOGFILE 2>&1	
}	

function get_archive_file {

tar -C ${PATH_TO_DIR} -czf ${FILES[i]}.tar.gz ${FILES[i]} >> $LOGFILE 2>&1
mv ${RUN_PATH}/${FILES[i]}.tar.gz ${DESTINATION_PATH} >> $LOGFILE 2>&1
status=$?
	if [ $status -eq 0 ]   
	then
		echo "Move operation for the compressed ${FILES[i]} ended successfully \
in `date`!" >> $LOGFILE 2>&1
		rm ${PATH_TO_DIR}/${FILES[i]}
	else
		echo "Move operation for the compressed ${FILES[i]} ended failed \
in `date`!" >> $LOGFILE 2>&1
	fi	
}	

function manage_cron {

cron_check=$((`crontab -l | grep "$RUN_PATH/$MY_USER" | \
awk '{if ($1 == "20" && $2 == "10" && $3 == "*" && $4 == "*") print $1,$2}' | \
wc -l`));
	
	if [ "$cron_check" -ne "1" ]
	then
		cron_user=$((`ls /var/spool/cron/ | grep $MY_USER | wc -l`))
		if [ "$cron_user" -eq "0" ]
		then
			echo -e '20 10 * * * $RUN_PATH/$MY_NAME' | crontab -
		else
			echo "20 10 * * * $RUN_PATH/$MY_NAME" >> /var/spool/cron/${MY_USER}
		fi
	fi	
}	


function main {

echo "------------------------------------------------" >> $LOGFILE 2>&1
echo "This script was started `date`" >> $LOGFILE 2>&1
echo "------------------------------------------------" >> $LOGFILE 2>&1

set_files
	
	for (( i=0; i < ${#FILES[*]}; i++ ))
		do
			volume=$(ls -lh | grep ${FILES[i]} | awk '{print $5}')
			last_modify=$((`stat -c%Y $PATH_TO_DIR/${FILES[i]}`))
			let "delta_time = $(date +%s) - last_modify"
			if [ $delta_time -lt $expiration_date ]
			then
					write_file_info
					get_archive_file
					manage_cron
			else
			echo "Last file ${FILES[i]} change date for more \
than 7 days, skip." >> $LOGFILE 2>&1
			fi
		done
}
main
exit
