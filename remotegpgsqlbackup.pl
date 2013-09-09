#!/usr/bin/perl

# Debian dependencies: libnet-sftp-foreign-perl libxml-simple-perl

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
my $tmpfolder = "tmp/";

# Prepare dump
my $temp = $tree->{databases}->{database};
my @dbs = ();

if (ref($temp) eq 'ARRAY') {
   @dbs = @{ $temp };
} else {
   @dbs = ( $temp );
}

# Establish connection
my $sftptarget = createconnection($tree->{destination});
$sftptarget->mkpath($tree->{destination}->{directory});

# Dump databases
foreach my $db ( @dbs ) {
   
   print "\n#-> Dump '".$db->{displayname}." (".$db->{database}."@".$tree->{hostname}.")'\n\n";
   
   # Dump
   print datestring()." Dump...\n";
   my $filename = $tree->{name}."_".$db->{displayname}."_".$db->{database}."_".$date.".sql";
   my $user = $db->{username};
   my $pass = $db->{password};
   my $dbn = $db->{database};
   my $lcmd = "mysqldump -h \"".$tree->{hostname}."\" -P \"".$tree->{port}."\" -u \"".$user."\" \"-p".$pass."\" \"".$dbn."\" > \"".$tmpfolder.$filename."\"";
   system($lcmd);
   
   # Tar
   print datestring()." Tar...\n";
   my $tcmd = "tar -czf \"".$tmpfolder.$filename.".tar.gz\" \"".$tmpfolder.$filename."\" 2>&1";
   system($tcmd);
   
   # Encrypt
   print datestring()." Encrypt...\n";
   my $ecmd = "gpg --trust-model always --batch --yes --encrypt --recipient ".$tree->{publickey}." \"".$tmpfolder.$filename.".tar.gz\"";
   system($ecmd);
   
   # Upload
   print datestring()." Upload...\n";
   $sftptarget->put($tmpfolder.$filename.".tar.gz.gpg", $tree->{destination}->{directory}."/".$filename.".tar.gz.gpg");
   
   # Cleanup
   print datestring()." Cleanup...\n";
   rmtree($tmpfolder.$filename);
   rmtree($tmpfolder.$filename.".tar.gz");
   rmtree($tmpfolder.$filename.".tar.gz.gpg");
   
   print datestring()." Done!\n";
   
}

# Delete old files
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

# EOF

