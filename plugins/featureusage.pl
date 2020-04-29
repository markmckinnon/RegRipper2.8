#-----------------------------------------------------------
# featureusage.pl
# Plugin for Registry Ripper 
# Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage Recent File List values 
#
# Change history
#
# References: https://www.group-ib.com/blog/featureusage
#
# 
# copyright 2020 Mark McKinnon
#-----------------------------------------------------------
package featureusage;
use strict;

my %config = (hive          => "NTUSER\.DAT",
              category      => "program execution",
              hasShortDescr => 1,
              hasDescr      => 0,
              hasRefs       => 0,
              osmask        => 22,
              version       => 20200429);

sub getConfig{return %config}
sub getShortDescr {
	return "Gets contents of user's feature usage key";	
}
sub getDescr{}
sub getRefs {}
sub getHive {return $config{hive};}
sub getVersion {return $config{version};}

my $VERSION = getVersion();
my @subkeys = qw(AppBadgeUpdated  AppLaunch  AppSwitched  ShowJumpView  TrayButtonClicked);

sub pluginmain {
	my $class = shift;
	my $ntuser = shift;
	::logMsg("Launching featureusage v.".$VERSION);
	::rptMsg("featureusage v.".$VERSION); # banner
  ::rptMsg("(".$config{hive}.") ".getShortDescr()."\n"); # banner
	my $reg = Parse::Win32Registry->new($ntuser);
	my $root_key = $reg->get_root_key;

	my $key_path = 'Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FeatureUsage';
	my $key;
	if ($key = $root_key->get_subkey($key_path)) {
		::rptMsg("FeatureUsage");
		::rptMsg($key_path);
		::rptMsg("LastWrite Time ".gmtime($key->get_timestamp())." (UTC)");
		::rptMsg("");
# Locate each subkey
        foreach my $subkey (@subkeys) {
            my $featureusage_key = $key->get_subkey($subkey);
            if (defined $featureusage_key) {
                my @vals = $featureusage_key->get_list_of_values();
                if (scalar(@vals) > 0) {
                    my %files;
# Retrieve values and load into a hash for sorting			
                    foreach my $v (@vals) {
                        my $val = $v->get_name();
                        my $data = $v->get_data();
                        $files{$val} = $val.":".$data;
                    }
                    ::rptMsg($subkey."  LastWrite Time ".gmtime($featureusage_key->get_timestamp())." (UTC)");
                    if ($subkey eq "AppBadgeUpdated") {
                        ::rptMsg("  Application -> Badge Updates");
                    } elsif ($subkey eq "AppLaunch") {
                        ::rptMsg("  Application -> Launches");
                    } elsif ($subkey eq "AppSwitched") {
                        ::rptMsg("  Application -> Left Click On Task Bar App");
                    } elsif ($subkey eq "ShowJumpView") {
                        ::rptMsg("  Application -> Right Click On Task Bar App");
                    } else {
                        ::rptMsg("  Application -> Left Click On Task Bar Items");
                    }
# Print sorted content to report file			
                    foreach my $u (sort {$a <=> $b} keys %files) {
                        my ($val,$data) = split(/:/,$files{$u},2);
                        ::rptMsg("    ".$val." -> ".$data);
                    }
                    ::rptMsg(" ");
                }
                else {
                    ::rptMsg($key_path."\\".$featureusage_key." has no values.");
                }			
            }
            else {
                ::rptMsg($key_path."\\".$featureusage_key." not found.");
            }
        }
	}
	else {
		::rptMsg($key_path." not found.");
	}
}

1;