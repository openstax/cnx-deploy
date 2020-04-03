vcl 4.0;

import std;
import directors;

# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.

# IP addresses blocked from performing any requests
acl block {
{% for ip_addr in blocked_ip_addresses|default([]) %}
"{{ ip_addr }}";
{% endfor %}
}

# IP addresses allowed to use the PURGE http verb
acl purge {
    "localhost";
    "127.0.0.1";
{% for host in groups.varnish_purge_allowed %}
    "{{ hostvars[host].ansible_default_ipv4.address }}";
{% endfor %}
}

# Needed for cnx.org/.*/enqueue and *format=rdf for PDFgen
# haproxy load balancing for zope
{% if groups.legacy_frontend %}
backend legacy_frontend {
.host = "{{ hostvars[groups.legacy_frontend[0]].ansible_default_ipv4.address }}";
.port = "{{ haproxy_zcluster_port|default(default_haproxy_zcluster_port) }}";
.connect_timeout = 0.4s;
.first_byte_timeout = 1200s;
.between_bytes_timeout = 600s;
}
{% else %}
{# Not implemented for some environments (e.g. beta) #}
backend legacy_frontend {
.host = "localhost";
.port = "{{ haproxy_zcluster_port|default(default_haproxy_zcluster_port) }}";
.connect_timeout = 0.4s;
.first_byte_timeout = 1200s;
.between_bytes_timeout = 600s;
}
{% endif %}

# static_files (nginx)
backend static_files {
.host = "127.0.0.1";
.port = "8080";
.connect_timeout = 0.4s;
.first_byte_timeout = 60s;
.between_bytes_timeout = 10s;
}

# webview (nginx)
backend webview {
.host = "127.0.0.1";
.port = "8081";
.connect_timeout = 0.4s;
.first_byte_timeout = 600s;
.between_bytes_timeout = 60s;
}

{% if vendor_domain is defined %}
  # vendor (nginx)
backend vendor {
.host = "127.0.0.1";
.port = "{{ vendor_nginx_port }}";
.connect_timeout = 0.4s;
.first_byte_timeout = 600s;
.between_bytes_timeout = 60s;
}
{% endif %}

probe archive_probe {
    .url = "/extras";
    .expected_response = 200;
}

# archive waitress
{% set base_port = archive_base_port|default(default_archive_base_port) %}
{% for host in groups.archive %}
{% for i in range(0, hostvars[host].archive_count|default(1), 1) %}
{% set ip_addr = hostvars[host].ansible_default_ipv4.address %}
{% set name = host.split('.')[0]|replace('-','_') %}
{% set backend_name = '{}_archive{}'.format(name, i) %}
backend {{ backend_name }} {
.host = "{{ ip_addr }}";
.port = "{{ base_port + i }}";
.probe = archive_probe;
.connect_timeout = 0.4s;
.first_byte_timeout = 600s;
.between_bytes_timeout = 60s;
}

{% endfor %}
{% endfor %}

probe publishing_probe {
    .expected_response = 404;
}

# publishing waitress
{% set base_port = publishing_base_port|default(default_publishing_base_port) %}
{% for host in groups.publishing %}
{% for i in range(0, hostvars[host].publishing_count|default(1), 1) %}
{% set ip_addr = hostvars[host].ansible_default_ipv4.address %}
{% set name = host.split('.')[0]|replace('-','_') %}
{% set backend_name = '{}_publishing{}'.format(name, i) %}
backend {{ backend_name }} {
.host = "{{ ip_addr }}";
.port = "{{ base_port + i }}";
.probe = publishing_probe;
.first_byte_timeout = 600s;
.between_bytes_timeout = 60s;
}

{% endfor %}
{% endfor %}

probe press_probe {
    .url = "/ping";
    .expected_response = 200;
}

# press waitress
{% set base_port = press_base_port|default(default_press_base_port) %}
{% for host in groups.press %}
{% for i in range(0, hostvars[host].press_count|default(1), 1) %}
{% set ip_addr = hostvars[host].ansible_default_ipv4.address %}
{% set name = host.split('.')[0]|replace('-','_') %}
{% set backend_name = '{}_press{}'.format(name, i) %}
backend {{ backend_name }} {
.host = "{{ ip_addr }}";
.port = "{{ base_port + i }}";
.probe = press_probe;
.first_byte_timeout = 600s;
.between_bytes_timeout = 60s;
}

{% endfor %}
{% endfor %}

# Any vcl subroutine that does not explicitly return gets the matching code appended from
# https://github.com/varnishcache/varnish-cache/blob/ef8a972bed0cba571f0086c7c6129fcadc667229/bin/varnishd/builtin.vcl

sub vcl_init {
    # Define the archive and resource clusters
    new archive_cluster = directors.round_robin();
    new resource_cluster = directors.round_robin();
{% for host in groups.archive %}
{% for i in range(0, hostvars[host].archive_count|default(1), 1) %}
{% set name = host.split('.')[0]|replace('-','_') %}
{% set backend_name = '{}_archive{}'.format(name, i) %}
    archive_cluster.add_backend({{ backend_name }});
    resource_cluster.add_backend({{ backend_name }});
{% endfor %}
{% endfor %}

    # Define the publishing cluster
    new publishing_cluster = directors.hash();
{% for host in groups.publishing %}
{% for i in range(0, hostvars[host].publishing_count|default(1), 1) %}
{% set name = host.split('.')[0]|replace('-','_') %}
{% set backend_name = '{}_publishing{}'.format(name, i) %}
    publishing_cluster.add_backend({{ backend_name }}, 1.0);
{% endfor %}
{% endfor %}

    # Define the Press cluster
    new press_cluster = directors.hash();
{% for host in groups.press %}
{% for i in range(0, hostvars[host].press_count|default(1), 1) %}
{% set name = host.split('.')[0]|replace('-','_') %}
{% set backend_name = '{}_press{}'.format(name, i) %}
    press_cluster.add_backend({{ backend_name }}, 1.0);
{% endfor %}
{% endfor %}

    # Run builtin vcl_init
}

sub vcl_recv {
    # Block any clients with an ip in the block acl
    if (client.ip ~ block) {
        return (synth(403, "Access denied"));
    }

    # Remove multiple trailing /
    if (req.url ~ "/{2,}$") {
        return (synth(301, req.http.host + regsub(req.url, "/{2,}$", "/")));
    }

    # Check purge ACL based on `req.http.x-forwarded-for` instead of `client.ip`
    # because `client.ip` has the IP address of haproxy.
    # `req.http-x-forwarded-for` sometimes has multiple IP addresses because
    # of redirects within our servers.
    # The first IP is what we want, so remove everything after ",".
    if (req.method == "PURGE" || req.method == "PURGE_REGEXP") {
        if (!std.ip(regsub(req.http.x-forwarded-for, ",.*$", ""), "0.0.0.0") ~ purge) {
            return (synth(405, "Not allowed."));
        }
        elsif (req.method == "PURGE") {
          ban("req.url ~ " + req.url + "$");
          return (synth(200, "Ban added"));
        }
        elsif (req.method == "PURGE_REGEXP") {
          ban("req.url ~ " + req.url);
          return (synth(200, "Regexp ban added"));
        }
    }

    # Routing
    if (req.url ~ "^/ping") {
        set req.backend_hint = webview;
    }
    elsif (req.url ~ "^/api/") {
       set req.backend_hint = press_cluster.backend(req.http.cookie);
       # let the client talk directly to Press,
       # because litezip publishing payloads are huge.
       return (pipe);
    }
{% if accounts_stub|default(False) %}
    # cnx rewrite stub login form
    elsif (req.url ~ "^/stub-login-form") {
        set req.backend_hint = publishing_cluster.backend(req.http.cookie);
    }
{% endif %}
    # cnx rewrite archive
    elsif (req.url ~ "^/a/") {
        set req.backend_hint = publishing_cluster.backend(req.http.cookie);
    }
    elsif (req.url ~ "^/resources/") {
        # Note: Medium-sized static files served directly from waitress
        # We could pipe, but varnish is probably
        # more suitable for serving these files than waitress
        set req.backend_hint = resource_cluster.backend();
    }
    elsif ( req.url ~ "^/exports/") {
        # Webview nginx config serves /exports files from /var/www/files*
        set req.backend_hint = webview;
        return (pass);
    }
    # cnx rewrite archive - specials served from nginx statically
    elsif (req.http.host ~ "^{{ arclishing_domain }}" || req.url ~ "^/sitemap.*.xml" || (req.http.host !~ "^{{ frontend_domain }}"{% if vendor_domain is defined %} && req.http.host !~ "^{{ vendor_domain }}"{% endif %} && req.url ~ "^(/contents|/extras)")) {
        if (req.url  == "/robots.txt" || req.url ~ "^/specials") {
            set req.backend_hint = static_files;
        }
        elsif ( req.method == "POST" || req.method == "PUT" || req.method == "DELETE" || req.url ~ "^/(publications|callback|a|login|logout|moderations|feeds/moderations.rss|contents/.*/(licensors|roles|permissions))") {
            set req.backend_hint = publishing_cluster.backend(req.http.cookie);
        }
        elsif (req.url ~ "^/contents/.*@.*" && req.http.Referer ~ "google") {
            # Don't cache the response, let the request go to vcl_backend_response so that
            # we can redirect to the canonical URL which comes from the archive response
            set req.backend_hint = archive_cluster.backend();
            return (pass);
        }
        else {
            set req.backend_hint = archive_cluster.backend();
        }
    }
    elsif (req.http.host ~ "^{{ frontend_domain }}(:[0-9]+)?$"{% if vendor_domain is defined %} || req.http.host ~ "^{{ vendor_domain }}(:[0-9]+)?$"{% endif %}) {
        # Doing the static file dance
        # Note: Cannot pipe here because we want to be able to handle restarts
        if (req.url ~ "^/pdfs") {
            set req.backend_hint = static_files;
            set req.url = regsub(req.url, "^/pdfs", "/files");
        }
        elsif (req.restarts == 0  && req.url ~ "^/content/.*/enqueue") {
            set req.backend_hint = legacy_frontend;
            return(pass);
        }
        elsif (req.restarts == 0  && req.url ~ "^/content/col.*/?\?format=rdf") {
            set req.backend_hint = legacy_frontend;
        }
        elsif (req.restarts == 0  && req.url ~ "^/content/.*/module_export_template") {
            set req.backend_hint = legacy_frontend;
        }
        elsif (req.restarts == 0  && req.url ~ "^/content/(m[0-9]+)/([0-9.]+)/.*format=pdf$") {
            set req.backend_hint = static_files;
            set req.url = regsub(req.url, "^/content/(m[0-9]+)/([0-9.]+)/.*format=pdf", "/files/\1-\2.pdf");
            return (pass);
        }
        elsif (req.restarts == 1  && req.url ~ "^/files/(m[0-9]+)-([0-9.]+)\.pdf") {
            # Note: Large static files served directly from zope
            set req.backend_hint = legacy_frontend;
            set req.url = regsub(req.url, "^/files/(m[0-9]+)-([0-9.]+)\.pdf", "/content/\1/\2/?format=pdf");
            return (pass);
        }
        elsif (req.url ~ "^/content/((col|m)[0-9]+)/latest/(pdf|epub)$") {
            # Note: Large static files served directly from zope
            set req.backend_hint = legacy_frontend;
            return (pass);
        }
        elsif (req.url ~ "^/content/((col|m)[0-9]+)/([0-9.]+)/(pdf|epub)$") {
            set req.backend_hint = static_files;
            set req.url = regsub(req.url, "^/content/((col|m)[0-9]+)/([0-9.]+)/.*(pdf|epub)", "/files/\1-\3.\4");
            return (pass);
        }
        elsif (req.url ~ "^/content/((col|m)[0-9]+)/([0-9.]+)/(complete|offline)$") {
            set req.backend_hint = static_files;
            set req.url = regsub(req.url, "^/content/((col|m)[0-9]+)/([0-9.]+)/(complete|offline)", "/files/\1-\3.\4.zip");
            return (pass);
        }
        elsif (req.url ~ "^/content/(col[0-9]+)/([0-9.]+)/source$") {
            set req.backend_hint = static_files;
            set req.url = regsub(req.url, "^/content/(col[0-9]+)/([0-9.]+)/source", "/files/\1-\2.xml");
        }
        elsif (req.url ~ "^/content/((col|m)[0-9]+)") {
            set req.backend_hint = archive_cluster.backend();
        }
        # vendor domain webview
        {% if vendor_domain is defined %}
        elsif (req.http.host ~ "^{{ vendor_domain }}(:[0-9]+)?$" && (req.url ~ "_escaped_fragment_=" || req.url ~ "^/$" || req.url ~ "^/?.*" || req.url ~ "^/opensearch\.xml" || req.url ~ "^/version\.txt" || req.url ~ "^/search" || req.url ~ "^/contents$" || req.url ~ "^/(contents|data|exports|styles|fonts|bower_components|node_modules|images|scripts)/" || req.url ~ "^/(about|about-us|people|contents|donate|tos|browse)" || req.url ~ "^/(login|logout|workspace|callback|users|publish|robots.txt)")) {
            set req.backend_hint = vendor;
        }
        {% endif %}  
        # all webview
        elsif (req.url ~ "_escaped_fragment_=" || req.url ~ "^/$" || req.url ~ "^/?.*" || req.url ~ "^/opensearch\.xml" || req.url ~ "^/version\.txt" || req.url ~ "^/search" || req.url ~ "^/contents$" || req.url ~ "^/(contents|data|exports|styles|fonts|bower_components|node_modules|images|scripts)/" || req.url ~ "^/(about|about-us|people|contents|donate|tos|browse)" || req.url ~ "^/(login|logout|workspace|callback|users|publish|robots.txt)") {
            set req.backend_hint = webview;
        }
    }
    else {
        return (synth(301, "https://" + regsub(req.http.host, "^[^:]*", "{{ frontend_domain }}") + req.url));
    }

    # https://github.com/collective/plonesite.de/blob/master/templates/varnish.vcl.in#L87
    # Optimize the Accept-Encoding variant caching
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpe?g|png|gif|swf|pdf|gz|tgz|bz2|tbz|zip|mp3|ogg|mp4|flv)$" ||
            req.url ~ "/image_[^/]*$") {
            unset req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } else {
            unset req.http.Accept-Encoding;
        }
    }

    # This is the builtin vcl_recv but ignores any cookies we don't know about (Google Analytics)
    if (req.method == "PRI") {
        # This will never happen in properly formed traffic (see: RFC7540)
        return (synth(405));
    }
    if (!req.http.host &&
      req.esi_level == 0 &&
      req.proto ~ "^(?i)HTTP/1.1") {
        # In HTTP/1.1, Host is required.
        return (synth(400));
    }
    if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "DELETE" &&
      req.method != "PATCH") {
        # Non-RFC2616 or CONNECT which is weird.
        return (pipe);
    }

    if (req.method != "GET" && req.method != "HEAD") {
        # We only deal with GET and HEAD by default
        return (pass);
    }
    if (req.http.Authorization ||
      req.http.Cookie ~ "(^|.*; )__ac=" ||
      req.http.Cookie ~ "(^|.*; )cosign") {
        # Not cacheable by default
        return (pass);
    }

    # Avoid the builtin vcl_recv, we already handled everything ourselves
    return (hash);
}

sub vcl_backend_response {
    if (beresp.status == 404 && bereq.url ~ "^/files/(m[0-9]+)-([0-9.]+)\.pdf") {
        return(retry);
    }
    # This is separate because we do not want to mark 500 errors as "Hit-For-Pass" for a minute
    elsif (beresp.status >= 500) {
        set beresp.ttl = 0s;
        set beresp.uncacheable = true;
        set beresp.http.X-Varnish-Status = "uncacheable - status code >= 500";
    }
    # Redirect search traffic from archive.cnx.org URLs to the corresponding pages on CNX
    # See: https://github.com/openstax/cnx/issues/209
    elsif (bereq.http.host ~ "archive" && bereq.url ~ "^/contents/.*@.*" && bereq.http.Referer ~ "google") {
      set beresp.http.status = 302;
      set beresp.http.Location = regsub(beresp.http.Link, "^<(https://.*)>.*Canonical.", "\1");
      set beresp.http.X-Varnish-Status = "uncacheable - redirected google";
      set beresp.ttl = 0s;
      # Expose the canonical url as diagnostic information
      set beresp.http.X-Varnish-Canonical-Url = regsub(beresp.http.Link, "^<(https://.*)>.*Canonical.", "\1");
    }
    else {
        # This is (mostly) the builtin vcl_backend_response with added diagnostic information
        if (bereq.uncacheable) {
            set beresp.http.X-Varnish-Status = "uncacheable - pass or hit-for-pass";
        } else {
            # Varnish does not set a TTL for 302 and 307 statuses by default
            # If we see a 302 or 307 status with a TTL <= 0s,
            # we let them fall through to our default override below instead
            if (beresp.ttl <= 0s && beresp.status != 302 && beresp.status != 307) {
                set beresp.http.X-Varnish-Status = "uncacheable - ttl <= 0";
            }
            elsif (beresp.http.Set-Cookie) {
                set beresp.http.X-Varnish-Status = "uncacheable - Set-Cookie in backend response";
            }
            elsif (beresp.http.Surrogate-control ~ "no-store") {
                set beresp.http.X-Varnish-Status = "uncacheable - no-store in Surrogate-control";
            }
            elsif (!beresp.http.Surrogate-Control &&
                   beresp.http.Cache-Control ~ "no-cache|no-store|private") {
                set beresp.http.X-Varnish-Status = "uncacheable - no-cache/no-store/private in Cache-Control";
            }
            elsif (beresp.http.Vary == "*") {
                set beresp.http.X-Varnish-Status = "uncacheable - Vary: * in backend response";
            }
            elsif (bereq.http.Authorization && !beresp.http.Cache-Control ~ "public") {
                set beresp.http.X-Varnish-Status = "uncacheable - Authorization header in request and no public in Cache-Control in backend response";
            }
            # Legacy overrides
            # Needed because we may still serve those from the main cnx.org domain
            elsif (bereq.url ~ "content/[^/]*/[0-9.]*/(\?format=)?pdf$") {
                set beresp.http.X-Varnish-Status = "uncacheable - legacy VersionedPDF";
            }
            elsif (bereq.url ~ "content/[^/]*/latest/(\?format=)?pdf$") {
                set beresp.http.X-Varnish-Status = "uncacheable - legacy LatestPDF";
            }
            elsif (bereq.url ~ "content/[^/]*/[0-9.]*/offline$") {
                set beresp.http.X-Varnish-Status = "uncacheable - legacy VersionedOfflineZip";
            }
            elsif (bereq.url ~ "content/[^/]*/[0-9.]*/complete$") {
                set beresp.http.X-Varnish-Status = "uncacheable - legacy VersionedCompleteZip";
            }

            # Serve stale requests for up to 1 minute longer than the ttl
            # Contact the backend to obtain a fresh response during this time
            set beresp.grace = 60s;

            # Keep old cache entries around for up to a day
            # Used to save some bandwidth communicating with the backend by using ETags
            set beresp.keep = 1d;

            if (beresp.http.X-Varnish-Status ~ "uncacheable") {
                # Mark as "Hit-For-Pass" (remember the uncacheable status) for a minute
                set beresp.ttl = 60s;
                set beresp.uncacheable = true;

                # The following 2 lines are a workaround for
                # https://github.com/varnishcache/varnish-cache/issues/1956
                # Fixed in https://github.com/varnishcache/varnish-cache/pull/1966
                # Remove when upgrading to 4.1.3+ for improved performance on uncacheable requests
                set beresp.grace = 0s;
                set beresp.keep = 0s;
            }
            elsif (beresp.http.Cache-Control) {
                set beresp.http.X-Varnish-Status = "cacheable - Cache-Control in backend response";
            }
            else {
                # These are the settings we use for caching whenever
                # the backend fails to set the Cache-Control header
                set beresp.http.X-Varnish-Status = "cacheable (override) - no Cache-Control in backend response";
                set beresp.ttl = 60s;
                set beresp.http.Cache-Control = "public, max-age=60";
            }
        }
    }

    # Expose the backend and ttl as diagnostic information
    set beresp.http.X-Varnish-Backend = beresp.backend.name;
    set beresp.http.X-Varnish-Ttl = beresp.ttl;

    # Avoid the builtin vcl_backend_response, we already handled everything ourselves
    return (deliver);
}

# https://varnish-cache.org/tips/vcl/redirect.html
# Allows the use of synth(301, url) and synth(302, url)
sub vcl_synth {
    if (resp.status == 301 || resp.status == 302) {
        set resp.http.location = resp.reason;
        set resp.reason = "Moved";
        return (deliver);
    }

    # Run builtin vcl_synth
}

sub vcl_hash {
    # The response to this archive route varies depending on the Accept header
    # This works like a normalized Vary: Accept
    if (req.url ~ "^/contents/" && req.http.Accept ~ "application/xhtml\+xml") {
        hash_data("application/xhtml+xml");
    }

    # Run builtin vcl_hash
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Varnish-Cache = "HIT";
    } else {
        set resp.http.X-Varnish-Cache = "MISS";
    }

    # Run builtin vcl_deliver
}
