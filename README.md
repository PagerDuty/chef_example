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

Let us know how it went. Happy cooking

