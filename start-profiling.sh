captureLog()
{
	pid=$1
	output=$2
	if [[ -z $output ]]; then
		echo "pid is $pid."
		adb logcat | grep -F " $pid " --color=always
	else
		echo "pid is $pid. Start capturing..."
		rogcat -m '\[HT\]'  -f json | grep -F "process\":\"$pid\"" > $output

		# 删除最后一行，因为该行可能不完整
		sed -i '$ d' $output
		
	fi

}


set -- $(getopt -u -o p -l output:,print -- "$@")
while [ -n "$1" ]
do
	case "$1" in
	-p|--print)
		print=true
		;;
	--output)
		output="$2"
		shift
		;;
	-b) param="$2"
		echo "Found the -b option, with parameter value $param"
		shift ;;
	-c) echo "Found the -c option" ;;
	--) shift
	break ;;
	*) echo "$1 is not an option";;
	esac
	shift
done

if [[ $# -gt 0 ]]; then
	fileName=$1;
	shift;
else
	echo "File name is missing"
	exit 1
fi

if [[ "$fileName" == *.dex ]]; then
	# 运行纯Java的dex文件。需要start-class-name
	if [[ $# -gt 0 ]]; then
		startClassName=$1
		shift
	else
		echo "start class name is missing."
		exit 1
	fi

	coreCommand="-Djava.class.path=$fileName /system/bin $startClassName"
	isDex=true
else
	if [[ $# -gt 0 ]]; then
		activityName=$1
		shift
	else
		echo "Activity name is missing."
		exit 1
	fi

	env="CLASSPATH=/system/framework/am.jar"
	coreCommand="/system/bin com.android.commands.am.Am start -S -n $fileName/$activityName"
fi


if [[ $print = true ]]; then
	echo "$env app_process -EnableRWProfiling:true -EnableHeapSizeProfiling:true $coreCommand"
	sleep 1
fi

if [[ $isDex = true ]]; then
	# echo $$ 里的$$在调用时展开，所以如果不用单引号包起来，展开的是当前shell的PID。
	# 同理，sh -c的参数也必须用单引号包起来。
	adb shell 'sh -c '"'"'echo $$; sleep 1; exec app_process -EnableRWProfiling:true -EnableHeapSizeProfiling:true' "$coreCommand"  "'" | {
		IFS= read -r line
		pid=$line
		
		captureLog $pid $output

	}
else
	# 如果是应用，似乎app_process会帮助孵化，但实际的进程ID不是app_process的ID。
	# 虽然am带有-S选项可以结束活动，但后面的pidof可能会抢先报告被结束的活动的pid，所以这个要先把该活动结束掉。
	adb shell am force-stop $fileName
	adb shell "CLASSPATH=/system/framework/am.jar app_process -EnableRWProfiling:true -EnableHeapSizeProfiling:true /system/bin com.android.commands.am.Am start -n $fileName/$activityName" &
	pid=$(adb shell '
	while true; do
		pid=$(pidof '$fileName')
		if [[ -n "$pid" ]]; then
			echo $pid
			break
		fi
	done')

	captureLog $pid $output
fi


