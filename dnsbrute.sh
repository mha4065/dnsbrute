#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
NC='\033[0m'


usage() { echo "Usage: ./dnsbrute.sh -d domain.tld [-c subdomain.txt] [-i] [-r resolvers.txt] [-s] [-o output.txt]" 1>&2; exit 1; }

while getopts "d:c:r:o:si" flag
do
    case "${flag}" in
        d) domain=${OPTARG#*//};;
        c) subdomain="$OPTARG";;
        i) include_unresolved_subs=true;;
        r) resolvers="$OPTARG";;
        o) output="$OPTARG";;
        s) silent=true;;
        \? ) usage;;
        : ) usage;;
	*) usage;;
    esac
done

if [[ -z "${domain}" ]]; then
  usage
fi

if [[ -z "${silent}" ]]; then
	printf "
	      _           _                _         
	   __| |_ __  ___| |__  _ __ _   _| |_ ___   
	  / _\` | '_ \/ __| '_ \| '__| | | | __/ _ \  
	 | (_| | | | \__ \ |_) | |  | |_| | ||  __/  
	  \__,_|_| |_|___/_.__/|_|   \__,_|\__\___|  
		                                     
		      ${cyan}Developed by MHA${NC}             
		         ${yellow}mha4065.com${NC}                 


	"
fi

# Check results/domain is exist or not
#=======================================================================
if [ ! -d "results" ]; then
    mkdir "results"
fi
if [ ! -d "results/$domain" ]; then
    mkdir "results/$domain"
fi
#=======================================================================



# Check the requirements
#=======================================================================
if [[ -z "${silent}" ]]; then
	echo
	echo -e "${blue}[!]${NC} Check the requirements :"
fi

if ! command -v subfinder &> /dev/null
then
    echo -e "   ${red}[-]${NC} subfinder could not be found !"
    exit
fi

if ! command -v anew &> /dev/null
then
    echo -e "   ${red}[-]${NC} Anew could not be found !"
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

if [[ -z "${silent}" ]]; then
	echo -e "   ${green}[+]${NC} All requirements are installed :)"
fi
#=======================================================================


# Check that anysubdomain is resolved to an A record or not
#=======================================================================
if [[ -z "${silent}" ]]; then
	echo
	echo -e "${blue}[!]${NC} Checking ${magenta}vampireishere${NC} as a subdomain for ${cyan}$domain${NC} ..."
fi

if dig +short "vampireishere.${domain}" A | grep -q "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$"; then
    echo -e "   ${red}[-]${NC} The $domain resolved to an IP with this subdomain: ${red}vampireishere${NC} :("
    exit
else
    if [[ -z "${silent}" ]]; then
        echo -e "   ${green}[+]${NC} No A record found :)"
    fi
fi
#=======================================================================


# Donwload and prepare wordlist
#=======================================================================
if [[ -z "${silent}" ]]; then
	echo
	echo -e "${blue}[!]${NC} Download and prepare wordlist"
fi
curl -s https://wordlists-cdn.assetnote.io/data/manual/best-dns-wordlist.txt > results/$domain/best-dns-wordlist.txt
curl -s https://wordlists-cdn.assetnote.io/data/manual/2m-subdomains.txt > results/$domain/2m-subdomains.txt
cat results/$domain/best-dns-wordlist.txt results/$domain/2m-subdomains.txt crunch.txt | sort -u > results/$domain/wordlist.txt
rm results/$domain/best-dns-wordlist.txt results/$domain/2m-subdomains.txt
#=======================================================================


# Subdomain enumeration
#=======================================================================
function subdomain_enum() {
	if [[ -z "${silent}" ]]; then
	    echo
	    echo -e "${blue}[!]${NC} Subdomain enumeration :"
	fi

	# Subfinder ==========================
	if [[ -z "${silent}" ]]; then
		echo -e "   ${green}[+]${NC} Subfinder"
	fi
	subfinder -d $domain -all -silent > results/$domain/subfinder.txt

	# Crt.sh =============================
	if [[ -z "${silent}" ]]; then
	    echo -e "   ${green}[+]${NC} crt.sh"
	fi
	query=$(cat <<-END
		SELECT
			ci.NAME_VALUE
		FROM
			certificate_and_identities ci
		WHERE
			plainto_tsquery('certwatch', '$domain') @@ identities(ci.CERTIFICATE)
		END
	)
	echo "$query" | psql -t -h crt.sh -p 5432 -U guest certwatch | sed 's/ //g' | grep -E ".*.\.$domain" | sed 's/*\.//g' | tr '[:upper:]' '[:lower:]' | sort -u | tee -a results/$domain/crtsh.txt &> /dev/null

	# Github subdomains ==================
	if [[ -z "${silent}" ]]; then
	    echo -e "   ${green}[+]${NC} Github"
	fi
	q=$(echo $domain | sed -e 's/\./\\\./g')
	src search -json '([a-z\-]+)?:?(\/\/)?([a-zA-Z0-9]+[.])+('${q}') count:5000 fork:yes archived:yes' | jq -r '.Results[] | .lineMatches[].preview, .file.path' | grep -oiE '([a-zA-Z0-9]+[.])+('${q}')' | awk '{ print tolower($0) }' | sort -u > results/$domain/github.txt

	# Remove duplicates
	cat results/$domain/subfinder.txt results/$domain/crtsh.txt results/$domain/github.txt | sort -u > results/$domain/subdomains.txt
	rm results/$domain/subfinder.txt results/$domain/crtsh.txt results/$domain/github.txt

	if [[ -z "${silent}" ]]; then
	    echo -e "${blue}[!]${NC} Subdomain enumeration completed :))"
	fi
}
#=======================================================================



# Name resolution using ShuffleDNS
#=======================================================================
#cat results/$domain/wordlist.txt | sed 's/\.domain\.tld//' > results/$domain/temp.txt
if [ -z "$subdomain" ]; then
	subdomain_enum
	cat results/$domain/subdomains.txt | sed 's/\.domain\.tld//' > results/$domain/temp.txt
	cat results/$domain/temp.txt | anew -q results/$domain/wordlist.txt
else
	cat "$subdomain" | sed 's/\.domain\.tld//' > results/$domain/temp.txt
	cat results/$domain/temp.txt | anew -q results/$domain/wordlist.txt
fi

rm results/$domain/temp.txt

if [[ -z "${silent}" ]]; then
	echo
	echo -e "${blue}[!]${NC} Name resolution :"
fi

if [[ -z "${silent}" ]]; then
	echo -e "   ${green}[+]${NC} ShuffleDNS"
fi
if [[ -z "${resolvers}" ]]; then
	shuffledns -d $domain -w results/$domain/wordlist.txt -silent -r resolvers.txt -o results/$domain/resolved1.txt
else
	shuffledns -d $domain -w results/$domain/wordlist.txt -silent -r $resolvers -o results/$domain/resolved1.txt
fi
if [[ -z "${silent}" ]]; then
	echo -e "${blue}[!]${NC} Name resolution completed :)"
fi
#=======================================================================


# Download and prepare a wordlist for DNSGen
#=======================================================================
if [[ -z "${silent}" ]]; then
	echo
	echo -e "${blue}[!]${NC} Download and prepare wordlist for DNSGen"
fi

curl -s https://raw.githubusercontent.com/infosec-au/altdns/master/words.txt > results/$domain/altwords.txt
curl -s https://raw.githubusercontent.com/ProjectAnte/dnsgen/master/dnsgen/words.txt > results/$domain/words.txt
cat results/$domain/altwords.txt | anew -q results/$domain/words.txt
rm results/$domain/altwords.txt
#=======================================================================


# Running dnsGen
#=======================================================================
if [[ -z "${silent}" ]]; then
	echo
	echo -e "${blue}[!]${NC} Generating domain names"
fi

if [ "$include_unresolved_subs" == true ]; then
	if [ -z "$subdomain" ]; then
		cat results/$domain/subdomains.txt | anew -q results/$domain/resolved1.txt
	else
		cat "$subdomain" | anew -q results/$domain/resolved1.txt
	fi
fi

if [[ -z "${silent}" ]]; then
	echo -e "   ${green}[+]${NC} DNSGen"
fi
if [[ -z "${resolvers}" ]]; then
	cat results/$domain/resolved1.txt | dnsgen -w results/$domain/words.txt - | shuffledns -d $domain -r resolvers.txt -silent -o results/$domain/resolved2.txt
else
	cat results/$domain/resolved1.txt | dnsgen -w results/$domain/words.txt - | shuffledns -d $domain -r $resolvers -silent -o results/$domain/resolved2.txt
fi

if [[ -z "${silent}" ]]; then
	echo -e "${blue}[!]${NC} DNSGen operation completed :)"
fi
#=======================================================================


# Merging resolved lists
#=======================================================================
if [[ -z "${silent}" ]]; then
	echo
	echo -e "${blue}[!]${NC} Merging resolved lists ..."
fi
if [[ -z "${output}" ]]; then
	cat results/$domain/resolved1.txt results/$domain/resolved2.txt | sort -u
else
	cat results/$domain/resolved1.txt results/$domain/resolved2.txt | sort -u > results/$domain/$output
	echo -e "${green}[+]${NC} Everything is finished and the results are saved in ${cyan}results/$domain/$output${NC}"
fi
#=======================================================================
