set -- $(getopt -u -o '' -l output: -- "$@")
while [ -n "$1" ]
do
	case "$1" in
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
else
	if [[ $# -gt 0 ]]; then
		activityName=$1
		shift
	else
		echo "Activity name is missing."
		exit 1
	fi

	coreCommand="/system/bin com.android.commands.am.Am start -S -n $fileName/$activityName"
fi


echo $coreCommand
#exit

# in $@ 可以省略
# for arg do 
# 	echo '--> '"\`$arg'"
# done

# echo $$ 里的$$在调用时展开，所以如果不用单引号包起来，展开的是当前shell的PID。
# 同理，sh -c的参数也必须用单引号包起来。
adb shell 'sh -c '"'"'echo $$; sleep 1;CLASSPATH=/system/framework/am.jar exec app_process -EnableRWProfiling:true -EnableHeapSizeProfiling:true' "$coreCommand"  "'" | {
	IFS= read -r line
	pid=$line

	if [[ -z $output ]]; then
		echo "pid is $pid."
		adb logcat | grep -F " $pid " --color=always
	else
		echo "pid is $pid. Start capturing..."
		rogcat -m '\[HT\]'  -f json | grep -F "process\":\"$pid\"" > $output
	fi
}
