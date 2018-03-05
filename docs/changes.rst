
.. Use the following to start a new version entry:

   |version|
   ----------------------

   - feature message

v2.11.0
-------

  - DRY out webview version pin
  - Fix missing become statement in python3 role
  - Modify python3 role to use python 3.6
  - Remove trailing ',' (comma) because Ansible's yaml parse chokes
  - Update cnx-archive from 3.4.0 to 3.5.0
  - Update cnx-archive from 3.4.0 to 3.5.0
  - Update cnx-easybake from 1.0.0 to 1.1.0
  - update webview for release v0.24.0
  - Update rhaptos.cnxmlutils from 1.3.0 to 1.3.1
  - Update rhaptos.cnxmlutils from 1.3.0 to 1.3.1
  - Add Sentry DSN to the dev environment settings
  - Configured Sentry for Press
  - Update cnx-recipes from 1.4.0 to 1.5.0
  - Add press to the dev and vm environments
  - Refactor libxml dependency to its own role
  - Refactor jre8 into a dependency role
  - Add the Press application
  - added fake google verification files for testing on staging
  - Update cnx-archive from 3.3.0 to 3.4.0
  - Update cnx-archive from 3.3.0 to 3.4.0

v2.10.0
-------
  - robots.txt enviromental overrides
  - dependent libarary updates

v2.9.2
------
  - content0X remove authoring deploy playbook

v2.9.1
------
  - contentXX servers moved to production class
  - add oer.exports version to version.txt

v2.9.0
------
  - hefty.heffalump v0.48.0

v2.8.1
------
  - Hotfix - new authors can now submit collections again
  - deployment fixes - removed restart chron job.

v2.8.0
------
  - backup roles/slim dump
  - improve plone site initalization
  - katalyst01 environment
  - devb environment
  - improved versions.txt

v2.7.0
------
  - run deferred migrations at deploy

v2.6.1
------
  - db access bugfix

v2.6.0
------
  - update OSX packages for release
  - Update pyup.yml to update requirements.yml asap
  - Add varnish_purge_allowed group
  - Fix frontend.yml not able to find authoring IP address
  - Explicitly set index url to https pypi for pip 2.4
  - Allow cache purges from any connected hosts
  - Use delegated facts instead of NOOP to gather facts
  - Remove postgres superuser privileges from db user
  - Replace initialize-repository-db script with commands
  - Add PGHOST env variable when migrating database
  - Change all the database config to use postgresql:// urls
  - Change "include" to "import_tasks" or "import_playbook"
