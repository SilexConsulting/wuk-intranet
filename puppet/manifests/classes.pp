class wuk_defaults{
  class {'all_defaults': }
  class {'wuk_groups': } ->
  class {'wuk_users': }
}

class all_defaults {
  class { 'beluga':
    stage => pre,
  }
}

class prod_defaults {
  class {'wuk_defaults': }

  class { 'sudo':
    purge                     => false,
    config_file_replace       => false,
  }

  host {'e02414': # Intranet LAMP 01
    ip => '10.210.100.32'
  }
  host {'e02415': # Intranet LAMP 02
    ip => '10.210.100.33'
  }
  host {'e02416': # Intranet DB 01
    ip => '10.210.73.185'
  }
  host {'e02417': # Intranet DB 02
    ip => '10.210.73.186'
  }
  host {'e03422': # Intranet LAMP Dev/stage
    ip => '10.218.65.13'
  }
  host {'e03423': # Intranet LAMP Test 01
    ip => '10.218.100.11'
  }
  host {'e03424': # Intranet LAMP Test 02
    ip => '10.218.100.12'
  }
  host {'e03425': # Intranet DB Dev/Test 01
    ip => '10.218.65.14'
  }
  host {'e03426': # Intranet DB Dev/Test 01
    ip => '10.218.65.15'
  }
}

class wuk_users {
  beluga::user { 'noels':
    uid => 5003,
    groups => ['admins'],
    ssh_key => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCuc0SV/j8yeDKINo8WOcaxrAbBxZuriZmT2OlXYEbZ3cWyzzevbI+nMcTc9UiivnFmFgTgV75qIlhv3p+dULF7Otu1fvGGFA0EY3ljeOPLqvF5hiqTmXDSvOEI3HQ0H5jiEWMmsFCSnVu5AaXuGKmHeotjQEczyYQmw0C7i8YV+HdnxlaN3A18SwzqfIClwuRDWogF3h3cQlHjXh4Kp68UOUB5LEX1XYP2/2l/dlXp+twJK7r/RI0JkLNLLDXaZjQpOkOVcuamcYemhbiDT4szVRz2SIkWAO/OwnGYOU0Zklv+7DJ1g1Gs8EQtr1l3LA6lv7Ah++kKUVKkUR8OkJlR',
    key_type => 'ssh-rsa',
  }

  beluga::user {'jasonb':
    uid => 5004,
    groups => ['admins'],
    ssh_key => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCoypusMcT0LZTfvyh7DLC/xTPsOnEYS3JOSwP4PFmN5QnwQGO250kkXDQ6UttxfimJbquvZY2MN3jQbwlTwQIY8xap81v13WjxMIHmN4dYd5GVrIGz6fw7uen3N25r53MIVPjL2UiD9D6RYLPYi9D4VifyjHNvd23lHzNIBAQUBQMMD3x15dStpMQpBgxZKmTkFGtvX1sbpXPHn9JIF4WsCQJshd0KE3NpfzMZIsbjP2NNjujHeKxzbgRjR1U2cP8BWGezBk+ZIbvkAFfzqEuedR5t2tQmCEDmSnc3T+JfRl0qoyZWr9y3rQqroaMF0MvgpdzfX4XfKY4UqczZcQzF',
    key_type => 'ssh-rsa'
  }

  beluga::user {'djotto':
    uid     => 5005,
	groups  => ['admins'],
	ssh_key => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCb0oQBfctaYbksZQnZp0MWIGtjJTd4o8tQGM3QJb39w31FiYFmXLo8XNLFnfZU1xr6WH2AeaaGtuPI5feemlzyDF58wHL1OSqETPQVqiSBiAz7WfiRl2Bdztu8yVvAEWWUJNDh9wncToa/dmBoMfq5K518iGoyO79NVU7FpzxCH9lSnL9bLHdC6bKXmuqUZ+lWRkTLVyUO9qt70GY58NohVJC15uUJ2tWA2TPl7PUMRvKL6TPjlosViQ8vBjFzWKO0+key8iWebz4Meu+xWJ9KDuH5ro4hSHOuIOduLARdw8DV6bnvTV4K9zC41dVIromNSj3Zwp0TQxOciC6/cg55',
	key_type => 'ssh-rsa',
  }
}

class wuk_groups {
  group {
    "admins":
    ensure  => present,
    gid     => 7000;
  }
}

class intranet_db {
  $db_pass = hiera("intranet_db::user_password", 'password')
  mysql_user { ["intranet@localhost"]:
    ensure => 'present',
    password_hash => mysql_password($db_pass),
  }
  mysql_grant { ['intranet@localhost/intranet2']:
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['ALL'],
    table      => '*.*',
    user       => ['intranet@localhost'],
  }
 mysql_database { 'intranet2':
      ensure  => 'present',
      charset => 'utf8',
  }
}

# includes SSL-groupintranet.wolseley.com.conf AND /sites/conf/include/groupintranetv2.conf
define groupintranet (
  $docroot,
  $serveradmin,
  $ssl                  = false,
  $serveraliases        = [],
) {
  $port = $ssl ? {
    true  => '443',
    false => '8181',
  }

  apache::vhost {$name:
    serveradmin                 => $serveradmin,
    port                        => $port,
    docroot                     => $docroot,
    ssl                         => $ssl,
    directories                 => [
      {
        path                    => $docroot,
        options                 => ['FollowSymLinks'],
        allow_override          => ['None'],
        php_values              => ["include_path \"${docroot}\"", "session.save_path \"/www/session\""],
        custom_fragment         => 'php_flag session.save_path /www/session
        php_flag zend.ze1_compatibility_mode Off',
      },
      {
        path                    => "${docroot}/vacancies",
        options                 => ['SymLinksIfOwnerMatch'],
        directoryindex          => 'index.php',
        custom_fragment         => 'php_flag zend.ze1_compatibility_mode On',
      }
    ],
    rewrites                    => [
      {
        rewrite_cond            => ['%{REQUEST_URI} ^/vacancies/main.php?'],
        rewrite_rule            => ['^/(.*) main.php?%{QUERY_STRING} [L,R=301]'],
      },
      {
        rewrite_cond            => ['%{REQUEST_URI} ^/vacancies/search.php?'],
        rewrite_rule            => ['^/(.*) search.php?%{QUERY_STRING} [L,R=301]'],
      },
    ],
  }
}

# includes SSL-intranet2.wolseley.co.uk.conf AND "/sites/conf/include/ukintranet2.conf" AND "/sites/conf/include/asp.conf"
define intranet2 (
  $docroot,
  $ssl                  = false,
  $serveraliases        = [],
  $parentroot           = '/sites/intranet2/'
) {
  $port = $ssl ? {
    true  => '443',
    false => '80',
  }
  apache::vhost {$name:
    manage_docroot              => false,
    serveraliases               => $serveraliases,
    port                        => $port,
    serveradmin                 => 'web_admin_ripon@wolseley.co.uk',
    docroot                     => $docroot,
    rewrites                    => [
      {
        rewrite_cond            => ['%{REQUEST_URI} ^/bathstore/_admin(.*)'],
        rewrite_rule            => ['^/(.*) http://www.bathstore.com/__admin$2 [R,L]'],
      },
      {
        rewrite_cond            => ["%{HTTP_HOST} !^${name}$ [NC]", '%{HTTP_HOST} !^$'],
        rewrite_rule            => ["^/(.*) http://${name}/\$1 [R]"]
      },
      {
        rewrite_rule            => ['^/$ /index.php [L,R=301]']
      },
      {
        rewrite_cond            => ['%{REQUEST_METHOD} ^TRAC(E|K)'],
        rewrite_rule            => ['.* - [F]']
      },
    ],
    directories                 => [
      {
        path                    => $parentroot,
        options                 => ['FollowSymLinks'],
        allow_override          => ['All'],
      },
    ],
    custom_fragment             => 'Alias /asp/ "/sites/intranet2/wuk/asp/"
<Directory "/sites/asp" >
  Options FollowSymLinks
  AllowOverride All

  PerlSetVar Global  .
  PerlSetVar GlobalPackage Apache::ASP
  PerlSetVar StateDir  /tmp/asp_demo
  PerlSetVar StatINC 0
  PerlSetVar StatINCMatch 0
  PerlSetVar Clean 0
  PerlSetVar DynamicIncludes 1
  PerlSetVar FileUploadMax 50000
  PerlSetVar FileUploadTemp 1
  PerlSetVar SessionQueryParse 0
  PerlSetVar SessionQuery 1
  PerlSetVar Debug 2
  PerlSetVar StateCache 0
  PerlSetVar SessionCount 1
  PerlSetVar TimeHiRes 1
  PerlSetVar CompressGzip 0
  PerlSetVar UseStrict 0
  PerlSetVar CacheDB DB_File
  PerlSetVar CacheDB MLDBM::Sync::SDBM_File

# .asp files for Session state enabled
<Files ~ (\.asp)>
	SetHandler perl-script
	PerlHandler Apache::ASP
	PerlSetVar CookiePath  /
	PerlSetVar SessionTimeout  5
	PerlSetVar RegisterIncludes 1
	PerlSetVar XMLSubsMatch ?>$
	PerlSetVar AllowApplicationState 1
	PerlSetVar AllowSessionState 1
	PerlSetVar StateSerializer Storable
	PerlSetVar StatScripts 0
</Files>

# .htm files for the ASP parsing, but not the $Session object
# NoState turns off $Session & $Application
<Files ~ (\.htm)>
	SetHandler perl-script
	PerlHandler Apache::ASP
	PerlSetVar NoState 1
	PerlSetVar BufferingOn 1
	PerlSetVar NoCache 1
	PerlSetVar DebugBufferLength 250
</Files>

<Files ~ (\.xml)>
	SetHandler perl-script
	PerlHandler Apache::ASP
	PerlSetVar NoState 1
	PerlSetVar XSLT template.xsl
	PerlSetVar XSLTCache 1
</Files>

<Files ~ (\.inc|\.htaccess)>
	ForceType text/plain
</Files>

# .ssi for full ssi support, with Apache::Filter
<Files ~ (\.ssi)>
	SetHandler perl-script
	PerlHandler Apache::ASP Apache::SSI
	PerlSetVar Global .
	PerlSetVar Filter On
</Files>

<Files ~ (\filter.filter)>
       SetHandler perl-script
       PerlHandler Apache::ASP Apache::ASP
       PerlSetVar Global .
       PerlSetVar Filter On
</Files>

<Files ~ (session_query_parse.asp$)>
	SetHandler perl-script
	PerlHandler Apache::ASP
	PerlSetVar CookiePath  /
	PerlSetVar SessionTimeout  1
	PerlSetVar SessionQueryParseMatch ^http://localhost
</Files>

<Files ~ (xml_subs_strict\.asp)>
	SetHandler perl-script
	PerlHandler Apache::ASP
	PerlSetVar CookiePath  /
	PerlSetVar SessionTimeout  5
	PerlSetVar RegisterIncludes 1
	PerlSetVar XMLSubsMatch my:\w+
	PerlSetVar XMLSubsStrict 1
</Files>

</Directory>'
  }
}

define intranet (
  $docroot              = '/sites/intranet/wuk',
  $serveraliases        = [],
) {
  apache::vhost { $name:
    serveraliases               => $serveraliases,
    port                        => '80',
    serveradmin                 => 'web_admin_ripon@wolseley.co.uk',
    docroot                     => $docroot,
    manage_docroot              => false,
    redirect_status             => 'permanent',
    redirect_source             => '/testarena.html',
    redirect_dest               => "http://${intranet2}/testarena.html",

    proxy_pass                  => [
      {
        'path' => '/login/',
        'url'  => 'http://login.wolseley.co.uk/',
        'reverse_urls' => ['http://login.wolseley.co.uk/']
      },
    ],

    custom_fragment             => "<Proxy http://${name}.wolseley.co.uk/login/*>
Order deny,allow
Allow from all
</Proxy>
SetOutputFilter DEFLATE
DeflateFilterNote ratio
SetEnvIfNoCase Request_URI \\.(?:gif|jpe?g|png)$ no-gzip dont-vary
SetEnvIfNoCase Request_URI \\.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
SetEnvIfNoCase Request_URI \\.pdf$ no-gzip dont-vary
SetEnvIfNoCase Request_URI random_image\\.(?:php)$ no-gzip dont-vary
SetEnvIfNoCase Request_URI random_supplier_image\\.(?:php)$ no-gzip dont-vary",

    directories                 => [
      {
        path                    => $docroot,
        options                 => ['FollowSymLinks'],
        php_values              => ["include_path \".:${docroot}/pipeline/qcodo/wwwroot/includes/:${docroot}/\""],
        rewrites                => [
          {
            comment             => 'Rewrite URLs for old worklog -> new worklog / Strip query string from projects/index.php and forward to /worklog/index.php',
            rewrite_rule        => '^projects/index.php?.+ /worklog/index.php$1? [R=301,L]'
          },
          {
            comment             => 'Any requests for /projects(/) sent to /worklog/',
            rewrite_rule        => '^projects(/)?$ /worklog/ [R=301,L]'
          },
          {
            comment             => 'If project.php is requested, redirect to project_overview with same query string',
            rewrite_rule        => '^projects/project.php(\?[a-z0-9=&]+)? /worklog/project_overview.php$1 [R=301,L]'
          },
          {
            comment             => 'If request.php is request, then serve it!',
            rewrite_rule        => '^projects/request.php /worklog/request.php [R=301,L]'
          },
          {
            comment             => 'Everything else, send to worklog home',
            rewrite_cond        => [
              '$1 download [OR]',
              '$1 logs     [OR]',
              '$1 report   [OR]',
              '$1 users    [OR]',
              '$1 review   [OR]',
              '$1 index'
            ],
            rewrite_rule        => '^projects/(.+)\.php(\?[a-zA-Z0-9=&%]+)?$ /worklog/index.php [R=301,L]'
          },
          {
            comment             => 'Rewrite rules for estimating quotelog',
            rewrite_cond        => ['$1 !^(_|index\.php|images|robots\.txt)'],
            rewrite_rule        => ['^estimating/(.*)$ /estimating/index.php/$1 [L]'],
          },
          {
            comment             => 'Rewrite rules for HR training calendar',
            rewrite_cond        => ['$1 !^(_|index\.php|images|robots\.txt)'],
            rewrite_rule        => ['^training_calendar/(.*)$ /training_calendar/index.php/$1 [L]'],
          },
          {
            comment             => 'Rewrite rules for moderator training calendar',
            rewrite_cond        => ['$1 !^(_|index\.php|images|robots\.txt)'],
            rewrite_rule        => ['^moderator_training/(.*)$ /moderator_training/index.php/$1 [L]'],
          },
          {
            comment             => 'Rewrite rule for Pay & Grading page',
            rewrite_rule        => ['^21220108$ /main.php?id=4610 [L]'],
          },
          {
            comment             => 'Rewrite rule for Flexible working',
            rewrite_rule        => ['^1213140308$ /main.php?id=4671 [L]'],
          },
          {
            comment               => 'Rewrite rule for Pensions',
            rewrite_rule          => ['^pensproc08$ /main.php?id=5227 [L]'],
          },
          {
            comment             => 'Rewrite rule for Ideas for Rob',
            rewrite_rule        => ['^ideasforrob$ /main.php?id=5492 [L]'],
          },
          {
            comment             => 'Rewrite for pip to intranet2',
            rewrite_rule        => ["^pip(.*) http://${intranet2}/pip$1 [R,L]"],
          },
          {
            comment             => 'Rewrite for woltrain now for intranet2',
            rewrite_rule        => ["^woltrain(.*) http://${intranet2}/woltrain$1 [R,L]"],
          },
        ]
      },
      {
        path                    => "${docroot}/returns",
        directoryindex          => 'british-gas-returns.php'
      },
      {
        path                    => "${docroot}/cw",
        php_values              => ["include_path \"${docroot}/cw/includes/\""]
      },
      {
        path                    => "${docroot}/leaguetables",
        options                 => ['Indexes','SymLinksIfOwnerMatch'],
      },
      {
        path                    => "${docroot}/pip",
        options                 => ['All'],
        allow_override          => ['All'],
      },
    ],
  }
}

define intranet2DEMO(
  $docroot              = '/sites/intranet2'
) {
  apache::vhost { "${name}.wolseley.co.uk":
    port                        => '80',
    docroot                     => $docroot,
    manage_docroot              => false,
    override                    => 'All',
    php_values                  => ['max_execution_time 120'],
    directories                 => [
      {
        allow_override          => ['All'],
        path                    => "${docroot}/current",
        options                 => ['FollowSymLinks', '-MultiViews'],
       php_values              => ["include_path \"${docroot}/current\"", "include_path \"${docroot}/pip\""],
        custom_fragment         => 'RailsBaseURI /apps
RailsBaseURI /qna
zend.ze1_compatibility_mode Off',
      },
      {
        path                    => "${docroot}/pip",
        allow_override          => ['All'],
        options                 => ['All'],
      },
    ],
  }
}

define groupintranetv2(
  $docroot            = '/sites/intranet/groupv2'
) {
  apache::vhost { "${name}.wolseley.co.uk":
  }
}

define webnode(
  $prefix,
) {

  include prod_defaults

  class { 'apache':
    mpm_module                  => 'prefork',
  }

  include apache::mod::rewrite
  include apache::mod::passenger
  include apache::mod::perl

  class { 'php52': }

  $files = [ "/sites", "/sites/intranet", "/sites/intranet2", "/sites/rails", "/sites/rails/qna", "/sites/rails/apps" ]

  file { $files:
    ensure                      => "directory",
    group                       => "apache",
    owner                       => "jenkins",
  }

  groupintranet { "ssl-${prefix}groupintranet.wolseley.com":
    ssl           => false, # THIS SHOULD BE TRUE TODO
    docroot       => '/sites/intranet/groupv2',
    serveradmin   => 'it.ops@wolseley.co.uk',
    serveraliases => ["${prefix}.groupintranet.wolseley.com"]
  }

  groupintranet { "${prefix}groupintranet.wolseley.com":
    ssl         => false,
    docroot     => '/sites/intranet/groupv2',
    serveradmin => 'web_admin_ripon@wolseley.co.uk',
  }

  intranet2 { "${prefix}intranet2.wolseley.co.uk" :
    docroot       => '/sites/intranet2/current',
    ssl           => false, # THIS SHOULD BE TRUE TODO
    serveraliases => ["${prefix}.intranet2.wolseley.com"],
  }

  intranet { "${prefix}intranet.wolseley.co.uk":
    serveraliases => ["www.${prefix}intranet.wolseley.com"],
  }

}

class dbnode{

  include prod_defaults
  class {'beluga::mysql_server': }
  class {'intranet_db':}

}