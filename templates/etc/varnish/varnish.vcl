vcl 4.0;

import std;

# This configuration uses inline C, so you must run the program with
# the include C parameter: -r vcc_allow_inline_c

# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.
# C{
#         #include <string.h>
#         #include <stdlib.h>
#         #include <time.h>

#         void TIM_format(double t, char *p);
#         double TIM_real(void);
#         time_t TIM_parse(const char *p);
# }C

# TODO restore blocked IP address list, but this needs to be part of configuration.
acl block {
}


# haproxy load balancing for zope
backend backend_0 {
.host = "127.0.0.1";
.port = "8888";
.connect_timeout = 0.4s;
.first_byte_timeout = 1200s;
.between_bytes_timeout = 600s;
}

## mobile
#backend backend_1 {
#.host = "128.42.169.31";
#.port = "5000";
#.connect_timeout = 0.4s;
#.first_byte_timeout = 600s;
#.between_bytes_timeout = 60s;
#}

# static files
backend backend_2 {
.host = "127.0.0.1";
.port = "8080";
.connect_timeout = 0.4s;
.first_byte_timeout = 60s;
.between_bytes_timeout = 10s;
}

backend rewrite_webview {
.host = "127.0.0.1";
.port = "8081";
.connect_timeout = 0.4s;
.first_byte_timeout = 600s;
.between_bytes_timeout = 60s;
}

backend rewrite_resources {
.host = "{{ archive_host }}";
.port = "{{ archive_port }}";
.connect_timeout = 0.4s;
.first_byte_timeout = 600s;
.between_bytes_timeout = 60s;
}

backend rewrite_archive {
.host = "{{ archive_host }}";
.port = "{{ archive_port }}";
.connect_timeout = 0.4s;
.first_byte_timeout = 600s;
.between_bytes_timeout = 60s;
}

backend rewrite_publish {
.host = "{{ publishing_host }}";
.port = "{{ publishing_port }}";
.first_byte_timeout = 1200s;
.between_bytes_timeout = 600s;
}


acl purge {
    "localhost";
    "127.0.0.1";
    # TODO Include IP addresses of other serving hosts.
}

acl nocache {
    "127.0.0.1";
    "10.0.0.0"/8;
}


sub vcl_recv {
    if (req.url == "/join_form") {
        return (synth(403, "Access denied"));
    }

    if (req.method == "POST" && req.url ~ "^/content/[mc]" && req.url !~ "(reuse_edit|(favorites|lens)_add)_inner" && req.url !~ "@@reuse-edit-view" && req.url !~ "lensAdd" && req.url !~ "setPrintedFile" && req.url !~ "updateParameters" && req.url !~ "manage_addProperty" && req.http.referer !~ "manage_propertiesForm") {
        return (synth(403, "Access denied (POST)"));
    }

    if (client.ip ~ block) {
        return (synth(403, "Access denied"));
    }

    # cnx rewrite archive
    if (req.url ~ "^/a/") {
            set req.backend_hint = rewrite_publish;
            return (pass);
        }

    # cnx rewrite archive  - specials served from nginx statically
    if (req.http.host ~ "^{{ arclishing_domain }}" || req.url ~ "^/sitemap.xml") {
        if ( req.method == "POST" || req.method == "PUT" || req.method == "DELETE" || req.url ~ "^/(publications|callback|a|login|logout|moderations|feeds/moderations.rss|contents/.*/(licensors|roles|permissions))") {
            set req.backend_hint = rewrite_publish;
            return (pass);
        }

        elsif (req.url ~ "^/specials") {
            set req.backend_hint = backend_2;
            return (hash);
        }
        else {

        set req.backend_hint = rewrite_archive;
        return (hash);
        }
    }

    # resource images
    if (req.url ~ "^/resources/") {
        set req.backend_hint = rewrite_resources;
        return (hash);
    }


    if (req.url ~ "^/lenses") {
        if (req.http.user-agent ~ "Baiduspider" 
            || req.http.user-agent ~ "ScoutJet"
            || req.http.user-agent ~ "bingbot") {
            return (synth(403, "Access denied"));
        }
    }

    if (req.http.user-agent ~ "equella|360Spider") {
        return (synth(403, "Access denied"));
    }

    # FIXME req.grace cannot be used here, see also
    #       https://www.varnish-cache.org/docs/4.0/users-guide/vcl-grace.html
    # set req.grace = 120s;
    if (req.http.host ~ "^{{ frontend_domain }}(:[0-9]+)?$") {

        /* doing the static file dance */
        if (req.url ~ "^/pdfs") {
            set req.backend_hint = backend_2;
            set req.url = regsub(req.url, "^/pdfs", "/files");
        }
        elsif (req.restarts == 0  && req.url ~ "^/content/.*/enqueue") {
            set req.backend_hint = backend_0;
            return(hash);
        }
        elsif (req.restarts == 0  && req.url ~ "^/content/col.*/?\?format=rdf") {
            set req.backend_hint = backend_0;
            return(hash);
        }
        elsif (req.restarts == 0  && req.url ~ "^/content/.*/module_export_template") {
            set req.backend_hint = backend_0;
            return(hash);
        }
        elsif (req.restarts == 0  && req.url ~ "^/content/(m[0-9]+)/([0-9.]+)/.*format=pdf$") {
            set req.backend_hint = backend_2;
            set req.url = regsub(req.url, "^/content/(m[0-9]+)/([0-9.]+)/.*format=pdf", "/files/\1-\2.pdf");
        }
        elsif (req.restarts == 1  && req.url ~ "^/files/(m[0-9]+)-([0-9.]+)\.pdf") {
            set req.backend_hint = backend_0;
            set req.url = regsub(req.url, "^/files/(m[0-9]+)-([0-9.]+)\.pdf", "/content/\1/\2/?format=pdf");
        }
        elsif (req.url ~ "^/content/((col|m)[0-9]+)/latest/(pdf|epub)$") {
            set req.backend_hint = backend_0;
            return(hash);
        }
        elsif (req.url ~ "^/content/((col|m)[0-9]+)/([0-9.]+)/(pdf|epub)$") {
            set req.backend_hint = backend_2;
            set req.url = regsub(req.url, "^/content/((col|m)[0-9]+)/([0-9.]+)/.*(pdf|epub)", "/files/\1-\3.\4");
        }
        elsif (req.url ~ "^/content/((col|m)[0-9]+)/([0-9.]+)/(complete|offline)$") {
            set req.backend_hint = backend_2;
            set req.url = regsub(req.url, "^/content/((col|m)[0-9]+)/([0-9.]+)/(complete|offline)", "/files/\1-\3.\4.zip");
        }
        elsif (req.url ~ "^/content/(col[0-9]+)/([0-9.]+)/source$") {
            set req.backend_hint = backend_2;
            set req.url = regsub(req.url, "^/content/(col[0-9]+)/([0-9.]+)/source", "/files/\1-\2.xml");
        }
        elsif (req.url ~ "^/content/((col|m)[0-9]+)/(([0-9.]+)|latest)/?") {
            set req.backend_hint = rewrite_archive;
        }
        elsif (req.url ~ "^/content/((col|m)[0-9]+)/(([0-9.]+)|latest)/\?collection=col[0-9]*") {
            set req.backend_hint = rewrite_archive;
        }
        // special cases for legacy
        elsif (req.url ~ "^/images/(advice\.png|example\.png|missing\.eps\.metadata|thick-left-arrow\.png|annot\.png|explanation\.png|question\.png|change\.png|magnify-glass-cnx\.png|rhaptos_powered\.png|comment\.png|missing\.eps|seealso\.png)"
               || req.url ~ "^/scripts/(fileSizeUnits|getUser|selectAllNoneInverse)") {
            set req.backend_hint = backend_0;
        }
        elseif ( req.url ~ "^/aboutus/" ) {
            /*  avoid multiple rewrites on restart */
            if (req.url !~ "VirtualHostBase" ) {
                set req.url = "/VirtualHostBase/https/legacy.cnx.org:443/plone/VirtualHostRoot" + req.url;
            }
            set req.backend_hint = backend_0;
        }
        // all rewrite webview
        elsif (req.url ~ "_escaped_fragment_=" || req.url ~ "^/$" || req.url ~ "^/opensearch\.xml" || req.url ~ "^/search" || req.url ~ "^/contents$" || req.url ~ "^/(contents|data|exports|styles|fonts|bower_components|node_modules|images|scripts)/" || req.url ~ "^/(about|about-us|people|contents|donate|tos)"|| req.url ~ "^/(login|logout|workspace|callback|users|publish)") {
            set req.backend_hint = rewrite_webview;

            if ( req.method == "POST" || req.method == "PUT" || req.method == "DELETE" || req.url ~ "^/users" || req.url ~ "@draft"){
                return (pass);
            }
        }
        // everything else (including 404)
        else {
            set req.http.X-My-Header = "Fallthrough";
            set req.backend_hint = backend_0;
            /*  avoid multiple rewrites on restart */
            if (req.url !~ "VirtualHostBase" ) {
                if  ( req.http.X-Secure ) {
                    set req.url = "/VirtualHostBase/https/cnx.org:443/plone/VirtualHostRoot" + req.url;
                }
                else {
                    set req.url = "/VirtualHostBase/http/cnx.org:80/plone/VirtualHostRoot" + req.url;
                }
            }
        }
    }
    elsif (req.http.host ~ "^passthru") {
        set req.backend_hint = backend_0;
    }
    elsif (req.http.host ~ "^siyavula.cnx.org") {
        set req.url = "/VirtualHostBase/http/siyavula.cnx.org:80/plone/VirtualHostRoot" + req.url;
    }
    elsif (req.http.host ~ "^legacy.cnx.org") {
        /*  avoid multiple rewrites on restart */
        if (req.url !~ "VirtualHostBase" ) {
            if  ( req.http.X-Secure ) {
                set req.url = "/VirtualHostBase/https/legacy.cnx.org:443/plone/VirtualHostRoot" + req.url;
                }
            else {
                set req.url = "/VirtualHostBase/http/legacy.cnx.org:80/plone/VirtualHostRoot" + req.url;
            }
        }
        set req.backend_hint = backend_0;
    }
    else {
        return (synth(750, "Moved Permanently"));
    }
    
    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return (synth(405, client.ip));
        }
        ban("req.url ~ " + req.url + "$");
        return (synth(200, "Ban added"));
    }
   if (req.method == "PURGE_REGEXP") {
        if (!client.ip ~ purge) {
            return (synth(405, "Not allowed."));
        }
        ban("req.url ~ " + req.url);
        return (synth(200, "Regexp ban added"));
    }

    if (req.method != "GET" && req.method != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return(pass);
    }

    if (req.http.If-None-Match) {
        return(pass);
    }

    if (req.url ~ "createObject") {
        return(pass);
    }

    if (req.url ~ "//$") {
        return (synth(700, "Bad URL"));
    }

    call normalize_accept_encoding;
    call annotate_request;
    return(hash);
}

sub vcl_pipe {
    # This is not necessary if you do not do any request rewriting.
    set req.http.connection = "close";
}

sub vcl_hit {
    if (obj.ttl <= 0s) {
        return(pass);
    }
    # if (req.http.X-Force-Refresh == "refresh") {
    #     # Allow client refresh via magic header
    #     # FIXME https://www.varnish-cache.org/docs/4.0/whats-new/upgrading.html#obj-is-now-read-only
    #     # set obj.ttl = 0s;
    #     # FIXME https://www.varnish-cache.org/docs/4.0/whats-new/upgrading.html#backend-restarts-are-now-retry
    #     # return (restart);

    #     # Note, this causes the previously cached object will remain
    #     # until its ttl has expired.
    #     set req.hash_always_miss = true;
    #     return(restart);
    # }
    if (req.http.Cache-Control ~ "no-cache") {
        # like msnbot that send no-cache with every request.
        if (client.ip ~ nocache) {
            # FIXME https://www.varnish-cache.org/docs/4.0/whats-new/upgrading.html#obj-is-now-read-only
            # set obj.ttl = 0s;
            # FIXME https://www.varnish-cache.org/docs/4.0/whats-new/upgrading.html#backend-restarts-are-now-retry
            # return (restart);

            return(restart);
        } 
    }
}

sub vcl_miss {
    if (req.method == "PURGE") {
        return (synth(404, "Not in cache"));
    }

}

sub vcl_backend_response {
    if (beresp.status >= 500) {
        set beresp.ttl = 0s;
    }
    if (bereq.http.X-My-Header ) {
        set beresp.http.X-My-Header = bereq.http.X-My-Header;
    }
    if (beresp.status == 404 && bereq.url ~ "^/files/(m[0-9]+)-([0-9.])+\.pdf") {
        # FIXME https://www.varnish-cache.org/docs/4.0/whats-new/upgrading.html#backend-restarts-are-now-retry
        return(retry);
    }
    if (beresp.status >= 300) {
        if (bereq.url !~ "/content/") {
            set beresp.http.X-Varnish-Action = "FETCH (pass - status > 300, not content)";
            set beresp.uncacheable = true;
            return(deliver);
        }
    }

    set beresp.grace = 120s;
    if (beresp.ttl <= 0s) {
        set beresp.http.X-Varnish-Action = "FETCH (pass - not cacheable)";
        set beresp.uncacheable = true;
        return(deliver);
    }

    if (!beresp.http.Cache-Control ~ "s-maxage=[1-9]" && beresp.http.Cache-Control ~ "(private|no-cache|no-store)") {
        set beresp.http.X-Varnish-Action = "FETCH (pass - response sets private/no-cache/no-store token)";
        set beresp.uncacheable = true;
        return(deliver);
    }
    if (bereq.http.Authorization && !beresp.http.Cache-Control ~ "public") {
        set beresp.http.X-Varnish-Action = "FETCH (pass - authorized and no public cache control)";
        set beresp.uncacheable = true;
        return(deliver);
    }
    if (bereq.http.X-Anonymous && !beresp.http.Cache-Control) {
        set beresp.ttl = 600s;
        set beresp.http.X-Varnish-Action = "FETCH (override - backend not setting cache control)";
    }

    if (bereq.http.host  ~ "^{{ arclishing_domain }}") {
        if (bereq.url ~ "^/contents/") {
            set beresp.ttl = 3600s;
            set beresp.http.X-Varnish-Action = "FETCH (override - archive contents)";
        }
        if (bereq.url ~ "^/extras") {
            set beresp.ttl = 600s;
            set beresp.http.X-Varnish-Action = "FETCH (override - archive extras)";
        }
    }
    if (bereq.url ~ "^/contents/") {
        set beresp.ttl = 7d;
        set beresp.http.X-Varnish-Action = "FETCH (override - archive contents)";
    }

    if (bereq.url ~ "^/resources") {
        set beresp.ttl = 30d;
        set beresp.http.X-Varnish-Action = "FETCH (override - resources)";
    }

    # Default based on %age of Last-Modified, like squid
    if (!beresp.http.Cache-Control && !beresp.http.Expires && !beresp.http.X-Varnish-Action) {
        # FIXME Is the following a valid replacement for this inline C?
        #       Probably not...
        # C{
        #     double factor = 0.2;
        #     double age = 0;
        #     char *lastmod = 0;
        #     time_t lmod;
            
        #     lastmod = VRT_GetHdr(sp, HDR_BERESP, "\016Last-Modified:");
        #     if (lastmod) {
        #         lmod =  TIM_parse(lastmod);
        #         age = TIM_real() - lmod;
        #         VRT_l_beresp_ttl(sp, age*factor);
        #     }
        #  }C

        # This is the attempted replacement, but it fails to compile.
        # set beresp.ttl = std.time(beresp.http.last-modified, now);
        # /FIXME
        set beresp.http.X-FACTOR-TTL = "ttl: " + beresp.ttl;
    }

    if (bereq.url ~ "content/OAI\?verb=List(Identifier|Record)s&metadataPrefix=[^&]*$") {
        set beresp.ttl = 7d; 
        set beresp.http.X-My-Header = "OAI";
    }
    if (bereq.url ~ "content/randomContent") {
        set beresp.uncacheable = true;
        return(deliver);
    }
    if (bereq.url ~ "content/[^/]*/[0-9.]*/(\?format=)?pdf$") {
        set beresp.ttl = 7d; 
        set beresp.http.X-My-Header = "VersionedPDF";
    }
    if (bereq.url ~ "content/[^/]*/latest/(\?format=)?pdf$") {
        set beresp.http.X-My-Header = "LatestPDF";
        set beresp.uncacheable = true;
        return(deliver);
    }
    if (bereq.url ~ "content/[^/]*/[0-9.]*/offline$") {
        set beresp.ttl = 90d; 
        set beresp.http.X-My-Header = "VersionedOfflineZip";
    }
    if (bereq.url ~ "content/[^/]*/[0-9.]*/complete$") {
        set beresp.ttl = 90d; 
        set beresp.http.X-My-Header = "VersionedCompleteZip";
    }
    call rewrite_s_maxage;
    set beresp.http.X-FACTOR-TTL = "ttl: " + beresp.ttl;
    return(deliver);
}

sub vcl_backend_error {
    if (beresp.status == 750) {
        set beresp.http.Location = "http://" + regsub(bereq.http.host, "^[^:]*", "cnx.org") + bereq.url;
        set beresp.status = 301;
        return(deliver);
    } elsif (beresp.status == 700) {
        set beresp.http.Location = bereq.http.host + regsub(bereq.url, "//$", "/");
        set beresp.status = 301;
        return(deliver);
    }
}

sub vcl_deliver {
        if (obj.hits > 0) {
                set resp.http.X-Cache = "HIT";
        } else {
                set resp.http.X-Cache = "MISS";
        }
    call rewrite_age;
}

sub vcl_hash {
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }
    if (req.http.Accept ~ "application/xhtml\+xml" && req.url ~ "^/contents/") {
        hash_data("application/xhtml+xml");
    }
    return (lookup);
}

##########################
#  Helper Subroutines
##########################

# Optimize the Accept-Encoding variant caching
sub normalize_accept_encoding {
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpe?g|png|gif|swf|pdf|gz|tgz|bz2|tbz|zip)$" || req.url ~ "/image_[^/]*$") {
            unset req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } else {
            unset req.http.Accept-Encoding;
        }
    }
}

# Keep auth/anon variants apart if "Vary: X-Anonymous" is in the response
# Also, duplicate logic of content_type_decide, in support of IE8
sub annotate_request {
    # X-Collection
    if (req.http.cookie ~ "(^|.*; )courseURL=") {
        set req.http.X-Collection = regsub(req.http.cookie, "^.*?courseURL=([^;]*);*.*$", "\1");
    }
    if (!(req.http.Authorization || req.http.cookie ~ "(^|.*; )__ac=" || req.http.cookie ~ "(^|.*; )cosign")) {
        set req.http.X-Anonymous = "True";
    }
    if (req.http.Accept ~ "application\/xhtml\+xml") {
        set req.http.X-Content-Type = "application/xhtml+xml";
    } else {
        set req.http.X-Content-Type = "text/html";
    }

}

# The varnish response should always declare itself to be fresh
sub rewrite_age {
    if (resp.http.Age) {
        set resp.http.X-Varnish-Age = resp.http.Age;
        set resp.http.Age = "0";
    }
}

# Rewrite s-maxage to exclude from intermediary proxies
# (to cache *everywhere*, just use 'max-age' token in the response to avoid this override)
sub rewrite_s_maxage {
    if (beresp.http.Cache-Control ~ "s-maxage") {
        set beresp.http.Cache-Control = regsub(beresp.http.Cache-Control, "s-maxage=[0-9]+", "s-maxage=0");
    }
}
