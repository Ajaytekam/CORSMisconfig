#!/bin/bash 

##
# Used Tools : httpxm, rush, xargs
##
G='\033[1;32m'
N='\033[0m'

Banner() {
    echo -e "\nUsage: ${0} [Domains_List_File|Domain_Name]"
    echo 
    echo -e "Example Usage : \n"
    echo -e "\t${0} SubDomains.txt"
    echo -e "\t${0} domain.com"
    echo -e "\nResult : Stored on 'CORSMisconfig.txt'"
    exit 0
}

SingleDomainCORSCheck() {
    echo -e "${G}[+]${N} Checking Domain.."   
    Domain=`echo $1 | httpx -follow-redirects -silent -no-color`
    temp=`echo $Domain | cut -d" " -f2`
    if [ "$temp" != "" ]
    then
        targetD=`echo $temp | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/\/$//g' | cut -d? -f1`
    else
        targetD=`echo $Domain | sed -e 's/\/$//g' | cut -d? -f1`
    fi
    echo $targetD | xargs -I{} sh -c 'curl -m5 -s -I -H "Origin: {}.evil.com" {} | [ $(grep -c "evil.com") -gt 0 ] && echo "\033[1;31m[-] {} : Vulnerable to CORS-Misconfiguration \033[0m" || echo "\033[1;32m[+]\033[1;36m {} : \033[1;32mNot-Vulnerable to CORS-Misconfiguration\033[0m"' 2> /dev/null | tee CORSMisconfig.txt 
    echo -e "${G}[+]${N} Test Completed...."    
}

MultiDomainCORSCheck() {
    echo -e "${G}[+]${N} Checking Alive Domains.."   
    cat $1 | httpx -threads 50 -follow-redirects -silent -no-color >> tempDms
    while read line
    do 
        temp=`echo $line | cut -d" " -f2`
        if [ "$temp" != "" ]
        then 
            dat=`echo $temp | sed -e 's/^\[//g' -e 's/\]$//g' -e 's/\/$//g' | cut -d? -f1`
            echo $dat >> DomainList
        else 
            echo $line >> DomainList  
        fi
    done < tempDms
    echo -e "${G}[+]${N} Checking for CORS Misconfiguration.."     
    cat DomainList | rush -j200 'curl -m5 -s -I -H "Origin: {}.evil.com" {} | [ $(grep -c "evil.com") -gt 0 ] && echo -e "\033[1;31m[-] {} - Vulnerable to CORS-Misconfiguration\033[0m" || echo -e "\033[1;32m[+]\033[1;36m {} : \033[1;32mNot-Vulnerable to CORS-Misconfiguration\033[0m"' 2>/dev/null | tee CORSMisconfig.txt
    echo -e "${G}[+]${N} Test Completed...."    
    rm tempDms
    rm DomainList
}

## Main Function Starts Here  
# Check if subdomain file provided
# or single subdomain string
if [ ${#} -eq 1 ]
then
    if [ ! -f $1 ] 
    then
        SingleDomainCORSCheck $1
    else
        MultiDomainCORSCheck $1 
    fi
else 
    Banner
fi
