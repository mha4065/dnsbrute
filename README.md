# DNSBrute

<p align="center">
  <a href="#requirements">Requirements</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#tool-options">Tool options</a> •
  <a href="#license">License</a>
</p>

DNSBrute is a powerful Bash script to brute force DNS and obtain hidden subdomains of a target.

## Requirements
  - Subfinder
  - Shuffledns + MassDNS
  - DNSGen
  - Anew

## Installation
  1. `git clone https://github.com/mha4065/dnsbrute.git`
  2. `cd dnsbrute`
  3. `chmod +x dnsbrute`
  4. `sudo mv dnsbrute /usr/local/bin`
  5. `dnsbrute -h`

## Usage

### Basic Usage
`dnsbrute -d domain.tld -w wordlist -r ~/.resolvers`

### Tool Options
- `-d` : Target domain.tld
- `-w` : Specify a wordlist
- `-r` : Specify a list of resolvers
- `-i` : Adding non-resolved subdomains along with resolved subdomains as input to DNSGen
- `-c` : If you have done subdomain enumeration, please enter your subdomains (if you enter subdomains, the script will not do subdomain enumeration)
- `-l` : Specify a wordlist as DNSGen wordlist
- `-s` : To run the script in silent mode
- `-o` : To write output to a file instead of the terminal
- `-h` : To show help message

### Note
- If you have a list of subdomains, you can give your subdomains file to the tool with `-c`.
- If your target has a small scope, I recommend to use `-i` so that after the initial name resolution by ShuffleDNS, the unresolved subdomains are also given as input to DNSGen.
- If you do not give a subdomain file to the tool, the tool will subdomain enumeration automatically.

## License
This project is licensed under the MIT license. See the LICENSE file for details.
