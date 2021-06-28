[![Gem Version](https://badge.fury.io/rb/cocoapods-art.svg)](https://badge.fury.io/rb/cocoapods-art)

# cocoapods-art
A CocoaPods Plugin to work with Artifactory Repository

## Installation
`gem install cocoapods-art`

## Client Configuration
To add an Artifactory repository named 'myRepo' to your client:
```
pod repo-art add artifactory-local http://art-prod.company.com:8081/artifactory/api/pods/myRepo
```

To use 'myRepo' to resolve pods when installing you must add the following to your Podfile:
```ruby
plugin 'cocoapods-art', :sources => [
  '<local_specs_repo_name>'    
] 
```
More than one source can be included, separated by commas.

For authenticated access, please add the user and password to your .netrc file:
```
machine art-prod.company.com
login admin
password password
```
You can also use an encrypted Artifactory password or your API key

If your .netrc file is not located in your home directory, you can specify its location in the environmental variable:
```
export COCOAPODS_ART_NETRC_PATH=$HOME/myproject/.netrc
```

You could set the following environment variable: COCOAPODS_ART_SSL_NO_REOVKE, this will add the flag --ssl-no-revoke to curl command.
If your are running on an environment where access to CRL isn't available you would still be able to access Artifactory via HTTPS using the cocoapods-art plugin on windows.
```
set COCOAPODS_ART_SSL_NO_REOVKE=true
```

## Artifactory Configuration
See the [Artifactory User Guide](https://www.jfrog.com/confluence/display/RTF/CocoaPods+Repositories)

## The cocoapods-art plugin exposes all `pod repo` commands  by using `pod repo-art`:
```
pod repo-art add
pod repo-art lint
pod repo-art list
pod repo-art remove
pod repo-art update
```
## Special notes
Contrary to the default behavior, the cocoapods-art plugin does not implicitly update your sources when actions such as `add` run. 
To update a repo use  `pod repo-art update`

`pod repo-art update` is an accumulative operation, meaning that it does not remove entries which do not exist in the Artifactory backend in order to preserve entries that were created with the `--local-only` flag. To have all such entries removed use the update command with the `--prune` flag.
