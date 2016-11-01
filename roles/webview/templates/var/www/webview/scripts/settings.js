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
      cnxSupport: 'http://openstax.force.com/support?l=en_US&c=Products%3ACNX',
      terpUrl: function (itemCode) {
        return 'https://openstaxtutor.org/terp/' + itemCode + '/quiz_start';
      },

      exerciseUrl: function (itemCode) {
        return 'https://{{ exercises_domain|default("exercises-qa.openstax.org") }}/api/exercises?q=tag:' + itemCode;
      },

      defaultLicense: {
        code: 'by'
      },

      conceptCoach: {
        uuids: {{ concept_coach_webview_settings|default({})|to_json }},
        url: 'https://{{ tutor_domain|default("tutor-qa.openstax.org") }}'
      }

    };

  });

})();
