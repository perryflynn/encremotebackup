This scripts download the specifed folder with SFTP, creates 
a tar archive, encrypt the tar with gpg and upload the encrypted tar to another SFTP Account.

Dependencies
------------
* Net::SFTP::Foreign
* XML::Simple

```
apt-get install libnet-sftp-foreign-perl libxml-simple-perl gpg tar
```

Installation
------------
* Import the public key to gpg: `gpg --import encrypt-key.txt`
* Add a cronjob
```
# m h  dom mon dow   command
00 02 * * * /home/encremotebackup/encremotebackup.pl -f my-backup.xml
```

Configuration in XML
--------------------
The configuration of a backup is specifed in xml.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<connection>
   <!-- Specify a name that used for the filename -->
   <name>the-name-of-backup</name>
   <!-- The ID of the public gpg key -->
   <publickey>997AA45D</publickey>
   <!-- Store one Month, then delete the backup -->
   <maxageinhours>720</maxageinhours>
   <!-- Source SFTP connection -->
   <source>
      <hostname>localhost</hostname>
      <port>22</port>
      <username>myuser</username>
      <!-- Use keyfile OR password -->
      <!--password>...</password-->
      <keyfile>ssh-myuser.key</keyfile>
      <directory>/home/myuser/</directory>
   </source>
   <!-- Target SFTP connection -->
   <destination>
      <hostname>mycoolonlinespace.example.com</hostname>
      <port>22</port>
      <username>anycustomernumber</username>
      <!-- Use keyfile OR password -->
      <password>akjfhkaakfjhakhfg</password>
      <!--keyfile>...</keyfile-->
      <directory>/mycustomernumber/the-name-of-backup/</directory>
   </destination>
</connection>
```
