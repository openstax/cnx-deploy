(function () {
  'use strict';

  define(function (require) {
    var languages = require('cs!configs/languages');

    return {
      // Directory from which webview is served
      root: '/',

      // Hostname and port for the cnx-archive server
      cnxarchive: {
        host: '{{ arclishing_domain }}'
      },

      // Hostname and port for the cnx-authoring server
      cnxauthoring: {
        host: location.hostname
      },

      // Prefix to prepend to page titles
      titleSuffix: ' - OpenStax CNX',

      // Google Analytics tracking ID
      analyticsID: 'UA-7903479-1',

      // Supported languages
      languages: languages,

      // Legacy URL
      // URLs are concatenated using the following logic: location.protocol + '//' + legacy + '/' + view.url
      //   Example: 'http:' + '//' + 'cnx.org' + '/' + 'contents'
      // Do not include the protocol or a trailing slash
      legacy: '{{ zope_domain }}',

      // Webmaster E-mail address
      webmaster: 'cnx@cnx.org',

      // Content shortcodes
      shortcodes: {
      },

      accountProfile: 'https://{{ accounts_domain }}/profile',

      terpUrl: function (itemCode) {
        return 'https://openstaxtutor.org/terp/' + itemCode + '/quiz_start';
      },

      exerciseUrl: function (itemCode) {
        // // stub.  Comment out to use local exercises stub.
        // // Copied from https://exercises-dev1.openstax.org/api/exercises?q=tag:k12phys-ch04-s01-lo01
        // return 'http://localhost:8000/data/exercises.json';
        return 'https://exercises-dev1.openstax.org/api/exercises?q=tag:' + itemCode;
      },

      defaultLicense: {
        code: 'by'
      },

      conceptCoach: {
        uuids: {
          'f10533ca-f803-490d-b935-88899941197f': ['exercise'],
          '8QUzyvgD': ['exercise'] // only long-codes are currently supported
        },
        url: 'https://tutor-qa.openstax.org'
      }

    };

  });

})();
