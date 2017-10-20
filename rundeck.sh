#!/bin/bash

# rundeck deploy script for deploying to qa.cnx.org

# escape special characters in user input
printf -v CNX_QUERY_GRAMMAR_VERSION '%q' "$RD_OPTION_CNX_QUERY_GRAMMAR_VERSION"
printf -v RHAPTOS_CNXMLUTILS_VERSION '%q' "$RD_OPTION_RHAPTOS_CNXMLUTILS_VERSION"
printf -v CNX_EPUB_VERSION '%q' "$RD_OPTION_CNX_EPUB_VERSION"
printf -v CNX_ARCHIVE_VERSION '%q' "$RD_OPTION_CNX_ARCHIVE_VERSION"
printf -v CNX_DB_VERSION '%q' "$RD_OPTION_CNX_DB_VERSION"
printf -v OPENSTAX_ACCOUNTS_VERSION '%q' "$RD_OPTION_OPENSTAX_ACCOUNTS_VERSION"
printf -v CNX_AUTHORING_VERSION '%q' "$RD_OPTION_CNX_AUTHORING_VERSION"
printf -v CSSSELECT2_VERSION '%q' "$RD_OPTION_CSSSELECT2_VERSION"
printf -v CNX_EASYBAKE_VERSION '%q' "$RD_OPTION_CNX_EASYBAKE_VERSION"
printf -v CNX_PUBLISHING_VERSION '%q' "$RD_OPTION_CNX_PUBLISHING_VERSION"
printf -v CNX_RECIPES_VERSION '%q' "$RD_OPTION_CNX_RECIPES_VERSION"
printf -v WEBVIEW_VERSION '%q' "$RD_OPTION_WEBVIEW_VERSION"

if [[ "$WEBVIEW_VERSION" == "''" ]]
then
    WEBVIEW_VERSION=master
fi

extra_vars="cnx_query_grammar_version='${CNX_QUERY_GRAMMAR_VERSION}' "
extra_vars+="rhaptos_cnxmlutils_version='${RHAPTOS_CNXMLUTILS_VERSION}' "
extra_vars+="cnx_epub_version='${CNX_EPUB_VERSION}' "
extra_vars+="cnx_archive_version='${CNX_ARCHIVE_VERSION}' "
extra_vars+="cnx_db_version='${CNX_DB_VERSION}' "
extra_vars+="openstax_accounts_version='${OPENSTAX_ACCOUNTS_VERSION}' "
extra_vars+="cnx_authoring_version='${CNX_AUTHORING_VERSION}' "
extra_vars+="cssselect2_version='${CSSSELECT2_VERSION}' "
extra_vars+="cnx_easybake_version='${CNX_EASYBAKE_VERSION}' "
extra_vars+="cnx_publishing_version='${CNX_PUBLISHING_VERSION}' "
extra_vars+="cnx_recipes_version='${CNX_RECIPES_VERSION}' "
extra_vars+="webview_version='${WEBVIEW_VERSION}'"

set -x
cd /var/cnx-deploy
ansible-playbook -i "environments/qa/inventory" \
                 --vault-password-file=/var/cnx-deploy/.vault/dev \
                 --extra-vars "$extra_vars" main.yml
set +x
