#!/bin/bash
#RHEL Linux setup script 
##################################################################################################################

checkFiles() {
echo -e "\e[36m##################################################################################################\e[0m"
echo -e "\e[36mPerforming pre-req checks to ensure all files are present for onboarding...\e[0m" 
echo -e "\e[36m##################################################################################################\e[0m"
echo

#check that adl url is accessible for engine
echo -e "\e[36mTesting connection to ADL...\e[0m"
adlURL="https://go.definitionupdates.microsoft.scloud/packages/?ostype=linux"
if ! curl --head --silent --fail "$adlURL" > /dev/null; then
	echo -e "\e[31mUnable to download engine from ${adlURL}. Check network connectivity and try again, exiting...\e[0m"
	echo
    exit 1
else
	echo -e "\e[32mADL url ${adlURL} is reachable!\e[0m"
	echo
fi

#find onboarding zip and unzip
echo -e "\e[36mChecking for zipped onboarding package from Defender XDR Portal...\e[0m"
currentDir=$(pwd)
zipFile=$(find "$currentDir" -maxdepth 1 -name "Gateway*.zip" | head -n 1)
if [ -n "$zipFile" ]; then
	echo -e "\e[32mFound correct onboarding package and unzipped in current location!\e[0m"
	unzip -j "$zipFile"
	echo
else
	echo -e "\e[31mNo onboarding .zip file from portal found in current directory. Make sure to place onboarding package zip file in current directory, exiting...\e[0m"
	echo
	exit 1
fi

#check that zip extracted successfully
echo -e "\e[36mChecking that MicrosoftDefenderATPOnboardingLinuxServer.py file was unzipped and present...\e[0m"
if [[ ! -f MicrosoftDefenderATPOnboardingLinuxServer.py ]]
then
	echo -e "\e[31mOnboarding file [MicrosoftDefenderATPOnboardingLinuxServer.py] NOT found. Check that onboarding zip is in current directory and was extracted, exiting...\e[0m"
	echo
	exit 1
else
	echo -e "\e[32mLinux onboarding file found!\e[0m"
	echo
fi

#make sure Fastpath blob is present
fpName="FpTrustAnchors_Signed.db"
fpPath="$currentDir/$fpName"
echo -e "\e[36mChecking that Fast Path Blob file ${fpName} is present...\e[0m"
if [ -f "$fpPath" ]; then
	echo -e "\e[32mFound required onboarding blob file!\e[0m"
	echo
else
	echo -e "\e[31mMissing required onboarding blob file: '$fpName' ensure it is present in current directory, exiting...\e[0m"
	echo
	exit 1
fi

#check for mdatp_managed.json
managedFile="mdatp_managed.json"
managedPath="$currentDir/$managedFile"
echo -e "\e[36mChecking that ${managedFile} file is present and contains required values...\e[0m"
if [ -f "$managedPath" ]; then
    # Check required JSON values
    if ! grep -q '"pinCertificateThumbs": true' "$managedPath" || \
	   ! grep -q '"pinCertificateThumbs":true' "$managedPath" || \
	   ! grep -q '"manageEngineInPassiveMode": "disabled"' "$managedPath" || \
       ! grep -q '"manageEngineInPassiveMode":"disabled"' "$managedPath"; then
        echo -e "\e[31mMdatp Managed json file missing required values! Please verify file contents, exiting...\e[0m"
		echo
        exit 1
    fi
    echo -e "\e[32mMdatp Managed json file found with correct contents!\e[0m"
    echo
else
	echo -e "\e[31mMdatp Managed json file: '$managedPath' is NOT present! Cannot configure engine, ensure managed json file is present in current directory, exiting...\e[0m"
	echo
    exit 1
fi
}

checkFiles
