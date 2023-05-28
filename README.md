# DNSBrute

<p align="center">
  <a href="#requirements">Requirements</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#tool-options">Tool options</a> •
  <a href="#license">license</a>
</p>

DNSBrute is a powerful Bash script to brute force DNS and obtain hidden subdomains of a target.

## Requirements
  - Subfinder
  - Shuffledns + MassDNS
  - DNSGen
  - Anew

## Installation
  1. `git clone https://github.com/mha4065/dnsbrute.git`
  2. `chmod +x dnsbrute.sh`

## Usage

### Basic Usage
`./dnsbrute -d domain.tld`

### Tool Options
- `-i` : Adding non-resolved subdomains along with resolved subdomains as input to DNSGen
- `-c` : Specify a list of Subdomains
- `-r` : Specify a list of resolvers
- `-s` : Run the script silently and do not display any output
- `-o` : Write output to a file instead of the terminal

### Note
- If you have a list of subdomains, you can give your subdomains file to the tool with `-c`.
- If your target has a small scope, I recommend to use `-i` so that after the initial name resolution by ShuffleDNS, the unresolved subdomains are also given as input to DNSGen.
- If you do not give a subdomain file to the tool, the tool will subdomain enumeration automatically.

## License
This project is licensed under the MIT license. See the LICENSE file for details.
