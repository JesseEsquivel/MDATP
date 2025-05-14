#!/bin/bash
checkFiles() {
#find onboarding zip and unzip
currentDir=$(pwd)
zipFile=$(find "$currentDir" -maxdepth 1 -name "Gateway*.zip" | head -n 1)
if [ -n "$zipFile" ]; then
	echo "Found correct onboarding package and unzipped in current location!"
	unzip -j $zipFile
else
	echo "No onboarding .zip file from portal found in current directory. Make sure to place onboarding package zip file in this folder, exiting..."
	exit 2
fi

#check that zip extracted successfully
if [[ ! -f MicrosoftDefenderATPOnboardingLinuxServer.py ]]
then
	printf "%10s%-s\n" "" "Onboarding file [MicrosoftDefenderATPOnboardingLinuxServer.py] NOT found. Check that onboarding zip is in current directory and was extracted! ?"
	exit 2
else
	echo "Linux onboarding file found!"
fi

#make sure Fastpath blob is present
fpName="FpTrustAnchors_Signed.db"
fpPath="$currentDir/$fpName"
if [ -n "$fpPath" ]; then
	echo "Found required onboarding blob!"
else
	echo "Missing required onboarding blob file: '$fpName' ensure it is present in this directory, exiting..."
	exit 2
fi

#check for mdatp_managed.json
managedFile="mdatp_managed.json"
managedPath="$currentDir/$managedFile"
if [ -n "$managedPath" ]; then
	echo "Mdatp Managed json file is present, can configure Engine"
else
	echo "Mdatp Managed json file is NOT present: '$managedPath' cannot configure engine, ensure managed json file is present this directory, exiting..."
	exit 2
fi
}

main() {
	checkFiles
}
