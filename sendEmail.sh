#!/bin/bash
#Written by b00st3d 8 Mar 2024.  This script is to be used only in YOUR OWN controlled environment.  Any use of this script is ***AT YOUR OWN RISK***.
#Do the research and understand what this script is doing (it just uses cURL). This was designed to highlight the risk to your network and users.
die () {
	echo >&2 "$0"
	exit 1
}

########DEFAULT SETTINGS########
subject="Notice"			#Subject for your email

server="mailserver.example.com"		#IP, DNS or Hostname of your local mail server. Shouldn't require authentication.

port=25					#Port 25 is the default smtp port.

emailFile="./mail.txt"			#Write your email in a text file. It will use standard html formating.

userFile=""				#Set this value to the file containing email addresses.

toName="Email User"			#Friendly name

toAddress="user@example.com"		#Email address note: if this is set, userFile will be unset.

fromName="no-reply"			#Friendly name

fromAddress="no-reply@example.com"	#Email address

redFlag=false				#Email appears to come from the destination eg. to: me@email.com from: me@email.com
					#This *SHOULD* be a red flag for the recievers. We'll see...
########No Touchy below here########
message=`cat $emailFile`
function showSettings () {
	echo "Server:		$server"
	echo "Port:		$port"
	if ! [[ -z $3 ]]; then
		echo "Sender Name:	$fromName"
	else
		echo "Sender Name:	N/A"
	fi
	if ! [[ -z $4 ]]; then
		echo "Sender Email:	$fromAddress"
	else
		echo "Sender Email:	N/A"
	fi
	if ! [[ -z $5 ]]; then
		echo "Reciever Name:	$toName"
	else
		echo "Reciever Name:	N/A"
	fi
	if ! [[ -z $6 ]]; then
		echo "Reciever Email:	$toAddress"
	else
		echo "Reciever Email:	N/A"
	fi
	if ! [[ -z $7 ]]; then
		echo "User List:	$userFile"
	else
		echo "User List:	N/A"
	fi
	echo "Subject:	$subject"
	echo "Body:		$emailFile"
	echo "RedFlag mode:	$redFlag"
	echo "Email text:"
	echo ""
	echo $message
	echo ""
	read -p "Send the email? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
	echo ""
	
	if [[ -z $userFile ]]; then #If the userfile is undefined, send to single address
		if [[ $redFlag == "true" ]]; then #redflag mode is set so make sender the same as the reciever
			curl --url smtp://$server:$port --mail-from $toAddress --mail-rcpt $toAddress -F '=(;type=multipart/mixed' -F "=$message;type=text/html" -F '=)' -H "Subject: $subject" -H "From: $toName <$toAddress>" -H "To: $toName <$toAddress>"
			echo $toAddress
		else #no redflag mode
			curl --url smtp://$server:$port --mail-from $fromAddress --mail-rcpt $toAddress -F '=(;type=multipart/mixed' -F "=$message;type=text/html" -F '=)' -H "Subject: $subject" -H "From: $fromName <$fromAddress>" -H "To: $toName <$toAddress>"
			echo $toAddress			
		fi
	else #If the userFile is defined, send to the list
		for E in `cat $userFile`
		do
			toName=`echo $E | cut -d '@' -f 1` #set to name to the the first half of the email address
			toAddress=$E
			if [[ $redFlag == "true" ]]; then #redflag mode is set so make sender the same as the reciever
				curl --url smtp://$server:$port --mail-from $toAddress --mail-rcpt $toAddress -F '=(;type=multipart/mixed' -F "=$message;type=text/html" -F '=)' -H "Subject: $subject" -H "From: $toName <$toAddress>" -H "To: $toName <$toAddress>"
				echo $toAddress
			else #no redflag mode
				curl --url smtp://$server:$port --mail-from $fromAddress --mail-rcpt $toAddress -F '=(;type=multipart/mixed' -F "=$message;type=text/html" -F '=)' -H "Subject: $subject" -H "From: $fromName <$fromAddress>" -H "To: $toName <$toAddress>"
				echo $toAddress
			fi
		done
	fi
	exit 1
}

function help () {
	echo ''
	echo 'This script will allow you to send un-encrypted email through your local mail server. For this to work, the server must not require authentication. Default settings are found at the top of the script and the arguments below will over-ride those settings. NOTE: Any argument that has a space needs to be surrounded by "quotes".  This script requires an email typed out in standard HTML in a text document.  By default it looks for this document (mail.txt) in the same directory as the script.'
	echo ''
	echo '-h, --help 				Show this help file'
	echo '-s, --server <server address>		Address of exchange server'
	echo '-p, --port [port]			Defaults to port 25 if no port supplied'
	echo '-F, --from-name ["Friendly Name"]	Friendly name for sender. Leave value blank to omit'
	echo '-f, --from-address <email>		Email Address the message is coming from'
	echo '-T, --to-name ["Friendly Name"]		Friendly name for reciever. Leave value blank to omit'
	echo '-t, --to-address <email>		Email address for reciever'
	echo '-u, --user-file <file>	 		Path to text file containing email addresses'
	echo '-a, --subject <"Text">			Text for the subject'
	echo '-b, --body <file>			Path the the email to be sent. Formatting is standard HTML'
	echo '-x, --red-flag-mode			Makes the email appear to come from the destination email'
	echo '					ie: (to: me@email.com from: me@email.com)'
	echo "					This *SHOULD* be a red flag for the recievers.  We'll see..."
	echo ''
	echo ''
	echo 'Usage: sendEmail -s myserver@example.com -p 123'
	echo 'Usage: sendEmail -s myserver@example.com -T -t target@email.com -a "Email Subject"'
	echo 'Usage: sendEmail -s myserver@example.com -b ~/Desktop/customEmail.txt -u ~/Desktop/userList.txt'
	echo 'Usage: sendEmail -s myserver@example.com --from-name "no-reply" --from-address no-reply@example.com'
	echo ''
	echo 'Usage: ./sendEmail -s mailserver.example.com -F "Mickey Mouse" -f mickey.mouse@gmail.com -t email.user@example.com -a "Oh No!" -b ./mail.txt'
	exit 1
}

########Parse User Input########
while [[ $# -gt 0 ]]; do
	case $1 in
		-h|--help)
			help
			shift
			;;
		-s|--server)
			if [[ $2 == -* || -z $2 ]] then
				echo "Invalid server name provided: $2"
				help
			else
				server=$2
			fi
			shift
			shift
			;;
		-p|--port)
			re='^[0-9]+$'
			if [[ $2 == -* || -z $2 ]] then
				echo "Invalid port provided: $2"
				help
			else
				if ! [[ $2 =~ $re ]] ; then
					echo "Invalid port provided: $2"
					help
				else
					port=$2
				fi
			fi
			shift
			shift
			;;
		-F|--from-name)
			if [[ $2 == -* || -z $2 ]] then
				fromName=""
				shift
			else	
				fromName=$2
				shift
				shift
			fi
			;;
		-f|--from-address)
			if [[ $2 == -* || -z $2 ]] then
				echo "Invalid source address provided: $2"
				help
			else
				fromAddress=$2
			fi
			shift
			shift
			;;
		-T|--to-name)
			if [[ $2 == -* || -z $2 ]] then
				toName=""
				shift
			else
				toName=$2
				shift
				shift
			fi
			;;
		-t|--to-address)
			if [[ $2 == -* || -z $2 ]] then
				echo "Invalid destination address provided: $2"
				help
			else
				toAddress=$2
			fi
			shift
			shift
			;;
		-u|--user-file)
			if [[ $2 == -* || -z $2 ]] then
				echo "Invalid email file provided: $2"
				help
			else
				if [ -f $2 ]; then
					toAddress=""
					userFile=$2
				else
					echo "File not found: $2"
					exit 1
				fi
			fi
			shift
			shift
			;;
		-a|--subject)
			if [[ $2 == -* || -z $2 ]] then
				echo "Invalid subject provided: $2"
				help
			else
				subject=$2
			fi
			shift
			shift
			;;
		-b|--body)
			if [[ $2 == -* || -z $2 ]] then
				echo "Invalid email file provided: $2"
				help
			else
				if [ -f $2 ]; then
					emailFile=$2
				else
					echo "File not found: $2"
					exit 1
				fi
			fi
			shift
			shift
			;;
		-x|--red-flag-mode)
			redFlag=true
			shift
			;;
		-w|--what-if)
			listVars=true
			shift
			;;
		*)
			echo "Unknown option $1"
			help
			;;
	esac
done
########Sanity Checks########
if ! [[ -z $toAddress ]] && ! [[ -z $userFile ]]; then #if both the toAddress and the userFile variables are set there's an issue
	echo "-T and -u can't be used in the same command"
	help
fi
if [[ $redFlag == "true" ]]; then #if we're using red flag mode and a destination address is set go ahead and set a source.
	fromName=$toName
	fromAddress=$toAddress
fi

########Run the commands########
showSettings "$server" "$port" "$fromName" "$fromAddress" "$toName" "$toAddress" "$userFile" "$subject" "$emailFile" "$redFlag"
exit 1
