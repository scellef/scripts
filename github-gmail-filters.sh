#!/usr/bin/env bash
# Template out a Gmail filters.xml to import for new Hashicorp Github
# repository notifications
#
# Take the resultant $outputFile and import it in Gmail via:
#   1. Settings -> Fitlers and Blocked Addresses
#   2. Import filters -> Choose File -> $outputFile
#   3. Open file
#   4. Select "Apply new filters to existing email" -> Create filters
#
# Usage: ./github-gmail-filters.sh repo1 [repo2] ...


repos="$@"
authorName='Sean Ellefson'
authorEmail='sellefson@hashicorp.com'
githubOrg='hashicorp.github.com'

[ -z "$repos" ] && \
  printf "Please enter a repository name you would like to filter\n" && exit 1

outputFile='filters.xml'

cat > $outputFile << HEADER
<?xml version='1.0' encoding='UTF-8'?>
<feed xmlns='http://www.w3.org/2005/Atom' xmlns:apps='http://schemas.google.com/apps/2006'>
  <title>Mail Filters</title>
  <id>tag:mail.google.com,2008:filters:z0000001598970691024*8356617616940590749</id>
  <author>
    <name>$authorName</name>
    <email>$authorEmail</email>
  </author>
HEADER

for repo in $repos ; do 
  cat >> $outputFile << ENTRY
  <entry>
    <category term='filter'></category>
    <title>Mail Filter</title>
    <id>tag:mail.google.com,2008:filter:z0000001598970691024*8356617616940590749</id>
    <content></content>
    <apps:property name='hasTheWord' value='list:($repo.$githubOrg)'/>"
    <apps:property name='label' value='Github/$repo'/>"
    <apps:property name='shouldArchive' value='true'/>
    <apps:property name='sizeOperator' value='s_sl'/>
    <apps:property name='sizeUnit' value='s_smb'/>
  </entry>
ENTRY
done 

cat >> $outputFile << EOF
</feed>
EOF
