# echo $$ 里的$$在调用时展开，所以如果不用单引号包起来，展开的是当前shell的PID。
# 同理，sh -c的参数也必须用单引号包起来。
adb shell 'sh -c '"'"'echo $$; sleep 1; exec app_process -Djava.class.path=/sdcard/Hello.dex -EnableRWProfiling:true -EnableHeapSizeProfiling:true /sdcard/ Hello '"'" | {
	IFS= read -r line
	pid=$line
	echo "pid is $pid. Start capturing..."

	rogcat -m '\[HT\]'  -f json | grep -F "process\":\"$pid\"" > trace.json
}
