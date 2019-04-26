#!/bin/bash

# 如果任何命令状态码不是0，就停止执行本脚本
set -e


waitForHomeScreen ()
{
	set +e
	x=$(adb wait-for-device shell getprop sys.boot_completed)
	while [ "$x" != "1" ]; do
		sleep 2
		read -t 0.1 -n 1 -s -r -p  $'\rWaiting for home screen. Press any key to stop waiting and continue to executing the following commands.'
		if [[ $? -eq 0 ]]; then
			sleep 2
			break
		fi
		x=$(adb shell getprop sys.boot_completed)
	done
	echo ""
	set -e
}

waitForRecoveryDesktop ()
{
	set +e
	x=$(adb shell getprop twrp.action_complete) # 测试发现当twrp未运行时，此命令返回的是\r\n。
	while [[ "${x/$'\x0d'}" != "0" ]]; do
		sleep 2
		read -t 0.1 -n 1 -s -r -p  $'\rWaiting for recovery mode desktop. Press any key to stop waiting and continue to executing the following commands.'
		if [[ $? -eq 0 ]]; then
			sleep 2
			break
		fi
		x=$(adb shell getprop twrp.action_complete)
	done
	echo ""
	set -e
}
if [[ -z $1 ]]; then
	startStage=1
else
	startStage=$1
fi

if [[ startStage -le 1 ]]; then
	echo "Make user the phone is in fastboot mode. You may use command \`adb reboot bootloader\`"
	read -n 1 -s -r -p "then press any key to continue"
	echo ""
	#Try to only flash system partition, thus don't have to flash TWRP recovery image over and over.

	# 有时候不能很好地运行
	fastboot flash system #if only flash system, the apps are still there.
	fastboot flash userdata
	# After flashing a new image, the phone has to boot to system at least once, then the computer can recognize it in recovery mode.
	fastboot reboot

	waitForHomeScreen

	adb push Magisk-v18.1.zip /sdcard/
	adb push open_gapps-arm64-8.1-mini-20190409.zip /sdcard/
	# Install root manager app
	adb install MagiskManager-v7.1.1.apk
	echo $'\033[33mThe phone is not rooted yet. Open Magisk Manager, it should say Magisk is not Installed.\033[0m'
	echo $'\033[33mAllow USB transfer, make sure the phone storage show up.\033[0m'
	read -n 1 -s -r -p "Press any key to continue"
	echo ""

	adb reboot recovery
fi


if [[ $startStage -le 2 ]]; then
	echo "Waiting for recovery device. If the script doesn't detect, reboot the phone to Android desktop, enable file transfer,"
    echo "make sure the drive show up on your computer. Then reboot to recovery."
	adb wait-for-recovery shell getprop
	waitForRecoveryDesktop

	adb shell twrp install /sdcard/Magisk-v18.1.zip


	# 在TWRP环境
	adb reboot

	waitForHomeScreen

	echo $'\033[33madb shell is going to execute for the first time. Pay attention to Magisk prompt and grant access.'
	echo $'Change Request Timeout to a larger value if you wish.\033[0m'
	read -n 1 -s -r -p "Press any key to continue"
	echo ""
	adb shell su -c date "$(date +%m%d%H%M%Y)" > /dev/null # the command will echo the set time. We don't need this.
	adb shell su -c 'svc bluetooth disable'
	adb shell settings put system accelerometer_rotation 0 #disable auto rotate
	sleep 2

	adb reboot recovery
	adb wait-for-recovery
	waitForRecoveryDesktop
	adb shell twrp install open_gapps-arm64-8.1-mini-20190409.zip
	adb reboot
fi
