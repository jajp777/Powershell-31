Cls

$VhostIP = "internal ip"
$VhostPort = "80"
$DocumentRoot = "documentroot.com"
$ServerName = "servername.fqdn.com"
$Ajp = "ajp.fqdn.com"
$AjpPort = "8009"
$Route = "rounte_name"
$MailAdmin = "test@test.com"



$ApachePath = "E:/Outils/Apache/"
$AWStatsPath = "E:/Outils/AWStats"
$ApachePathPosh = "E:\Outils\Apache"
$AWStatsPathPosh = "E:\Outils\AWStats"
$CompleteServerName = "$ServerName" + ":" + "$VhostPort"
$AjpAddress = "$Ajp" + ":" + "$AjpPort"
$VhostAddress = "$VhostIP" + ":" + "$VhostPort"



$Vhost = "
<VirtualHost $VhostAddress>
    ServerAdmin $MailAdmin

    DocumentRoot 'E:/websites/$DocumentRoot'
    ServerName $CompleteServerName
    UseCanonicalName On

    ErrorDocument 404 http://$DocumentRoot/404.php
    ErrorDocument 503 http://$DocumentRoot/503.php

    LogLevel warn
    ErrorLog 'logs/$ServerName.error.log'
    CustomLog 'logs/$ServerName.access.log' combined

    ProxyRequests Off
    <Proxy *>
      Order deny,allow
    </Proxy>

    RewriteEngine On
    RewriteRule   ^/$ /xnet/`$1 [R,L]
    RewriteRule   ^/admin-console(.*)$ /xnet`$1 [R,L]
    RewriteRule   ^/invoker(.*)$ /xnet`$1 [R,L]
    RewriteRule   ^/jmx-console(.*)$ /xnet`$1 [R,L]
    RewriteRule   ^/status(.*)$ /xnet`$1 [R,L]
    RewriteRule   ^/web-console(.*)$ /xnet`$1 [R,L]

    ProxyPreserveHost On
    ProxyPass  / ajp://$AjpAddress/ route=$Route keepalive=on disablereuse=On
    ProxyPassReverse  / ajp://$AjpAddress/
    
    <Directory 'E:/websites/$DocumentRoot'>
      AllowOverride FileInfo
      Options FollowSymLinks
      Require all granted
    </Directory>
</VirtualHost>" 


$AWStats = "
#---
#---  Pour plus d'informations sur les options :
#---  http://awstats.sourceforge.net/docs/awstats_config.html
#---

#-----------------------------------------------------------------------------
# MAIN SETUP SECTION (Required to make AWStats work)
#-----------------------------------------------------------------------------

LogFile='$ApachePath/logs/$ServerName.access.log'
LogType=W
LogFormat=1
LogSeparator=' '

SiteDomain='$ServerName'
HostAliases='localhost 127.0.0.1 REGEX[myserver\.com$]'

DNSLookup=1

DirData='$AWStatsPath/Datas'
DirCgi='/awstats'
DirIcons='/awstatsicons'

AllowToUpdateStatsFromBrowser=0
AllowFullYearView=3


#-----------------------------------------------------------------------------
# OPTIONAL SETUP SECTION (Not required but increase AWStats features)
#-----------------------------------------------------------------------------

EnableLockForUpdate=0

DNSStaticCacheFile='E:/Outils/AWStats/Datas/dnscache.txt'
DNSLastUpdateCacheFile='E:/Outils/AWStats/Datas/dnscachelastupdate.txt'
SkipDNSLookupFor=''

AllowAccessFromWebToAuthenticatedUsersOnly=0
AllowAccessFromWebToFollowingAuthenticatedUsers=''
AllowAccessFromWebToFollowingIPAddresses=''

CreateDirDataIfNotExists=0

BuildHistoryFormat=text
BuildReportFormat=html

SaveDatabaseFilesWithPermissionsForEveryone=0

PurgeLogFile=1
ArchiveLogRecords=%YYYY%MM%DD

KeepBackupOfHistoricFiles=1

DefaultFile='index.php index.html'

SkipHosts='172.17.40.204'
SkipUserAgents=''
SkipFiles=''
SkipReferrersBlackList=''

OnlyHosts=''
OnlyUserAgents=''
OnlyUsers=''
OnlyFiles=''

NotPageList='css js class gif jpg jpeg png bmp ico rss xml swf'

ValidHTTPCodes='200 304'
ValidSMTPCodes='1 250'

AuthenticatedUsersNotCaseSensitive=0

URLNotCaseSensitive=0
URLWithAnchor=0
URLQuerySeparators='?;'
URLWithQuery=0
URLWithQueryWithOnlyFollowingParameters=''
URLWithQueryWithoutFollowingParameters=''
URLReferrerWithQuery=0

WarningMessages=1
ErrorMessages=''
DebugMessages=0

NbOfLinesForCorruptedLog=50

WrapperScript=''

DecodeUA=0

# MiscTrackerUrl can be used to make AWStats able to detect some miscellaneous
# things, that can not be tracked on other way, like:
# - Javascript disabled
# - Java enabled
# - Screen size
# - Color depth
# - Macromedia Director plugin
# - Macromedia Shockwave plugin
# - Realplayer G2 plugin
# - QuickTime plugin
# - Mediaplayer plugin
# - Acrobat PDF plugin
# To enable all these features, you must copy the awstats_misc_tracker.js file
# into a /js/ directory stored in your web document root and add the following
# HTML code at the end of your index page (but before </BODY>) :
#
# <script type='text/javascript' src='/js/awstats_misc_tracker.js'></script>
# <noscript><img src='/js/awstats_misc_tracker.js?nojs=y' height=0 width=0 border=0 style='display: none'></noscript>
#
# If code is not added in index page, all those detection capabilities will be
# disabled. You must also check that ShowScreenSizeStats and ShowMiscStats
# parameters are set to 1 to make results appear in AWStats report page.
# If you want to use another directory than /js/, you must also change the
# awstatsmisctrackerurl variable into the awstats_misc_tracker.js file.
# Change : Effective for new updates only.
# Possible value: URL of javascript tracker file added in your HTML code.
# Default: '/js/awstats_misc_tracker.js'
#
MiscTrackerUrl='/js/awstats_misc_tracker.js'


#-----------------------------------------------------------------------------
# OPTIONAL ACCURACY SETUP SECTION (Not required but increase AWStats features)
#-----------------------------------------------------------------------------

LevelForBrowsersDetection=2         # 0 disables Browsers detection.
                                    # 2 reduces AWStats speed by 2%
                                    # allphones reduces AWStats speed by 5%
LevelForOSDetection=2               # 0 disables OS detection.
                                    # 2 reduces AWStats speed by 3%
LevelForRefererAnalyze=2            # 0 disables Origin detection.
                                    # 2 reduces AWStats speed by 14%
LevelForRobotsDetection=2           # 0 disables Robots detection.
                                    # 2 reduces AWStats speed by 2.5%
LevelForSearchEnginesDetection=2    # 0 disables Search engines detection.
                                    # 2 reduces AWStats speed by 9%
LevelForKeywordsDetection=2         # 0 disables Keyphrases/Keywords detection.
                                    # 2 reduces AWStats speed by 1%
LevelForFileTypesDetection=2        # 0 disables File types detection.
                                    # 2 reduces AWStats speed by 1%
LevelForWormsDetection=2            # 0 disables Worms detection.
                                    # 2 reduces AWStats speed by 15%


#-----------------------------------------------------------------------------
# OPTIONAL APPEARANCE SETUP SECTION (Not required but increase AWStats features)
#-----------------------------------------------------------------------------

UseFramesWhenCGI=1

DetailedReportsOnNewWindows=1

Expires=0

MaxRowsInHTMLOutput=1000

Lang='auto'
DirLang='./lang'

ShowMenu=1					


# You choose here which reports you want to see in the main page and what you
# want to see in those reports.
# Possible values:
#  0  - Report is not shown at all
#  1  - Report is shown in main page with an entry in menu and default columns
# XYZ - Report shows column informations defined by code X,Y,Z...
#       X,Y,Z... are code letters among the following:
#        U = Unique visitors
#        V = Visits
#        P = Number of pages
#        H = Number of hits (or mails)
#        B = Bandwith (or total mail size for mail logs)
#        L = Last access date
#        E = Entry pages
#        X = Exit pages
#        C = Web compression (mod_gzip,mod_deflate)
#        M = Average mail size (mail logs)
#

# Show monthly summary
# Context: Web, Streaming, Mail, Ftp
# Default: UVPHB, Possible column codes: UVPHB
ShowSummary=UVPHB

# Show monthly chart
# Context: Web, Streaming, Mail, Ftp
# Default: UVPHB, Possible column codes: UVPHB
ShowMonthStats=UVPHB

# Show days of month chart
# Context: Web, Streaming, Mail, Ftp
# Default: VPHB, Possible column codes: VPHB
ShowDaysOfMonthStats=VPHB

# Show days of week chart
# Context: Web, Streaming, Mail, Ftp
# Default: PHB, Possible column codes: PHB
ShowDaysOfWeekStats=PHB

# Show hourly chart
# Context: Web, Streaming, Mail, Ftp
# Default: PHB, Possible column codes: PHB
ShowHoursStats=PHB

# Show domains/country chart
# Context: Web, Streaming, Mail, Ftp
# Default: PHB, Possible column codes: PHB
ShowDomainsStats=PHB

# Show hosts chart
# Context: Web, Streaming, Mail, Ftp
# Default: PHBL, Possible column codes: PHBL
ShowHostsStats=PHBL

# Show authenticated users chart
# Context: Web, Streaming, Ftp
# Default: 0, Possible column codes: PHBL
ShowAuthenticatedUsers=0

# Show robots chart
# Context: Web, Streaming
# Default: HBL, Possible column codes: HBL
ShowRobotsStats=HBL

# Show worms chart
# Context: Web, Streaming
# Default: 0 (If set to other than 0, see also LevelForWormsDetection), Possible column codes: HBL
ShowWormsStats=0

# Show email senders chart (For use when analyzing mail log files)
# Context: Mail
# Default: 0, Possible column codes: HBML
ShowEMailSenders=0

# Show email receivers chart (For use when analyzing mail log files)
# Context: Mail
# Default: 0, Possible column codes: HBML
ShowEMailReceivers=0

# Show session chart
# Context: Web, Streaming, Ftp
# Default: 1, Possible column codes: None
ShowSessionsStats=1

# Show pages-url chart.
# Context: Web, Streaming, Ftp
# Default: PBEX, Possible column codes: PBEX
ShowPagesStats=PBEX

# Show file types chart.
# Context: Web, Streaming, Ftp
# Default: HB, Possible column codes: HBC
ShowFileTypesStats=HB

# Show file size chart (Not yet available)
# Context: Web, Streaming, Mail, Ftp
# Default: 1, Possible column codes: None
ShowFileSizesStats=0	

# Show downloads chart.
# Context: Web, Streaming, Ftp
# Default: HB, Possible column codes: HB
ShowDownloadsStats=HB	

# Show operating systems chart
# Context: Web, Streaming, Ftp
# Default: 1, Possible column codes: None
ShowOSStats=1

# Show browsers chart
# Context: Web, Streaming
# Default: 1, Possible column codes: None
ShowBrowsersStats=1

# Show screen size chart
# Context: Web, Streaming
# Default: 0 (If set to 1, see also MiscTrackerUrl), Possible column codes: None
ShowScreenSizeStats=0

# Show origin chart
# Context: Web, Streaming
# Default: PH, Possible column codes: PH
ShowOriginStats=PH

# Show keyphrases chart
# Context: Web, Streaming
# Default: 1, Possible column codes: None
ShowKeyphrasesStats=1

# Show keywords chart
# Context: Web, Streaming
# Default: 1, Possible column codes: None
ShowKeywordsStats=1

# Show misc chart
# Context: Web, Streaming
# Default: a (See also MiscTrackerUrl parameter), Possible column codes: anjdfrqwp
ShowMiscStats=a

# Show http errors chart
# Context: Web, Streaming
# Default: 1, Possible column codes: None
ShowHTTPErrorsStats=1

# Show smtp errors chart (For use when analyzing mail log files)
# Context: Mail
# Default: 0, Possible column codes: None
ShowSMTPErrorsStats=0

# Show the cluster report (Your LogFormat must contains the %cluster tag)
# Context: Web, Streaming, Ftp
# Default: 0, Possible column codes: PHB
ShowClusterStats=0


AddDataArrayMonthStats=1
AddDataArrayShowDaysOfMonthStats=1
AddDataArrayShowDaysOfWeekStats=1
AddDataArrayShowHoursStats=1

IncludeInternalLinksInOriginSection=0


# The following parameters can be used to choose the maximum number of lines
# shown for the particular following reports.
#
# Stats by countries/domains
MaxNbOfDomain = 10
MinHitDomain  = 1
# Stats by hosts
MaxNbOfHostsShown = 10
MinHitHost    = 1
# Stats by authenticated users
MaxNbOfLoginShown = 10
MinHitLogin   = 1
# Stats by robots
MaxNbOfRobotShown = 10
MinHitRobot   = 1
# Stats for Downloads
MaxNbOfDownloadsShown = 10
MinHitDownloads = 1
# Stats by pages
MaxNbOfPageShown = 10
MinHitFile    = 1
# Stats by OS
MaxNbOfOsShown = 10
MinHitOs      = 1
# Stats by browsers
MaxNbOfBrowsersShown = 10
MinHitBrowser = 1
# Stats by screen size
MaxNbOfScreenSizesShown = 5
MinHitScreenSize = 1
# Stats by window size (following 2 parameters are not yet used)
MaxNbOfWindowSizesShown = 5
MinHitWindowSize = 1
# Stats by referers
MaxNbOfRefererShown = 10
MinHitRefer   = 1
# Stats for keyphrases
MaxNbOfKeyphrasesShown = 10
MinHitKeyphrase = 1
# Stats for keywords
MaxNbOfKeywordsShown = 10
MinHitKeyword = 1
# Stats for sender or receiver emails
MaxNbOfEMailsShown = 20
MinHitEMail   = 1


FirstDayOfWeek=1

ShowFlagLinks='en es fr it'

ShowLinksOnUrl=1

UseHTTPSLinkForUrl=''

MaxLengthOfShownURL=64


# You can enter HTML code that will be added at the top of AWStats reports.
# Default: ''
#
HTMLHeadSection=''


# You can enter HTML code that will be added at the end of AWStats reports.
# Great to add advert ban.
# Default: ''
#
HTMLEndSection=''


# By default AWStats page contains meta tag robots=noindex,nofollow
# If you want to have your statistics to be indexed, set this option to 1. 
# Default: 0
#
MetaRobot=0


# You can set Logo and LogoLink to use your own logo.
# Logo must be the name of image file (must be in `$DirIcons/other directory).
# LogoLink is the expected URL when clicking on Logo.
# Default: 'awstats_logo6.png'
#
Logo='awstats_logo6.png'
LogoLink='http://awstats.sourceforge.net'


# Value of maximum bar width/height for horizontal/vertical HTML graphics bars.
# Default: 260/90
#
BarWidth   = 260
BarHeight  = 90


# You can ask AWStats to use a particular CSS (Cascading Style Sheet) to
# change its look. To create a style sheet, you can use samples provided with
# AWStats in wwwroot/css directory.
# Example: '/awstatscss/awstats_bw.css'
# Example: '/css/awstats_bw.css'
# Default: ''
#
StyleSheet=''


# Those color parameters can be used (if StyleSheet parameter is not used)
# to change AWStats look.
# Example: color_name='RRGGBB'	# RRGGBB is Red Green Blue components in Hex
#
color_Background='FFFFFF'		# Background color for main page (Default = 'FFFFFF')
color_TableBGTitle='CCCCDD'		# Background color for table title (Default = 'CCCCDD')
color_TableTitle='000000'		# Table title font color (Default = '000000')
color_TableBG='CCCCDD'			# Background color for table (Default = 'CCCCDD')
color_TableRowTitle='FFFFFF'	# Table row title font color (Default = 'FFFFFF')
color_TableBGRowTitle='ECECEC'	# Background color for row title (Default = 'ECECEC')
color_TableBorder='ECECEC'		# Table border color (Default = 'ECECEC')
color_text='000000'				# Color of text (Default = '000000')
color_textpercent='606060'		# Color of text for percent values (Default = '606060')
color_titletext='000000'		# Color of text title within colored Title Rows (Default = '000000')
color_weekend='EAEAEA'			# Color for week-end days (Default = 'EAEAEA')
color_link='0011BB'				# Color of HTML links (Default = '0011BB')
color_hover='605040'			# Color of HTML on-mouseover links (Default = '605040') 
color_u='FFAA66'				# Background color for number of unique visitors (Default = 'FFAA66')
color_v='F4F090'				# Background color for number of visites (Default = 'F4F090')
color_p='4477DD'				# Background color for number of pages (Default = '4477DD')
color_h='66DDEE'				# Background color for number of hits (Default = '66DDEE')
color_k='2EA495'				# Background color for number of bytes (Default = '2EA495')
color_s='8888DD'				# Background color for number of search (Default = '8888DD')
color_e='CEC2E8'				# Background color for number of entry pages (Default = 'CEC2E8')
color_x='C1B2E2'				# Background color for number of exit pages (Default = 'C1B2E2')



#-----------------------------------------------------------------------------
# PLUGINS
#-----------------------------------------------------------------------------

# Add here all plugin files you want to load.
# Plugin files must be .pm files stored in 'plugins' directory.
# Uncomment LoadPlugin lines to enable a plugin after checking that perl
# modules required by the plugin are installed.

# PLUGIN: Tooltips
# REQUIRED MODULES: None
# PARAMETERS: None
# DESCRIPTION: Add tooltips pop-up help boxes to HTML report pages.  
# NOTE: This will increased HTML report pages size, thus server load and bandwidth.
#
#LoadPlugin='tooltips'

# PLUGIN: DecodeUTFKeys
# REQUIRED MODULES: Encode and URI::Escape
# PARAMETERS: None
# DESCRIPTION: Allow AWStats to show correctly (in language charset) 
# keywords/keyphrases strings even if they were UTF8 coded by the 
# referer search engine.
#
#LoadPlugin='decodeutfkeys'

# PLUGIN: IPv6
# PARAMETERS: None
# REQUIRED MODULES: Net::IP and Net::DNS
# DESCRIPTION: This plugin gives AWStats capability to make reverse DNS
# lookup on IPv6 addresses.
#
#LoadPlugin='ipv6'

# PLUGIN: HashFiles
# REQUIRED MODULES: Storable
# PARAMETERS: None
# DESCRIPTION: AWStats DNS cache files are read/saved as native hash files. 
# This increases DNS cache files loading speed, above all for very large web sites.
#
#LoadPlugin='hashfiles'


# PLUGIN: UserInfo
# REQUIRED MODULES: None
# PARAMETERS: None
# DESCRIPTION: Add a text (Firtname, Lastname, Office Department, ...) in 
# authenticated user reports for each login value.
# A text file called userinfo.myconfig.txt, with two fields (first is login,
# second is text to show, separated by a tab char) must be created in DirData
# directory.
#
#LoadPlugin='userinfo'

# PLUGIN: HostInfo
# REQUIRED MODULES: Net::XWhois
# PARAMETERS: None
# DESCRIPTION: Add a column into host chart with a link to open a popup window that shows
# info on host (like whois records).
#
#LoadPlugin='hostinfo'

# PLUGIN: ClusterInfo
# REQUIRED MODULES: None
# PARAMETERS: None
# DESCRIPTION: Add a text (for example a full hostname) in cluster reports for each cluster
# number. A text file called clusterinfo.myconfig.txt, with two fields (first is
# cluster number, second is text to show) separated by a tab char. must be
# created into DirData directory.
# Note this plugin is useless if ShowClusterStats is set to 0 or if you don't
# use a personalized log format that contains %cluster tag.
#
#LoadPlugin='clusterinfo'

# PLUGIN: UrlAliases
# REQUIRED MODULES: None
# PARAMETERS: None
# DESCRIPTION: Add a text (Page title, description...) in URL reports before URL value.
# A text file called urlalias.myconfig.txt, with two fields (first is URL,
# second is text to show, separated by a tab char) must be created into
# DirData directory.
#
#LoadPlugin='urlalias'

# PLUGIN: TimeHiRes
# REQUIRED MODULES: Time::HiRes (if Perl < 5.8)
# PARAMETERS: None
# DESCRIPTION: Time reported by -showsteps option is in millisecond. For debug purpose.
#
#LoadPlugin='timehires'		

# PLUGIN: TimeZone
# REQUIRED MODULES: Time::Local
# PARAMETERS: [timezone offset]
# DESCRIPTION: Allow AWStats to adjust time stamps for a different timezone
# This plugin reduces AWStats speed of 10% !!!!!!!
# LoadPlugin='timezone'
# LoadPlugin='timezone +2'
# LoadPlugin='timezone CET'
#
#LoadPlugin='timezone +2'

# PLUGIN: Rawlog
# REQUIRED MODULES: None
# PARAMETERS: None
# DESCRIPTION: This plugin adds a form in AWStats main page to allow users to see raw
# content of current log files. A filter is also available.
#
#LoadPlugin='rawlog'

# PLUGIN: GraphApplet
# REQUIRED MODULES: None
# PARAMETERS: [CSS classes to override]
# DESCRIPTION: Supported charts are built by a 3D graphic applet.
#
#LoadPlugin='graphapplet /awstatsclasses'				# EXPERIMENTAL FEATURE

# PLUGIN: GraphGoogleChartAPI
# REQUIRED MODULES: None
# PARAMETERS: None
# DESCRIPTION: Replaces the standard charts with free Google API generated images 
# in HTML reports. If country data is available and more than one country has hits, 
# a map will be generated using Google Visualizations.
# Note: The machine where reports are displayed must have Internet access for the 
# charts to be generated. The only data sent to Google includes the statistic numbers, 
# legend names and country names.
# Warning: This plugin is not compatible with option BuildReportFormat=xhtml. 
#
#LoadPlugin='graphgooglechartapi'

# PLUGIN: GeoIPfree
# REQUIRED MODULES: Geo::IPfree version 0.2+ (from Graciliano M.P.)
# PARAMETERS: None
# DESCRIPTION: Country chart is built from an Internet IP-Country database.
# This plugin is useless for intranet only log files.
# Note: You must choose between using this plugin (need Perl Geo::IPfree
# module, database is free but not up to date) or the GeoIP plugin (need
# Perl Geo::IP module from Maxmind, database is also free and up to date).
# Note: Activestate provide a corrupted version of Geo::IPfree 0.2 Perl
# module, so install it from elsewhere (from www.cpan.org for example).
# This plugin reduces AWStats speed by up to 10% !
#
#LoadPlugin='geoipfree'

# MAXMIND GEO IP MODULES: Please see documentation for notes on all Maxmind modules

# PLUGIN: GeoIP
# REQUIRED MODULES: Geo::IP or Geo::IP::PurePerl (from Maxmind)
# PARAMETERS: [GEOIP_STANDARD | GEOIP_MEMORY_CACHE] [/pathto/geoip.dat[+/pathto/override.txt]]
# DESCRIPTION: Builds a country chart and adds an entry to the hosts 
# table with country name
# Replace spaces in the path of geoip data file with string '%20'.
#
#LoadPlugin='geoip GEOIP_STANDARD /pathto/GeoIP.dat'

# PLUGIN: GeoIP_City_Maxmind
# REQUIRED MODULES: Geo::IP or Geo::IP::PurePerl (from Maxmind)
# PARAMETERS: [GEOIP_STANDARD | GEOIP_MEMORY_CACHE] [/pathto/GeoIPCity.dat[+/pathto/override.txt]]
# DESCRIPTION: This plugin adds a column under the hosts field and tracks the pageviews
# and hits by city including regions.
# Replace spaces in the path of geoip data file with string '%20'.
#
#LoadPlugin='geoip_city_maxmind GEOIP_STANDARD /pathto/GeoIPCity.dat'

# PLUGIN: GeoIP_ASN_Maxmind
# REQUIRED MODULES: Geo::IP or Geo::IP::PurePerl (from Maxmind)
# PARAMETERS: [GEOIP_STANDARD | GEOIP_MEMORY_CACHE] [/pathto/GeoIPASN.dat[+/pathto/override.txt][+http://linktoASlookup]]
# DESCRIPTION: This plugin adds a chart of AS numbers where the host IP address is registered. 
# This plugin can display some ISP information if included in the database. You can also provide 
# a link that will be used to lookup additional registration data. Put the link at the end of 
# the parameter string and the report page will include the link with the full AS number at the end.
# Replace spaces in the path of geoip data file with string '%20'.
#
#LoadPlugin='geoip_asn_maxmind GEOIP_STANDARD /usr/local/geoip.dat+http://enc.com.au/itools/aut-num.php?autnum='

# PLUGIN: GeoIP_Region_Maxmind
# REQUIRED MODULES: Geo::IP or Geo::IP::PurePerl (from Maxmind)
# PARAMETERS: [GEOIP_STANDARD | GEOIP_MEMORY_CACHE] [/pathto/GeoIPRegion.dat[+/pathto/override.txt]]
# DESCRIPTION:This plugin adds a chart of hits by regions. Only regions for US and 
# Canada can be detected.
# Replace spaces in the path of geoip data file with string '%20'.
#
#LoadPlugin='geoip_region_maxmind GEOIP_STANDARD /pathto/GeoIPRegion.dat'

# PLUGIN: GeoIP_ISP_Maxmind
# REQUIRED MODULES: Geo::IP or Geo::IP::PurePerl (from Maxmind)
# PARAMETERS: [GEOIP_STANDARD | GEOIP_MEMORY_CACHE] [/pathto/GeoIPISP.dat[+/pathto/override.txt]]
# DESCRIPTION: This plugin adds a chart of hits by ISP.
# Replace spaces in the path of geoip data file with string '%20'.
#
#LoadPlugin='geoip_isp_maxmind GEOIP_STANDARD /pathto/GeoIPISP.dat'

# PLUGIN: GeoIP_Org_Maxmind
# REQUIRED MODULES: Geo::IP or Geo::IP::PurePerl (from Maxmind)
# PARAMETERS: [GEOIP_STANDARD | GEOIP_MEMORY_CACHE] [/pathto/GeoIPOrg.dat[+/pathto/override.txt]]
# DESCRIPTION: This plugin add a chart of hits by Organization name
# Replace spaces in the path of geoip data file with string '%20'.
#
#LoadPlugin='geoip_org_maxmind GEOIP_STANDARD /pathto/GeoIPOrg.dat'


#-----------------------------------------------------------------------------
# EXTRA SECTIONS
#-----------------------------------------------------------------------------

# You can define your own charts, you choose here what are rows and columns
# keys. This feature is particularly useful for marketing purpose, tracking
# products orders for example.
# For this, edit all parameters of Extra section. Each set of parameter is a
# different chart. For several charts, duplicate section changing the number.
# Note: Each Extra section reduces AWStats speed by 8%.
#
# WARNING: A wrong setup of Extra section might result in too large arrays
# that will consume all your memory, making AWStats unusable after several
# updates, so be sure to setup it correctly.
# In most cases, you don't need this feature.
#
# ExtraSectionNameX is title of your personalized chart.
# ExtraSectionCodeFilterX is list of codes the record code field must match.
#   Put an empty string for no test on code.
# ExtraSectionConditionX are conditions you can use to count or not the hit,
#   Use one of the field condition
#   (URL,URLWITHQUERY,QUERY_STRING,REFERER,UA,HOSTINLOG,HOST,VHOST,extraX)
#   and a regex to match, after a coma. Use '||' for 'OR'.
# ExtraSectionFirstColumnTitleX is the first column title of the chart.
# ExtraSectionFirstColumnValuesX is a string to tell AWStats which field to
#   extract value from
#   (URL,URLWITHQUERY,QUERY_STRING,REFERER,UA,HOSTINLOG,HOST,VHOST,extraX)
#   and how to extract the value (using regex syntax). Each different value
#   found will appear in first column of report on a different row. Be sure
#   that list of different possible values will not grow indefinitely.
# ExtraSectionFirstColumnFormatX is the string used to write value.
# ExtraSectionStatTypesX are things you want to count. You can use standard
#   code letters (P for pages,H for hits,B for bandwidth,L for last access).
# ExtraSectionAddAverageRowX add a row at bottom of chart with average values.
# ExtraSectionAddSumRowX add a row at bottom of chart with sum values.
# MaxNbOfExtraX is maximum number of rows shown in chart.
# MinHitExtraX is minimum number of hits required to be shown in chart.
#

# Example to report the 20 products the most ordered by 'order.cgi' script
#ExtraSectionName1='Product orders'
#ExtraSectionCodeFilter1='200 304'
#ExtraSectionCondition1='URL,\/cgi\-bin\/order\.cgi||URL,\/cgi\-bin\/order2\.cgi'
#ExtraSectionFirstColumnTitle1='Product ID'
#ExtraSectionFirstColumnValues1='QUERY_STRING,productid=([^&]+)'
#ExtraSectionFirstColumnFormat1='%s'
#ExtraSectionStatTypes1=PL
#ExtraSectionAddAverageRow1=0
#ExtraSectionAddSumRow1=1
#MaxNbOfExtra1=20
#MinHitExtra1=1


# There is also a global parameter ExtraTrackedRowsLimit that limits the
# number of possible rows an ExtraSection can report. This parameter is
# here to protect too much memory use when you make a bad setup in your
# ExtraSection. It applies to all ExtraSection independently meaning that
# none ExtraSection can report more rows than value defined by ExtraTrackedRowsLimit.
# If you know an ExtraSection will report more rows than its value, you should
# increase this parameter or AWStats will stop with an error.
# Example: 2000
# Default: 500
#
ExtraTrackedRowsLimit=500


#-----------------------------------------------------------------------------
# INCLUDES
#-----------------------------------------------------------------------------

# You can include other config files using the directive with the name of the
# config file.
# This is particularly useful for users who have a lot of virtual servers, so
# a lot of config files and want to maintain common values in only one file.
# Note that when a variable is defined both in a config file and in an
# included file, AWStats will use the last value read for parameters that
# contains one value and AWStats will concat all values from both files for
# parameters that are lists of values.
#

#Include ''"


Cls

Invoke-Command -Computer $Server -ArgumentList $Vhost, $ApachePath -ScriptBlock { $Vhost | Out-File $ApachePathPosh\conf\extra\httpd-vhosts\$ServerName.conf }
Invoke-Command -Computer $Server -ArgumentList $AWStats, $AWStatsPath -ScriptBlock { $AWStats | Out-File $AWStatsPathPosh\7.0\wwwroot\cgi-bin\$ServerName }