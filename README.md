encremotebackup.pl download the specifed folder with SFTP, creates 
a tar archive, encrypt the tar with gpg and upload the encrypted tar to another SFTP account.

remotegpgsqlbackup.pl creates dumps of mysql databases, creates 
a tar archive, encrypt the tar with gpg and upload the encrypted tar to a SFTP account.

Dependencies
------------
* tar
* gpg
* mysqldump
* Perl Module `Net::SFTP::Foreign`
* Perl Module `XML::Simple`

```
apt-get install libnet-sftp-foreign-perl libxml-simple-perl gpg tar mysql-client
```

Installation
------------
* Import the public key to gpg: `gpg --import encrypt-key.txt`
* Find out the ID of GPG key `gpg --list-keys` `pub   4096R/997AA45D 2013-09-06` => `997AA45D`
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

```xml
<?xml version="1.0" encoding="UTF-8"?>
<connection>
   <name>sql-mydatabaseserver</name>
   <publickey>997AA45D</publickey>
   
   <!-- 3 Months -->
   <maxageinhours>2160</maxageinhours>

   <destination>
      <hostname>my.cool-backupspace.com</hostname>
      <port>22</port>
      <username>my-user-account</username>
      <password>mypw</password>
      <!--keyfile>...</keyfile-->
      <directory>/my-user-account/sql-mydatabaseserver/</directory>
   </destination>
   
   <hostname>any.sqlhost.com</hostname>
   <port>3306</port>
   
   <databases>
      
      <database>
         <displayname>database-01</displayname>
         <database>d0931478</database>
         <username>d0931478</username>
         <password>fooooopw</password>
      </database>
      
      <database>
         <displayname>database-02</displayname>
         <database>d0931477</database>
         <username>d0931477</username>
         <password>fooooopw</password>
      </database>
      
      <database>
         <displayname>database-03</displayname>
         <database>d0931476</database>
         <username>d0931476</username>
         <password>fooooopw</password>
      </database>
      
   </databases>
</connection>
```
