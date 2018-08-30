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

      // Hostname and port for the OpenStax CMS server
      openstaxcms: {
        host: '{{ cms_domain }}',
        port: 443
      },

      // Hostname and port for the OpenStax Exercises server
      exercises: {
        host: '{{ exercises_domain }}',
        port: 443
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
      webmaster: 'support@openstax.org',

      // Donate E-mail address
      donation: 'openstaxgiving@rice.edu',

      // Content shortcodes
      shortcodes: {
      },

      accountProfile: 'https://{{ accounts_domain }}/profile',
      cnxSupport: 'https://openstax.secure.force.com/help',

      defaultLicense: {
        code: 'by'
      }
    };

  });

})();
