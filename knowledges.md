
 - List Open Files for a Process
```bash
lsof -p <pid>
```
 - List Environment Variables for a Process
```bash
ps eww -p <pid>
```
 - How to view logs in Max
```bash
open /Applications/Utilities/Console.app
# or
log stream --predicate 'process = "<process_name>"'
```
 - read binary file: read all string data in it
```bash
strings <binary_file>
```
 - check if an nix-darwin option is applied
```bash
darwin-option --show <option_name>
```
 - inspect flake  
```bash
debug
nix-repl>darwinConfigurations."95hyoukas-MacBook-Air".options.<...>
nix-repl>darwinConfigurations."95hyoukas-MacBook-Air".config.<...>
```
 - `launchctl getenv PATH`