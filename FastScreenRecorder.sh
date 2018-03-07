#!/bin/bash 

# xwininfo | grep -e Width -e Height -e Absolute

if ! type ffmpeg > /dev/null; then
  whiptail --title "Error!" --msgbox "ffmpeg not installed, please install ffmpeg package" 10 60
  exit 0
fi

DISPLAY=$(echo $DISPLAY)

mkdir -p ~/FastScreenRecorder/
output_directory="~/FastScreenRecorder"
now=`date +'%Y_%m_%d_%H_%M_%S'`
all_resolution=$(xdpyinfo  | grep 'dimensions:' | awk '{print $2}')
monitors=$(xrandr  | grep "*" | awk '{print $1}')

counter=0
for monitor in $monitors
do
	resolution[counter]=$monitor
	height[counter]=`echo $monitor | cut -d \x -f 1`
	width[counter]=`echo $monitor | cut -d \x -f 2`
	let counter+=1
done

all_monitors=${#resolution[@]}
CMD=""
counter=1
for monitor in ${resolution[@]}
do
	CMD="$CMD \"$counter\" \"monitor $counter($monitor)\" "
	let counter+=1
done
all=$((all_monitors + 1))
CMD="$CMD \"$all\" \"all monitors\""
CMD="whiptail --title \"Plaese Select Option\" --menu \"Choose your option\" 15 60 5 $CMD 3>&1 1>&2 2>&3"
selected_monitor=$(eval $CMD)
exitstatus=$?
if [ $exitstatus != 0 ]; then
	exit 0
fi


file_format=$(whiptail --title "File Format" --inputbox "What is Your Output Format (Exm: mp4,avi,mkv)" 10 60 mkv 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
	exit 0
fi

if [ -s $file_format ]
then
	file_format="mkv"
fi


validate=0
	while [ $validate -eq 0 ]; do
	framerate=$(whiptail --title "framerate" --inputbox "What is Your framerate (10-50)\n$ERROR" 10 60 15 3>&1 1>&2 2>&3)

	if [ -s $framerate ]
	then
		framerate="15"
		validate=1
	elif ! [[ "$framerate" =~ ^[0-9]+$ ]]
	then
		ERROR="\n\nOnly Number Accept"
	elif [ $framerate -lt 10 ] || [ $framerate -gt 50 ]
	then
		ERROR="\n\nInvalid Frame Rate"
	else
		validate=1
	fi
done


CHOICE=$(whiptail --title "Check list example" --separate-output --checklist \
"Choose config options" 10 55 4 \
"MICROPHONE" " |Record sound from microphone " ON \
3>&2 2>&1 1>&3 )

if [[ $CHOICE =~ "MICROPHONE" ]]; then
	RECORD_SOUND="-f pulse -ac 2 -i default"
else
	RECORD_SOUND=""
fi


if [ $selected_monitor -eq $all ]
then
	#Full Display
	echo "nohup ffmpeg -y $RECORD_SOUND -f x11grab -framerate $framerate -video_size $all_resolution -i $DISPLAY.0+0,0 -c:v libx264 -pix_fmt yuv420p -qp 0 -preset ultrafast $output_directory/FastScreenRecorder_$now.$file_format > /dev/null 2>&1 &"
else
	#Selected Monitor
	counter=0
	sum_resolution=0
	selected=$((selected_monitor - 1))
	for monitor_height in ${height[@]}
	do
		if [ $counter -lt $selected ]
		then
			sum_resolution=$((sum_resolution + $monitor_height))
		fi
		let counter+=1
	done
	echo "nohup ffmpeg -y $RECORD_SOUND -f x11grab -framerate $framerate -video_size ${resolution[selected]} -i $DISPLAY.0+$sum_resolution,0 -c:v libx264 -pix_fmt yuv420p -qp 0 -preset ultrafast $output_directory/FastScreenRecorder_$now.$file_format > /dev/null 2>&1 &"
fi


while [[ true ]]; do
	if (whiptail --title "Recording" --yesno "Are you sure to stop recording?" 10 60) then
		eval "pkill ffmpeg"
		echo "Captured Video on $output_directory/FastScreenRecorder_$now.$file_format"
    	exit 0
    fi
done