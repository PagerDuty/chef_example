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
- unit tests can be run using ```bundle exec rake spec```

