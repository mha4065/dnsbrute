# dnsbrute

## Requirements
  - Subfinder
  - Assetfinder
  - Shuffledns
  - DNSGen
  - MassDNS
  - Github-Subdomains

## Installation
  1. Add your providers token to this file: `$HOME/.config/subfinder/provider-config.yaml`
  2. Add your github token to top of `dnsbrute.sh` file, in `token`
  3. Run `chmod +x dnsbrute.sh`
  4. `./dnsbrute.sh -d domain.tld -w wordlist.txt`

