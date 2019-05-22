pid=120
adb shell "sh -c 'echo $$; echo hello; exec app_process -Djava.class.path=/sdcard/Hello.dex -EnableRWProfiling:true -EnableHeapSizeProfiling:true /sdcard/ Hello '" | {
  while IFS= read -r line
  do
		pid=$line
		echo "pid is $pid"
		break
  done
}
echo "pid is $pid"


