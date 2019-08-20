# Development

1. set up a [virtualenv](https://virtualenv.readthedocs.org/en/latest/) and activate it
1. `pip install -r requirements.txt`
1. `python do.py --help`
1. `python do.py update-rex-redirects openstax.org`


Then, check `environments/<environment>/files/etc/nginx/uri-maps/rex-uris.map` for changes.
