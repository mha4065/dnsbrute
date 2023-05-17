# dnsbrute
dnsbrute is a powerful tool to brute force DNS and obtain hidden subdomains of a target.

## Requirements
  - Subfinder
  - Assetfinder
  - Shuffledns + MassDNS
  - DNSGen
  - Github-Subdomains

## Installation
  1. Add your providers token to this file: `$HOME/.config/subfinder/provider-config.yaml`
  2. Add your github token to top of `dnsbrute.sh` file, in `token`
  3. Run `chmod +x dnsbrute.sh`
  4. `./dnsbrute.sh -d domain.tld [-s subdomain.txt] [-i]`

Note: If you have a list of subdomains, you can give your subdomains file to the tool with `-s`. Also, if your target has a small scope, I recommend to use `-i` so that after the initial name resolution by ShuffleDNS, the unresolved subdomains are also given as input to DNSGen.

Note: If you do not give a subdomain file to the tool, the tool will subdomain enumeration automatically using the best tools.
