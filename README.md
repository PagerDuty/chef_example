### About This Repository

The contents of this repository complement the [Chef at PagerDuty](https://www.pagerduty.com/blog/chef-at-pagerduty/) article on PagerDuty blog. The article was published in November 2013 and the repository represents our thinking and Chef workflow at the time; it has not been updated since, and does not necessarily reflect our current processes.

### PagerDuty Chef repository layout

This repository mimics PagerDuty chef repo layout.

- site-cookbooks directory stores all our custom cookbooks
- data_bags directory stores all databags except encrypted data bags
- roles directory stores all roles.
- spec directory stores all role & environment specific unit tests. individual cookbook specific unit tests are stored inside site-cookbooks<cookbook name>/spec directories.
- lib directory holds all our general purpose ruby, python & jaba bindings.
  -  lib/plugins stores all our knife plugins (which tend to be thin wrappers around lib/ based ruby objects)

#### Setup
- symlink lib/plugins inside ```HOME/.chef``` or create a ```.chef``` directory inside the current directory, as plugins/
  ```ln -s lib/plugins .chef/plugins```
- install necessary gems using ```bundle install```
- install cookbook dependencies using berkshelf ```bundle exec berks install -p vendor```
- install and configure lxc if you want to run the functional spec


#### Usage
- unit tests can be run using ```bundle exec rake spec```
- take backup of chef server (and publish it in s3)
  ```knife pd chef backup -K -C backup.json.gz```
- restore a chef server
  - Upload all cookbooks, roles, databags from git repo (will also delete all exsiting cookbooks, data bags roles from the server that are already maintained inside the git repo) 
  ```./restore_chef.sh ```
  - Recreate all nodes, clients, databags
  ```knife pd chef restore -f backup.json.gz```

### Testing
#### Unit testing
- write specs against custom resources (this will help during rewrites)
- write specs against resources that comes from community cookbooks, but we use for notifications
- write specs against any regression (permission issues, service auto start issues)
- write specs against attribute overrides via role or environments
- gather shared asserts using ```shared_examples``` so that they can be reused in recipe, roles and environments testing
- do not use memoized runner where fresh convergence is necessary (e.g. asserts against same attribute with diffent values)

#### Functional Testing
- All specs are tested on Fedora 19 with lxc 0.9.2 (lxc rpms are from rawhide), should work on any distro with working lxc 0.9.x
- Functional tests will start chef zero, spawn container, bootstrap it and then run a convergence.
- Use serverspec for basic assertions.
- Use ```knife_commmand``` helper to assert using node attributes against chef-zero (successfull convergence will be reflected in chef server)
- Use ```vm.ssh``` to test using commands (run inside the container)
- Use ``Net::Telnet`` and other ruby libraries to test any network services from putside

Let us know how it went. Happy cooking!

#License and Copyright
Copyright (c) 2014, PagerDuty
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

* Neither the name of [project] nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
