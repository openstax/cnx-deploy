(function () {
  'use strict';

  define(function (require) {
    var makeSettings = require('settings/base');

    // The follow properties have been defined with default values in "settings/base":
    //  root, features, titleSuffix, analyticsID, languages, webmaster,
    //  support, terpUrl, defaultLicense, conceptCoach
    // Any new values here will override those default values.

    return makeSettings({
      features: {{ webview_features|default(["conceptCoach"])|to_json }},

      // Hostname and port for the cnx-archive server
      cnxarchive: {
        host: '{{ arclishing_domain }}'
      },

      // Hostname and port for the cnx-authoring server
      cnxauthoring: {
        host: location.hostname
      },

      // Legacy URL
      // URLs are concatenated using the following logic: location.protocol + '//' + legacy + '/' + view.url
      //   Example: 'http:' + '//' + 'cnx.org' + '/' + 'contents'
      // Do not include the protocol or a trailing slash
      legacy: '{{ zope_domain }}',

      // Webmaster E-mail address
      webmaster: '{{ webmaster_email|default("support@openstax.org") }}',

      // Content shortcodes
      shortcodes: {{ content_shortcodes|default({})|to_json }},

      accountProfile: 'https://{{ accounts_domain }}/profile',
      cnxSupport: 'http://openstax.force.com/support?l=en_US&c=Products%3ACNX',

      exerciseUrl: function (itemCode) {
        return 'https://{{ exercises_domain|default("exercises-qa.openstax.org") }}/api/exercises?q=tag:' + itemCode;
      },

      conceptCoach: {
        uuids: {{ concept_coach_webview_settings|default({})|to_json }},
        url: 'https://{{ tutor_domain|default("tutor-qa.openstax.org") }}',
        assetsUrl: 'https://{{ tutor_domain|default("tutor-qa.openstax.org") }}/assets',
        revUrl: 'https://{{ tutor_domain|default("tutor-qa.openstax.org") }}/rev.txt'
      }

    });

  });

})();
