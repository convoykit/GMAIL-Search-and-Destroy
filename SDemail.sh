#!/bin/bash
#Author: Kit Keller

#Purpose:
#To solve for sensitive emails that have mistakenly been sent to the incorrect recipients while minimizing risk of collateral damage.

#Constraints:
#Should be a user-friendly command-line interface or script
#Should display a prompt with message header ID and user(s) targeted
#Should call bash commands or be a bash script

#Exit when error detected
set -o errexit
#Exit when piped command fails
set -o pipefail

# checks for gam and offers installation
checkGam (){
	if hash gam; then
		return
	else
		read -r -p "It looks like GAM is not installed, would you like to install it? [y/N] " prompt
		case "$prompt" in
	    	[yY][eE][sS]|[yY]) 
	        	echo "yes"
	        	echo "follow the directions on the launched window and rerun the script"
	        	bash <(curl -s -S -L https://git.io/install-gam)
	        	open "https://github.com/jay0lee/GAM/wiki#creating-a-project"
	        	exit 2
	        	;;
	    	*)
				echo "You chose wrong :("
	        	exit
	        	;;
		esac
	fi

}

#generic prompt that returns input as response
promptUser (){ 
	read -r -p "Are you sure? [y/N] " prompt
	case "$prompt" in
    	[yY][eE][sS]|[yY]) 
        	response="yes"
        	;;
    	*)
        	echo "Please try again"
        	;;
	esac
}

readCommand (){
if [ "$1" == "target" ]; then
	response="no"
	while [[ $response == "no" ]]; do
		printf "What is the user's Convoy email?\n"
		read userName
		echo "What is the messageID of the email\n"
		read messageID
		echo " Is the username:" $userName "and email ID:" $messageID "Correct?"
		promptUser	
		gam user $userName delete messages query rfc822msgid:$messageID doit
	done
	
elif [ "$1" == "csv" ] && [ -f "$2" ]; then
	echo "What is the messageID of the email\n"
	read messageID
	echo " Is the username:" $userName "and email ID:" $messageID "Correct?"
	promptUser
elif [ "$1" == "csv" ] && [ "$2" -eq 0 ]; then
	echo "Please supply the csv as a parameter. Type $0 csv --help to learn more"
elif [ "$1" == "nuke" ]; then
	echo "What is the messageID of the email\n"
	read messageID
	echo "Are you sure the email ID is:" $messageID" and that you want to delete it across the doamin?"
	promptUser
else
	echo "I don't know how to interpret that buddy"
	echo "Type --help for a list of commands"
fi
}

getHelp (){
# Help  
#if [ ${#@} -ne 0 ] && [ "${@#"--help"}" = "" ]; then
if  [ ${#@} -ne 0 ] && [ "$1" == "target" ]; then
  printf -- '
You can specify a user using the command "target"
It will run the following gam command:
gam user $(user) delete messages query rfc822msgid:$(MESSAGEIDHERE) doit'


elif  [ ${#@} -ne 0 ] && [ "$1" == "csv" ]; then
  printf -- '
If you have a list of users, consider running "csv"
It will run the following gam command using after specifying the path of a provided CSV:
gam csv $(file) gam user ~Email delete messages query rfc822msgid:$(MESSAGEIDHERE) doit'


elif  [ ${#@} -ne 0 ] && [ "$1" == "nuke" ]; then
  printf -- '
You can target all inboxes of users across the domain using "nuke"
It will run the following gam command:
gam all users delete messages query rfc822msgid:$(MESSAGEIDHERE) doit

This example will delete the message that has this exact RFC822 Message ID header for all users. 
Only one message at most will be deleted for all users (they should have only one copy). 
This is useful if an email is sent to a large number of people but is slow to complete.'

elif  [ ${#@} -ne 0 ] && [ "$1" == "search" ]; then
  echo 
  echo "In order to delete emails from a user's inbox or all inboxes in the domanin, you should reference the Message ID of the email."
  echo "You must be an administrator with audit log access or have the recipient provide the message ID from the email header." 
  echo
  read -n 1 -s -r -p "Press any key to launch the knowledgebase article"
  open "https://support.google.com/a/answer/2618874?hl=en"
else
  echo "I don't know how to interpret that buddy"
  echo "Type --help for a list of valid commands"
  exit 1;

fi
}


if [ ${#@} -eq 1 ] && [ "${@#"--help"}" = "" ]; then
  printf -- '
	Commands:
		target   Specify a single user inbox to delete an email from
		csv      Delete emails from multiple user inboxes via csv
		nuke     Delete emails for all users within the domain
		search   Search for an email by its Message ID or by its Subject'


	printf '\n\n%s\n\n' "Run  "${0##*/}" COMMAND --help for more information on a command."
elif [ ${#@} -gt 1 ] && [ "$2" == "--help" ]; then
	getHelp $1
elif [ ${#@} -lt 1 ]; then
	echo "Type --help for a list of commands"
	#echo "$0 ${@#}"
	#readCommand "$0 ${@#}"
else
	checkGam
	readCommand $1 $2
fi
