 #!/bin/bash

###############################Important Note#################################
#please convert or download the csv formart of the google sheet or excel document
#As a pre-requites you should have aws CLI Installed and  aws_config configured for the environment you are running against.
#You can check this link for assistance https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html 
#Replace the original_file(csv format) and output_file path

original_file=/path/{converted from google_sheets}.csv
output_file=/path/temp_output.csv
user_file=/path/workshop_$(date +"%m_%d_%Y").csv

#Adds a new csv column(NR) (also ignore first 2 lines as Header) to the output_file for Wuser assigned number
#Here $6 and $7 are for column 6 and 7, whichg are for email addresss and IP address
#add /32 at the $7 so we have cidr in form of x.x.x.x/32
awk -F "," 'NR>2 {print NR,$6,$7 "/32"}' $original_file | sort | uniq | sed 's/ /,/g; s/,/ /2' > $output_file

##Add security group for the Key Clock instance. Replace the below one with the correct one
#Security group can hold only 60 rules. Please replace the below with SC_ID (sg-055134a455bd792ee,sg-07ba687d8cdf95857) if you need additional users.
#security_group=sg-07ba687d8cdf95857
security_group=sg-089514a966a807076

for line in $(awk -F "," '{print $1,$2,$3}' $output_file | sort | uniq |sed 's/ /,/g')
do
	IFS="," read line_no email ips <<<"$line"        
	echo " these are the IPs :$ips"
	aws ec2 authorize-security-group-ingress --group-id $security_group  --ip-permissions IpProtocol=-1,IpRanges='[{CidrIp='$ips',Description='$email\ "wuser$line_no@workshop.com"'}]' --profile se-sandbox

##  Collect the output for the file below, so we can pass to the users.
    echo "$email,wuser$line_no@workshop.com" >> $user_file
done
