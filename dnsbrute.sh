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

usage() { echo "Usage: ./dnsbrute.sh -d domain.tld [-s subdomain.txt] [-i] [-m massdnsbinary]" 1>&2; exit 1; }

massdns=""

while getopts "d:s:i:m:" flag
do
    case "${flag}" in
        m) massdns="-m $OPTARG";;
        d) domain=${OPTARG#*//};;
        s) subdomain="$OPTARG";;
        i) include_unresolved_subs=true;;
        \? ) usage;;
        : ) usage;;
		*) usage;;
    esac
done


if [[ -z "${domain}" ]]; then
  usage
fi


# Check results/domain is exist or not
#=======================================================================
if [ ! -d "results" ]; then
    mkdir "results"
fi
if [ ! -d "results/$domain" ]; then
    mkdir "results/$domain"
fi
if [ ! -d "results/$domain/dnsbrute" ]; then
    mkdir "results/$domain/dnsbrute"
fi
#=======================================================================



# Check the requirements
#=======================================================================
echo
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
echo -e "${blue}[!]${NC} Checking ${magenta}vampireishere${NC} as a subdomain for ${cyan}$domain${NC} ..."

if dig +short "vampireishere.${domain}" A | grep -q "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$"; then
    echo -e "   ${red}[-]${NC} The $domain resolved to an IP with this subdomain: ${red}vampireishere${NC} :("
    exit
else
    echo -e "   ${green}[+]${NC} No A record found :)"
fi
#=======================================================================


# Donwload and prepare wordlist
#=======================================================================
echo
echo -e "${blue}[!]${NC} Download and prepare wordlist"
curl -s https://wordlists-cdn.assetnote.io/data/manual/best-dns-wordlist.txt > results/$domain/dnsbrute/best-dns-wordlist.txt
curl -s https://wordlists-cdn.assetnote.io/data/manual/2m-subdomains.txt > results/$domain/dnsbrute/2m-subdomains.txt
cat results/$domain/dnsbrute/best-dns-wordlist.txt results/$domain/dnsbrute/2m-subdomains.txt crunch.txt | sort -u > results/$domain/dnsbrute/wordlist.txt
rm results/$domain/dnsbrute/best-dns-wordlist.txt results/$domain/dnsbrute/2m-subdomains.txt
#=======================================================================


# Subdomain enumeration
#=======================================================================
function sub_enumeration() {
    echo
    echo -e "${blue}[!]${NC} Subdomain enumeration :"

    # Subfinder ==========================
    echo -e "   ${green}[+]${NC} Subfinder"
    subfinder -d $domain -all -silent > results/$domain/dnsbrute/subfinder.txt

    # Assetfinder ========================
    echo -e "   ${green}[+]${NC} Assetfinder"
    assetfinder --subs-only $domain > results/$domain/dnsbrute/assetfinder.txt

    # Crt.sh =============================
    echo -e "   ${green}[+]${NC} crt.sh"
    curl -s "https://crt.sh/?q=$domain&output=json" | tr '\0' '\n' | jq -r ".[].common_name,.[].name_value" | sort -u > results/$domain/dnsbrute/crtsh.txt

    # AbuseDB ============================
    echo -e "   ${green}[+]${NC} AbuseDB"
    curl -s "https://www.abuseipdb.com/whois/$domain" -H "User-Agent: Chrome" | grep -E '<li>\w.*</li>' | sed -E 's/<\/?li>//g' | sed -e "s/$/.$domain/" > results/$domain/dnsbrute/abusedb.txt

    # Github subdomains ==================
    echo -e "   ${green}[+]${NC} Github"
    github-subdomains -d $domain -e -o results/$domain/dnsbrute/github.txt -t $token > /dev/null 2>&1

    # Remove duplicates
    cat results/$domain/dnsbrute/subfinder.txt results/$domain/dnsbrute/assetfinder.txt results/$domain/dnsbrute/crtsh.txt results/$domain/dnsbrute/github.txt results/$domain/dnsbrute/abusedb.txt | sort -u > results/$domain/dnsbrute/subdomains.txt
    rm results/$domain/dnsbrute/subfinder.txt results/$domain/dnsbrute/assetfinder.txt results/$domain/dnsbrute/crtsh.txt results/$domain/dnsbrute/github.txt results/$domain/dnsbrute/abusedb.txt 

    echo -e "${blue}[!]${NC} Subdomain enumeration completed :))"
}

#=======================================================================



# Name resolution using ShuffleDNS
# =======================================================================
cat results/$domain/dnsbrute/wordlist.txt | sed -e "s/$/.$domain/" > results/$domain/dnsbrute/temp.txt
if [ -z "$subdomain" ]; then
    sub_enumeration
    cat results/$domain/dnsbrute/subdomains.txt results/$domain/dnsbrute/temp.txt | sort -u > results/$domain/dnsbrute/shuffle_input.txt
else
    cat "$subdomain" results/$domain/dnsbrute/temp.txt | sort -u > results/$domain/dnsbrute/shuffle_input.txt
fi

rm results/$domain/dnsbrute/temp.txt

echo
echo -e "${blue}[!]${NC} Name resolution :"

echo -e "   ${green}[+]${NC} ShuffleDNS"
shuffledns $massdns -d $domain -list results/$domain/dnsbrute/shuffle_input.txt -silent -r resolvers.txt > results/$domain/dnsbrute/resolved1.txt
echo -e "${blue}[!]${NC} Name resolution completed :)"
#=======================================================================


# Download and prepare a wordlist for DNSGen
#=======================================================================
echo
echo -e "${blue}[!]${NC} Download and prepare wordlist for DNSGen"
curl -s https://raw.githubusercontent.com/infosec-au/altdns/master/words.txt > results/$domain/dnsbrute/altwords.txt
curl -s https://raw.githubusercontent.com/ProjectAnte/dnsgen/master/dnsgen/words.txt > results/$domain/dnsbrute/genwords.txt
cat results/$domain/dnsbrute/altwords.txt results/$domain/dnsbrute/genwords.txt > results/$domain/dnsbrute/words.txt
rm results/$domain/dnsbrute/altwords.txt results/$domain/dnsbrute/genwords.txt
#=======================================================================


# Running dnsGen
#=======================================================================
echo
echo -e "${blue}[!]${NC} Generating domain names"

if [ "$include_unresolved_subs" == true ]; then
    cat results/$domain/dnsbrute/subdomains.txt results/$domain/dnsbrute/resolved1.txt | sort -u > results/$domain/dnsbrute/dnsgen_input.txt
else
    mv results/$domain/dnsbrute/resolved1.txt results/$domain/dnsbrute/dnsgen_input.txt
fi

echo -e "   ${green}[+]${NC} DNSGen"
cat results/$domain/dnsbrute/dnsgen_input.txt | dnsgen -w results/$domain/dnsbrute/words.txt - | shuffledns $massdns -d $domain -r resolvers.txt -silent > results/$domain/dnsbrute/resolved2.txt
echo -e "${blue}[!]${NC} DNSGen operation completed :)"
#=======================================================================

# Save diff of resolved 1 and 2
#=======================================================================
echo
echo -e "${blue}[!]${NC} Save unique results..."
comm -2 -3 results/$domain/dnsbrute/resolved2.txt results/$domain/dnsbrute/resolved1.txt | sort -u > results/$domain/dnsbrute/unique_results.txt

# Merging resolved lists
#=======================================================================
echo
echo -e "${blue}[!]${NC} Merging resolved lists ..."
cat results/$domain/dnsbrute/resolved1.txt results/$domain/dnsbrute/resolved2.txt | sort -u > results/$domain/dnsbrute/final_results.txt
rm results/$domain/dnsbrute/shuffle_input.txt results/$domain/dnsbrute/dnsgen_input.txt
echo -e "   ${green}[+]${NC} Everything is finished and the results are saved in ${cyan}results/$domain/dnsbrute/final_results.txt${NC}. Have a good hack :))"
#=======================================================================
