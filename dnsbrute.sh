#!/bin/bash


token="Your Github Token"


red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
NC='\033[0m'


printf "
      _           _                _         
   __| |_ __  ___| |__  _ __ _   _| |_ ___   
  / _\` | '_ \/ __| '_ \| '__| | | | __/ _ \  
 | (_| | | | \__ \ |_) | |  | |_| | ||  __/  
  \__,_|_| |_|___/_.__/|_|   \__,_|\__\___|  
                                             
              ${cyan}Developed by MHA${NC}             
                 ${yellow}mha4065.com${NC}                 


"

usage() { echo "Usage: ./dnsbrute.sh -d domain.tld -w wordlist.txt" 1>&2; exit 1; }

while getopts "d:w:" flag
do
    case "${flag}" in
        d) domain=${OPTARG#*//};;
        w) wordlist=${OPTARG};;
        \? ) usage;;
        : ) usage;;
		*) usage;;
    esac
done

if [[ -z "${domain}" ]] || [[ -z "${wordlist}" ]]; then
  usage
fi

if [ ! -d "results" ]; then
    mkdir "results"
    if [ ! -d "results/$domain" ]; then
    	mkdir "results/$domain"
    fi
fi




# Check the requirements
#=======================================================================
echo -e "${blue}[!]${NC} Check the requirements :"

if ! command -v subfinder &> /dev/null
then
    echo -e "   ${red}[-]${NC} subfinder could not be found !"
    exit
fi

if ! command -v assetfinder &> /dev/null
then
    echo -e "   ${red}[-]${NC} assetfinder could not be found !"
    exit
fi

if ! command -v github-subdomains &> /dev/null
then
    echo -e "   ${red}[-]${NC} github-subdomains could not be found !"
    exit
fi

if ! command -v shuffledns &> /dev/null
then
    echo -e "   ${red}[-]${NC} shuffledns could not be found :("
    exit
fi

if ! command -v dnsgen &> /dev/null
then
    echo -e "   ${red}[-]${NC} dnsgen could not be found :("
    exit
fi

if ! command -v massdns &> /dev/null
then
    echo -e "   ${red}[-]${NC} massdns could not be found :("
    exit
fi

echo -e "   ${green}[+]${NC} All requirements are installed :)"
#=======================================================================





# Check that anysubdomain is resolved to an A record or not
#=======================================================================
echo
echo -e "${blue}[!]${NC} Checking ${magenta}somethingdoesnotexist${NC} as a subdomain for ${cyan}$domain${NC} ..."

if dig +short "somethingdoesnotexist.${domain}" A | grep -q "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$"; then
	echo -e "   ${red}[-]${NC} The $domain resolved to an IP with this subdomain: ${red}somethingdoesnotexist${NC} :("
	exit
else
	echo -e "   ${green}[+]${NC} No A record found :)"
fi
#=======================================================================






# Subdomain enumeration
#=======================================================================
echo
echo -e "${blue}[!]${NC} Subdomain enumeration :"

# Subfinder ==========================
echo -e "   ${green}[+]${NC} Subfinder"
subfinder -d $domain -all -silent > results/$domain/subfinder.txt

# Assetfinder ========================
echo -e "   ${green}[+]${NC} Assetfinder"
assetfinder --subs-only $domain > results/$domain/assetfinder.txt

# Crt.sh =============================
echo -e "   ${green}[+]${NC} crt.sh"
curl -s "https://crt.sh/?q=$domain&output=json" | tr '\0' '\n' | jq -r ".[].common_name,.[].name_value" | sort -u > results/$domain/crtsh.txt

# AbuseDB ============================
echo -e "   ${green}[+]${NC} AbuseDB"
curl -s "https://www.abuseipdb.com/whois/$domain" -H "User-Agent: Chrome" | grep -E '<li>\w.*</li>' | sed -E 's/<\/?li>//g' | sed -e "s/$/.$domain/" > results/$domain/abusedb.txt

# Github subdomains ==================
echo -e "   ${green}[+]${NC} Github"
github-subdomains -d $domain -e -o results/$domain/github.txt -t $token > /dev/null 2>&1

# Remove duplicates
cat results/$domain/*.txt | sort -u > results/$domain/subdomains.txt
rm results/$domain/subfinder.txt results/$domain/assetfinder.txt results/$domain/crtsh.txt results/$domain/github.txt results/$domain/abusedb.txt 

echo -e "${blue}[!]${NC} Subdomain enumeration completed :))"
#=======================================================================





# Name resolution using ShuffleDNS
#=======================================================================
echo
echo -e "${blue}[!]${NC} Name resolution :"

# Merge subdomains and wordlist ===
cat $wordlist | sed -e "s/$/.$domain/" > results/$domain/temp.txt
cat results/$domain/subdomains.txt results/$domain/temp.txt > results/$domain/shuffle_input.txt
rm results/$domain/temp.txt

echo -e "   ${green}[+]${NC} ShuffleDNS"
shuffledns -d $domain -l results/$domain/shuffle_input.txt -silent -r resolvers.txt > results/$domain/resolved1.txt
echo -e "${blue}[!]${NC} Name resolution completed :)"
#=======================================================================





# Running dnsGen
#=======================================================================
echo
echo -e "${blue}[!]${NC} Generating domain names"

cat results/$domain/subdomains.txt results/$domain/resolved1.txt | sort -u > results/$domain/dnsgen_input.txt

echo -e "   ${green}[+]${NC} DNSGen"
cat results/$domain/dnsgen_input.txt | dnsgen - > results/$domain/dnsgen_output.txt
echo -e "${blue}[!]${NC} DNSGen operation completed :)"
#=======================================================================





# Name resolution using ShuffleDNS again
#=======================================================================
echo
echo -e "${blue}[!]${NC} Name resolution :"

echo -e "   ${green}[+]${NC} ShuffleDNS"
shuffledns -d $domain -l results/$domain/dnsgen_output.txt -r resolvers.txt -silent > results/$domain/resolved2.txt
echo -e "${blue}[!]${NC} Name resolution completed :)"
#=======================================================================





# Merging resolved lists
#=======================================================================
echo
echo -e "${blue}[!]${NC} Merging resolved lists ..."
cat results/$domain/resolved1.txt results/$domain/resolved2.txt | sort -u > results/$domain/final_results.txt
rm results/$domain/resolved1.txt results/$domain/resolved2.txt results/$domain/shuffle_input.txt results/$domain/dnsgen_input.txt results/$domain/dnsgen_output.txt
echo -e "   ${green}[+]${NC} Everything is finished and the results are saved in ${cyan}results/$domain/final_results.txt${NC}. Have a good hack :))"
#=======================================================================