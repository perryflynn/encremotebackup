#!/usr/bin/perl

#
# This script creates encrypted backups of SFTP locations
# Script by Christian Blechert (christian@blechert.name)
# License: GPL Version 3, see License.txt
#

# Debian dependencies: libnet-sftp-foreign-perl libxml-simple-perl gpg tar

use strict; 
use warnings; 
use Net::SFTP::Foreign;
use Data::Dumper;
use Getopt::Std;
use XML::Simple;
use File::Path qw(mkpath rmtree);;
use Cwd 'chdir';
use File::Basename;

sub createconnection
{
   my $node = $_[0];

   my $shost = $node->{hostname};
   my $sport = $node->{port};
   my $suser = $node->{username};

   if (exists $node->{keyfile}) 
   {
      my $skey = $node->{keyfile};
      return Net::SFTP::Foreign->new(host=>$shost, user=>$suser, key_path=>$skey, port=>$sport, timeout=>120);
   } 
   elsif(exists $node->{password}) 
   {
      my $spw = $node->{password};
      return Net::SFTP::Foreign->new(host=>$shost, user=>$suser, password=>$spw, port=>$sport, timeout=>120);
   } 
   else 
   {
      return;
   }
}

sub datestring
{
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
   return sprintf "%.4d-%.2d-%.2d--%.2d-%.2d-%.2d", $year+1900, $mon+1, $mday,$hour,$min,$sec;
}



# Change in scripts path
chdir dirname $0;

# Arguments
my %opts;
getopts('f:', \%opts);
my $file = $opts{f};

die "Can't find file \"$file\""
  unless -f $file;
  
# Parse config
my $parser = new XML::Simple;
my $tree = $parser->XMLin($file);

# Build names
my $date = datestring();
my $tmpfolder = "tmp/".$tree->{name}."/";
my $tarfile = "tmp/".$tree->{name}."-".$date.".tar.gz";
my $gpgfile = $tree->{name}."-".$date.".tar.gz.gpg";

# Download
print datestring()." Download...\n";
my $sftpsource = createconnection($tree->{source});
mkpath($tmpfolder);
$sftpsource->rget($tree->{source}->{directory}, $tmpfolder, ignore_links=>1, overwrite=>1, copy_perm=>0, copy_time=>0);
$sftpsource->disconnect();

# TAR
print datestring()." Tar...\n";
my $cmd = "tar -czf \"".$tarfile."\" \"".$tmpfolder."\" 2>&1";
system($cmd);

# Encrypt
print datestring()." Encrypt...\n";
$cmd = "gpg --trust-model always --batch --yes --encrypt --recipient ".$tree->{publickey}." \"".$tarfile."\"";
system($cmd);

# Upload
print "\n".datestring()." Upload...\n";

my @info = stat("tmp/".$gpgfile);
print "Filename: ".$gpgfile."\n";
print "Size: ".($info[7]/1024/1024)."MB\n";

my $sftptarget = createconnection($tree->{destination});
$sftptarget->mkpath($tree->{destination}->{directory});
$sftptarget->put("tmp/".$gpgfile, $tree->{destination}->{directory}."/".$gpgfile);

# Remove old Backups
print "\n".datestring()." Remove old backups...\n";

my $filelist = $sftptarget->ls($tree->{destination}->{directory}, wanted=>qr/.*\.gpg$/);
my $maxtstamp = time-($tree->{maxageinhours}*60*60);

foreach my $file ( @{ $filelist } ){
   my $mtime = $file->{a}->{mtime};
   if($maxtstamp>$mtime) {
      print "Delete ".$file->{filename}."\n";
      $sftptarget->remove($tree->{destination}->{directory}."/".$file->{filename});
   }
}

$sftptarget->disconnect();

# Cleanup
print "\n".datestring()." Cleanup...\n";
rmtree($tmpfolder);
rmtree($tarfile);
rmtree("tmp/".$gpgfile);

print datestring()." Done!\n\n";

# EOF
