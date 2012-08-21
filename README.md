Packaging

This is a repository for packaging artifacts for Puppet Labs software.
The goal is to abstract and automate packaging processes beyond individual
software projects to a level where this repo can be cloned inside any
project and used to build Debian and Redhat packages.

It expects the following directory structure in the project
*   ext/{debian,redhat,osx}

each of which contains templated erb files using the instance variables
specified in the setupvars task. These include a debian changelog, a
redhat spec file, and an osx preflight and plist.

The top level Rakefile in the project should have the following added:
```ruby
Dir['ext/packaging/tasks/**/*'].sort.each { |t| load t }
@build_defaults ||= YAML.load(File.read('ext/build_defaults.yaml'))
begin
  @packaging_url  = @build_defaults['packaging_url']
  @packaging_repo = @build_defaults['packaging_repo']
rescue
  STDERR.puts "Unable to read the packaging repo from ext/build_defaults.yaml"
end


namespace :package do
  desc "Bootstrap packaging automation, e.g. clone into packaging repo"
  task :bootstrap do
    cd 'ext' do
      %x{git clone #{@packaging_url}}
    end
  end

  desc "Remove all cloned packaging automation"
  task :implode do
    rm_rf "ext/#{@packaging_repo}"
  end
end
```

Also in ext should be two files, build_defaults.yaml and project_data.yaml.

This is the sample build_defaults.yaml file from Hiera:
```
---
packaging_url: 'git@github.com:MosesMendoza/packaging --branch=build_support_for_all_basic_packaging'
packaging_repo: 'packaging'
default_cow: 'base-squeeze-i386.cow'
cows: 'base-lucid-amd64.cow base-lucid-i386.cow base-natty-amd64.cow base-natty-i386.cow base-oneiric-amd64.cow base-oneiric-i386.cow base-precise-amd64.cow base-precise-i386.cow base-sid-amd64.cow base-sid-i386.cow base-squeeze-amd64.cow base-squeeze-i386.cow base-testing-amd64.cow base-testing-i386.cow base-wheezy-i386.cow'
pbuild_conf: '~/.pbuilderrc.foss'
packager: 'puppetlabs'
gpg_name: 'info@puppetlabs.com'
gpg_key: '4BD6EC30'
sign_srpm: FALSE
# a space separated list of mock configs
final_mocks: 'pl-5-i386 pl-5-x86_64 pl-6-i386 pl-6-x86_64 fedora-15-i386 fedora-15-x86_64 fedora-16-i386 fedora-16-x86_64 fedora-17-i386 fedora-17-x86_64'
rc_mocks: 'pl-5-i386-dev pl-5-x86_64-dev pl-6-i386-dev pl-6-x86_64-dev fedora-15-i386-dev fedora-15-x86_64-dev fedora-16-i386-dev fedora-16-x86_64-dev fedora-17-i386-dev fedora-17-x86_64-dev'
yum_host: 'burji.puppetlabs.com'
yum_repo_path: '~/repo/'
build_gem: TRUE
```
This is the sample project_data.yaml file:
```
---
project: 'hiera'
author: 'Puppet Labs'
email: 'info@puppetlabs.com'
homepage: 'https://github.com/puppetlabs/hiera'
summary: 'Light weight hierarchical data store'
description: 'A pluggable data store for hierarcical data'
version_file: '/lib/hiera.rb'
# files and gem_files are space separated lists
files: '[A-Z]* ext lib bin spec acceptance_tests'
gem_files: '{bin,lib}/**/* CHANGELOG COPYING README.md LICENSE'
gem_require_path: 'lib'
gem_test_files: 'spec/**/*'
gem_executables: 'hiera'
gem_default_executables: 'hiera'
```
