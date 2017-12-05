
.. Use the following to start a new version entry:

   |version|
   ----------------------

   - feature message

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
