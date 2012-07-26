#!/usr/bin/perl
###!C:/perl/bin/perl.exe
# roqwiki;
# Last updated: 2012-07-26
$version = '2.1';
$copyyear = '2012';

=head1 RoqWiki

  A wiki generator that converts ascii text files that are in
  Roqet Document Format into an HTML document.
  RoqWiki was inspired by pwyky, an Python wiki (but contains
  no source-code from that project).

=head2 Install

  0. Download RoqWiki: <https://github.com/roqetman/roqwiki>
  1. Create a new script-writable directory on your server
  2. Upload roqwiki.pl to your server and rename it to index.cgi
  3. Change permissions on index.cgi to 755
  4. Create a .htaccess file in the same directory with the
     following contents:
     DirectoryIndex index.cgi
     Options -MultiViews
     RewriteEngine on
     RewriteBase /test
     RewriteRule ^@[a-z]+/([A-Za-z0-9-]+)$ index.cgi [L]
     RewriteRule ^([A-Za-z0-9-]+)$ index.cgi [L]
     RewriteRule ^([A-Za-z0-9-]+)\.html$ - [L]
  5. Browse to http://yourdomainname/yourdirectory/index.cgi

  When the index.cgi is run the first time, it will create the 
  template and stylesheet files for your later modification.

=head2 Further Configuration

  If you want to remove editing from the wiki, create a file in 
  the same directory called roqwiki.xml with the following format:

  <?xml version="1.0" encoding="UTF-8"?>
  <!-- roqwiki settings -->
  <parameters>
    <!-- allow_edit=0 to remove the "Edit this Page" link -->
    <!-- allow_edit=1 to add the "Edit this Page" link -->
    <allow_edit>1</allow_edit>
    <!-- "Deploy Page" only shown if allow_edit=1 -->
    <deploy_location>../</deploy_location>
    <!-- Exclude files from group deploy: exclude_files=file1,file2,...filex -->
    <exclude_files>wiki.html</exclude_files>
  </parameters>

  If your source contains comments that you don't want visible
  to the word, you should password-protect the created "source"
  directory.

=head2 Roqet Document Format

  The format of an  Roqet Document Format is as follows:
  - (comment)
  @ heading (heading) 
  * bullet (depreciated)
  *** bullet (new style)
  *-* horizontal line
  command = description and [examples] (descriptive line)
  [code]
  {{link~~linkname}} 
  {*imagelink*} 
  [[
  preformatted block (puts in <pre></pre> tag block)
  ]]
  - -->import:filename to import an external file

=head2 The Template File

  RoqWiki will generate an HTML Template File, you can then modify it to
  include whatever you want (Google search for example). The template must
  contain these tags
  (*title*)
  (*body*)
  (*draftdate*)

=head1 To Do

  Add more meta pages:
    switch to using markdown
    grep (search)
    help (can build into about perhaps)

=head1 ChangeLog

  2008-04-16 :: 1.0 :: Initial release some code came from roqdocbuild.pl
  2008-04-17 :: 1.1 :: Bugfixes on display, create and URI limits
  2008-04-18 :: 1.2 :: Tweaks on formatting
  2008-05-19 :: 1.3 :: Added a body div for more refined formatting
  2008-06-06 :: 1.4 :: Added build all functionality
  2008-06-13 :: 1.5 :: Cleaned up code to use template for all page builds
  2009-05-11 :: 1.6 :: Changed info tag about imports not being within pre tags
  2009-06-03 :: 1.7 :: Added new-style bullets and horizontal lines.
  2009-12-23 :: 1.8 :: Added ability to deploy a single page to another location.
  2009-12-23 :: 1.9 :: Changed parameter file to be an xml file and to deploy multiple files.
  2010-04-01 :: 2.0 :: Modified to have a metadata page instead of a generated about page.
  2012-07-26 :: 2.1 :: Migrated to github prior to proposed markdown coversion.

=head1 Author

  roqet <http://www.roqet.org>

=head1 Copyright

  RoqWiki Perl script copyright 2012 roqet <http://www.roqet.org>.
  RoqWiki can be distributed and modified under the terms of the
  GNU General Public License: http://www.gnu.org/copyleft/gpl.html

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
  GNU General Public License for more details.

  Updates and other scripts and software available at:
  http://www.roqet.org/software.html
   ~~~
   'l'
    -

=cut

use CGI qw/:standard/;
use File::Copy;
use XML::Simple;
&parseform;

$allowedit = 1;
$deploylocation = '../';

$paramfile = XMLin('./roqwiki.xml');
$allowedit = $paramfile->{allow_edit};
$deploylocation = $paramfile->{deploy_location};

$sourcedir = "./source/";

if (!$key) {
  ( $val1, $val2, $val3 ) = split( /\//, $ENV{'SCRIPT_URL'} );
  $key = $val3;
  #print "Content-type:text/html\n\n";
  #print "$val1, $val2, $val3\n\n";
  #print "</html>";
}

if (!$key) {
  &indexcheck;  
}
elsif ($key eq 'create') {
  # create a new .txt file and 
  # generate a new .html file
  open(OUTSOURCE,">$sourcedir" . "$value.txt") || die "error opening $sourcedir" . "$value.txt: $!\n";
  print OUTSOURCE '-= ' . $value . ' =-' . "\n\n";
  &getnotes;
  print OUTSOURCE $notes;
  print OUTSOURCE '@ New Page' . "\n";
  print OUTSOURCE '----------' . "\n";
  print OUTSOURCE 'ready for your modifications.' . "\n";
  close OUTSOURCE;
  print "Content-type:text/html\n\n";
  undef (@body);
  push (@body, '<form action="./index.cgi" method="post">' . "\n");
  push (@body, '<textarea rows="20" cols="80" name="update--' . $value . '">' . "\n");
  open(INSOURCE,"<$sourcedir" . "$value.txt") || die "error opening $sourcedir" . "$value.txt: $!\n";
  @insource = <INSOURCE>;    
  close INSOURCE;
  foreach $inline (@insource) {
    push (@body, "$inline");
  }
  push (@body, '</textarea>' . "\n");
  push (@body, '<input type="submit" value="Submit">' . "\n");
  push (@body, '</form>' . "\n");
  &readtemplate;
  $titleval = 'Editing ' . $value . ' Page';
  foreach $item (@templatefile) {
    $item =~ s/\(\*title\*\)/$titleval/g;
    if ($item =~ /\(\*body\*\)/) {
      #$item =~ s/\(\*body\*\)/@body/g;
      # need to do this as the above line caused a preceeding space
      $item =~ s/\(\*body\*\)//g;
      foreach $bit (@body) {
        print "$bit";
      }
    }
    $item =~ s/\(\*draftdate\*\)//g; 
    if ( $item =~ '<address>' ) { print '<address>A <a href="./index.cgi?about">roqwiki</a> Edit page</address>' . "\n"; }
    else { print "$item"; }
  }
}
elsif ($key eq 'filename') {
  # display page
  print "Content-type:text/html\n\n";
  print "query: " . $ENV{'SCRIPT_URI'};
  print "value: $value";
  print "</html>";
}
elsif (substr($key,0,6) eq 'update') { 
  # save changes and display page again here
  ( $val1, $sourcename ) = split( /\-\-/, $key );
  open(OUTSOURCE,">$sourcedir" . "$sourcename.txt") || die "error opening $sourcedir" . "$sourcename.txt: $!\n";
  print OUTSOURCE $value;
  close OUTSOURCE;
  &generatehtml($sourcename);
  &displaypage($sourcename);
}
elsif ($key eq 'edit') {
  # display source code in edit box
  print "Content-type:text/html\n\n";
  undef (@body);
  push (@body, '<form action="./index.cgi" method="post">' . "\n");
  push (@body, '<textarea rows="20" cols="80" name="update--' . $value . '">' . "\n");
  open(INSOURCE,"<$sourcedir" . "$value.txt") || die "error opening $sourcedir" . "$value.txt: $!\n";
  @insource = <INSOURCE>;    
  close INSOURCE;
  foreach $inline (@insource) {
    push (@body, "$inline");
  }
  push (@body, '</textarea>' . "\n");
  push (@body, '<input type="submit" value="Submit">' . "\n");
  push (@body, '</form>' . "\n");
  &readtemplate;
  $titleval = 'Editing ' . $value . ' Page';
  foreach $item (@templatefile) {
    $item =~ s/\(\*title\*\)/$titleval/g;
    if ($item =~ /\(\*body\*\)/) {
      #$item =~ s/\(\*body\*\)/@body/g;
      # need to do this as the above line caused a preceeding space
      $item =~ s/\(\*body\*\)//g;
      foreach $bit (@body) {
        print "$bit";
      }
    }
    $item =~ s/\(\*draftdate\*\)//g; 
    if ( $item =~ '<address>' ) { print '<address>A <a href="./index.cgi?about">roqwiki</a> Edit page</address>' . "\n"; }
    else { print "$item"; }
  }
}
elsif ($key eq 'deploy') {
  # copy page to deploy location
  print "Content-type:text/html\n\n";
  undef (@body2);
  push (@body2, '<h2>Deploy Wiki Page</h2>' . "\n");
  push (@body2, "<ul>\n");
  push (@body2, "</ul>\n");
  copy("$value.html", $deploylocation) or warn "$value.html cannot be copied.";
  push (@body2, "$value has been deployed to $deploylocation\n");
  &readtemplate;
  foreach $item (@templatefile) {
    $item =~ s/\(\*title\*\)/Deploy Complete/g;
    if ($item =~ /\(\*body\*\)/) {
      #$item =~ s/\(\*body\*\)/@body/g;
      # need to do this as the above line caused a preceeding space
      $item =~ s/\(\*body\*\)//g;
      foreach $bit (@body2) {
        print "$bit";
      }
    }
    if ( $item =~ '<address>' ) { print '<address>A <a href="./index.cgi?about">roqwiki</a> Metadata page</address>' . "\n"; }
    else { print "$item"; }
  }
}
elsif ($key eq 'doclist') {
  # list all wiki pages
  print "Content-type:text/html\n\n";
  undef (@body);
  push (@body, '<h1>List of Wiki Pages</h1>' . "\n");
  push (@body, "<ul>\n");
  opendir(DIR, "$sourcedir") or die "can't open directory $sourcedir: $!";
  $filecount = 0;
  while (defined($file = readdir(DIR))) {
    if ($file =~ /.txt/) {
      $file =~ s/.txt//;
	  push (@body, "<li><a href=\"./index.cgi\?$file\"\>$file<\/a><\/li>\n");
	  $filecount++;
	}
  }
  closedir(DIR);
  push (@body, "</ul>\n");
  push (@body, "<p><b>Total: $filecount pages.<\/b><\/p>\n");
  &readtemplate;
  foreach $item (@templatefile) {
    $item =~ s/\(\*title\*\)/RoqWiki List of Pages/g;
    $item =~ s/\(\*body\*\)/@body/g;
    if ( $item =~ '<address>' ) { print '<address>A <a href="./index.cgi?about">roqwiki</a> Metadata page</address>' . "\n"; }
    else { print "$item"; }
  }
}
elsif ($key eq 'buildall') {
  # build all wiki pages
  print "Content-type:text/html\n\n";
  undef (@body2);
  push (@body2, '<h2>Rebuilding All Wiki Pages</h2>' . "\n");
  push (@body2, "<ul>\n");
  opendir(DIR, $sourcedir) or die "can't open source directory: $!";
  $filecount = 0;
  while (defined($file = readdir(DIR))) {
    if ($file =~ /.txt/) {
      $file =~ s/.txt//;
      &generatehtml($file);
      $file =~ s/.txt//;
	  push (@body2, "<li><a href=\"./index.cgi\?$file\"\>$file<\/a><\/li>\n");
	  $filecount++;
	}
  }
  closedir(DIR);
  push (@body2, "</ul>\n");
  push (@body2, "<p><b>Rebuilt $filecount pages.<\/b><\/p>\n");
  &readtemplate;
  foreach $item (@templatefile) {
    $item =~ s/\(\*title\*\)/RoqWiki Build All Pages/g;
    if ($item =~ /\(\*body\*\)/) {
      #$item =~ s/\(\*body\*\)/@body/g;
      # need to do this as the above line caused a preceeding space
      $item =~ s/\(\*body\*\)//g;
      foreach $bit (@body2) {
        print "$bit";
      }
    }
    if ( $item =~ '<address>' ) { print '<address>A <a href="./index.cgi?about">roqwiki</a> Metadata page</address>' . "\n"; }
    else { print "$item"; }
  }
}
elsif ($key eq 'deployall') {
  # deploy all wiki pages
  print "Content-type:text/html\n\n";
  undef (@body2);
  push (@body2, '<h2>Deploying All Wiki Pages</h2>' . "\n");
  push (@body2, "<ul>\n");
  opendir(DIR, "./") or die "can't opendir ./: $!";
  $filecount = 0;
  while (defined($file = readdir(DIR))) {
    if ($file =~ /.html/) {
      $copy = 1;
      foreach $excluded (@excludefiles) {
        if ($excluded eq $file) {
          $copy = 0;
          last;
        }
      }
      if ($copy) {
 	    push (@body2, "<li>Deploying <a href=\"./index.cgi\?$file\"\>$file<\/a><\/li>\n");
        copy($file, $deploylocation) or warn "$file cannot be copied.";
 	    $filecount++;
      }
    }
  }
  closedir(DIR);
  push (@body2, "</ul>\n");
  push (@body2, "<p><b>Deployed $filecount pages.<\/b><\/p>\n");
  &readtemplate;
  foreach $item (@templatefile) {
    $item =~ s/\(\*title\*\)/RoqWiki Deploy All Pages/g;
    if ($item =~ /\(\*body\*\)/) {
      #$item =~ s/\(\*body\*\)/@body/g;
      # need to do this as the above line caused a preceeding space
      $item =~ s/\(\*body\*\)//g;
      foreach $bit (@body2) {
        print "$bit";
      }
    }
    if ( $item =~ '<address>' ) { print '<address>A <a href="./index.cgi?about">roqwiki</a> Metadata page</address>' . "\n"; }
    else { print "$item"; }
  }
}
elsif ($key eq 'about') {
  # wiki general info
  print "Content-type:text/html\n\n";
  undef (@body2);
  push (@body2, '<h1>About RoqWiki</h1>' . "\n");
  push (@body2, '<p>This is the <a href="http://roqet.org/roqwiki.html">RoqWiki</a> wiki application. The latest version is available <a href="http://www.roqet.org/software.html">here</a></p>' . "\n");
  push (@body2, '<li />Wiki Metadata' . "\n");
  push (@body2, '<p><a href="./index.cgi?doclist">View all Wiki Pages</a></p>' . "\n");
  push (@body2, '<p><a href="./index.cgi?buildall">Rebuild ALL Wiki Pages</a></p>' . "\n");
  push (@body2, '<p><a href="./index.cgi?deployall">Deploy ALL Wiki Pages</a></p>' . "\n");
  &readtemplate;
  foreach $item (@templatefile) {
    $item =~ s/\(\*title\*\)/About RoqWiki/g;
    $item =~ s/\(\*body\*\)/@body2/g;
    if ( $item =~ '<address>' ) { print '<address>A <a href="./index.cgi?about">roqwiki</a> Metadata page</address>' . "\n"; }
    else { print "$item"; }
  }
}
elsif (-f "./source/$key.txt") {
  # display actual page here
  &displaypage($key);
}
else {
  print "Content-type:text/html\n\n";
  undef (@body);
  if ( $allowedit ) { 
    push (@body, "\<p\>This page has not yet been created \<a href=\"./index.cgi\?create\=$key\">Create it?\<\/a\>\<\/p\>");
  }
  else {
    push (@body, "\<p\>This page has not yet been created.\<\/p\>");
  }
  &readtemplate;
  foreach $item (@templatefile) {
    $item =~ s/\(\*title\*\)/New Roqwiki Page/g;
    $item =~ s/\(\*body\*\)/@body/g;
    $item =~ s/\(\*draftdate\*\)//g; 
    if ( $item =~ '<address>' ) { print ' ' . "\n"; }
    else { print "$item"; }
  }
}

###############
#             #
# subroutines #
#             #
###############

sub parseform
{                                    
  if( $ENV{'REQUEST_METHOD'} eq 'GET' ) 
  {	@pairs = split( /&/, $ENV{'QUERY_STRING'} ); }   
  elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) 
  {                                                   
	read( STDIN, $buffer, $ENV{'CONTENT_LENGTH'} );
	@pairs = split( /&/, $buffer );                          	
	if( $ENV{'QUERY_STRING'} ) 
	{ @getpairs = split( /&/, $ENV{'QUERY_STRING'} );
	  push( @pairs, @getpairs ); }
  }                                                 
  else 
  {                                               
    print "Content-type:text/html\n\n";            
    print "Unrecognized Method - Use GET or POST.";
  }                                                                                                     
  foreach $pair( @pairs ) 
  {                                           
    ( $key, $value ) = split( /=/, $pair );
    $key =~ tr/+/ /;	
    $value =~ tr/+/ /;                                   
    $key =~ s/%(..)/pack("c", hex($1))/eg;                                       
    $value =~ s/%(..)/pack("c", hex($1))/eg;         
    $value =~ s/<!--(.|\n)*-->//g;  		# ignore SSI
    if( $formdata{$key} ){$formdata{$key} .= ", $value";}                                                    
    else{ $formdata{$key} = $value; }                         
  } 
}

sub displaypage {
  local($pagename) = @_;
  print "Content-type:text/html\n\n";
  open INFILE, "./$pagename.html" or die "error opening $pagename.html: $!\n";
  @infile = <INFILE>;    
  close INFILE;
  #$outdate = &draftdate('draft');
  $edit = '';
  foreach $inline (@infile) {
    if ( $inline =~ '<address>' ) { 
      if ( $allowedit ) { 
        $edit = '<a href="./index.cgi?edit=' . $pagename . '">Edit this page?</a>' . ' <a href="./index.cgi?deploy=' . $pagename . '">Deploy this page?</a>';
      }
      $inline =~ s/\<\!\-\-\(\*edit\*\)\-\-\>/$edit/g;           
      print "$inline";
    }
    else {
      print "$inline";
    }
  }
}

sub indexcheck {
  # if index page doesn't exist, create and display it here
  &createfiles;
  print "Content-type:text/html\n\n";
  open INFILE, "./index.html" or die "error opening index.html: $!\n";
  @infile = <INFILE>;    
  close INFILE;
  foreach $inline (@infile) {
    print "$inline";
  }
}

sub readtemplate {
  open TEMPLATE, "$sourcedir" . "wiki_template.html" or die "error opening $sourcedir" . "wiki_template.html: $!\n";
  @templatefile = <TEMPLATE>;    
  close TEMPLATE;
}

sub getnotes {
  $notes = '- Roqet Document Format v2.0. Notes:' . "\n" .
    '- examples are in []s' . "\n" .
    '- this document is formatted in Roqet Document Format which can easily be' . "\n" .
    '- converted to html using RoqWiki which is available here:' . "\n" .
    '- http://www.roqet.org/software.html' . "\n" .
    '- The Roqet Document Format is as follows:' . "\n" .
    '- - (comment)' . "\n" .
    '- @ heading (heading)' . "\n" .
    '- * bullet' . "\n" .
    '- command = description and [examples] (descriptive line)' . "\n" .
    '- [code]' . "\n" .
    '- {{link~~linkname}} ' . "\n" . 
    '- {*imagelink*} ' . "\n" .
    '- [[' . "\n" .
    '- preformatted block (puts in <pre></pre> tag block)' . "\n" .
    '- ]]' . "\n" .
    '- -->import:filename to import an external file' . "\n\n";
}    

sub checksourcedir {
  umask(000); # UNIX file permission junk
  mkdir($sourcedir, 0755) unless (-d $sourcedir);
}

sub createfiles {
  &checksourcedir;
  if (-f "$sourcedir" . "wiki_template.html") {
    &readtemplate;
  }
  else {
    open(TEMPLATE,">$sourcedir" . "wiki_template.html") || die "error opening $sourcedir" . "wiki_template.html: $!\n";
    print TEMPLATE '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">' . "\n";
    print TEMPLATE '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">' . "\n";
    print TEMPLATE '<html>' . "\n";
    print TEMPLATE '  <head>' . "\n";
    print TEMPLATE '    <title>(*title*)</title>' . "\n";
    print TEMPLATE '    <meta name="robots" content="all" />' . "\n";
    print TEMPLATE '    <meta content="true" name="MSSmartTagsPreventParsing" />' . "\n";
    print TEMPLATE '    <link rel="icon" href="./favicon.ico" type="image/x-icon">' . "\n";
    print TEMPLATE '    <link rel="stylesheet" type="text/css" href="roqwiki.css" />' . "\n";
    print TEMPLATE '</head>' . "\n";
    print TEMPLATE '<body>' . "\n";
    print TEMPLATE '<div class="body">' . "\n";
    print TEMPLATE '    <div class="content">' . "\n";
    print TEMPLATE '    (*body*) ' . "\n";
    print TEMPLATE '    <address>This is a <a href="http://www.roqet.org/roqwiki.html">roqwiki</a> page. Published under <a href="./index.cgi?license">This License</a> on (*draftdate*). <a href="./index.cgi?about">About This Wiki</a>. <!--(*edit*)--></address>' . "\n";
    print TEMPLATE '    </div>' . "\n";
    print TEMPLATE '</div>' . "\n";
    print TEMPLATE '</body>' . "\n";
    print TEMPLATE '</html>' . "\n";
    close TEMPLATE;
  }
  if (!-f "./roqwiki.css") {
    open(CSS,">./roqwiki.css") || die "error opening roqwiki.css: $!\n";
    print CSS 'body { ' . "\n";
    print CSS '   margin: 1.5em 2em 1.5em 1.5em; ' . "\n";
    print CSS '   font-family: Georgia, sans-serif; ' . "\n";
    print CSS '}' . "\n\n";
    print CSS 'h1, h2 { ' . "\n";
    print CSS '   font-family: Tahoma, "Gill Sans", sans-serif; ' . "\n";
    print CSS '   font-weight: normal; ' . "\n";
    print CSS '}' . "\n\n";
    print CSS 'address { ' . "\n";
    print CSS '   font-size: small; ' . "\n";
    print CSS '   padding-top: 0.35em; ' . "\n";
    print CSS '   border-top: 2px solid #069; ' . "\n";
    print CSS '   font-style: normal; ' . "\n";
    print CSS '}' . "\n\n";
    print CSS 'pre { margin-left: 1.5em; }' . "\n\n";
    close CSS;
  }
  if (!-f "$sourcedir/index.txt") {
      close INDEX;
      open(OUTSOURCE,">$sourcedir" . "index.txt") || die "error opening $sourcedir" . "index.txt: $!\n";
      print OUTSOURCE '-= Wiki Home Page =-' . "\n\n";
      &getnotes;
      print OUTSOURCE $notes;
      print OUTSOURCE '@ Index Page of Your RoqWiki' . "\n";
      print OUTSOURCE '----------------------------' . "\n";
      print OUTSOURCE 'Edit it as you see fit.' . "\n";
      close OUTSOURCE;
      &generatehtml('index');
  }
}

sub generatehtml {
#
# builds html from roqet document format text file
#
  local($source) = @_;
  undef (@body);
  open(INSOURCE,"<$sourcedir" . "$source.txt") || die "error opening $sourcedir" . "$source.txt: $!\n";
  @insource = <INSOURCE>;    
  close INSOURCE;
  $pretag = 0;
  foreach $line (@insource) {
    chomp($line);
    if (substr($line,0,3) eq '-->') { 
      ($command,$filename) = split(/\:/,$line,2);
      #print "Importing: $filename... \n";    
      open IMPORT, $filename or warn "import failure error opening " . $filename . ": $!\n";
      @importfile = <IMPORT>;    
      close IMPORT;
      #push (@body, "<pre>\n");
      push (@body, "\n");
      foreach $impline (@importfile) {
        chomp($impline);
        push (@body, $impline . "\n");
      }
      #push (@body, "\n</pre>\n");
      push (@body, "\n\n");
      undef (@importfile);
    }
    elsif (substr($line,0,2) eq '-=') { 
      $line =~ s/\-\=//g;
      $line =~ s/\=\-//g;
      push (@body, "    <h1>$line</h1>\n");
    }
    elsif (substr($line,0,2) eq '* ') { 
      # old-style bullet - depreciated 
      $line =~ s/\* //g;
      push (@body, "    <li />$line\n");
    }
    elsif (substr($line,0,1) eq '-') { next; }
    elsif (substr($line,0,2) eq '@ ') { 
      $line =~ s/\@ //g;
      push (@body, "    <h2>$line</h2>\n");
    }
    elsif ($line ne ''){
      if ($line =~ /\[\[/){ 
        $pretag = 1; 
        push (@body, "<pre>\n");
      }
      elsif ($line =~ /\]\]/){
        $pretag = 0; 
        push (@body, "    </pre>\n");
      }
      elsif ( $pretag ){
        push (@body, $line  . "\n");
      }
      else {
        $line =~ s/\</\&lt\;/g;
        $line =~ s/\>/\&gt\;/g;
        $line =~ s/\>/\&gt\;/g;
        $line =~ s/  /\&nbsp\;/g;
        $line =~ s/\[/\<code\>/g;
        $line =~ s/\]/\<\/code\>/g;
        $line =~ s/\{\*/\<img src\=\"/g;
        $line =~ s/\*\}/\" border \=\"0\"\>/g;
        $line =~ s/\{\{/\<a href\=\"/g;
        $line =~ s/\~\~/\"\>/g;
        $line =~ s/\}\}/\<\/a\>/g;
        # new-style bullet
        $line =~ s/\*\*\* /    \<li \/\>/g;
        $line =~ s/\*\-\*/\<hr \/\>/g;
        if ($line =~ /\= /){ 
          ($comm,$desc) = split(/\=/,$line,2);
          push (@body, "    <p><b>$comm</b>: $desc</p>\n");
        #  $comm = '<b>' . $comm . '</b>';
        #  push (@body, "    <h4>$comm </h4>\n");
        #  push (@body, "    <p>$desc </p>\n    <p> </p>\n");
        }
        else {
          $comm = $line;
          $desc = '';
          push (@body, "    <p>\n    " . $comm . $desc . "\n    </p>\n");
        }
      }
    }	  
  }
  &readtemplate;
  open HTMLOUT, ">./$source.html" or die "error opening $source.html: $!\n";
  $outdate = &draftdate('draft');
  foreach $item (@templatefile) {
    $item =~ s/\(\*title\*\)/$source/g;
    if ($item =~ /\(\*body\*\)/) {
      #$item =~ s/\(\*body\*\)/@body/g;
      # need to do this as the above line caused a preceeding space
      $item =~ s/\(\*body\*\)//g;
      foreach $bit (@body) {
        print HTMLOUT "$bit";
      }
    }
    $item =~ s/\(\*draftdate\*\)/$outdate/g; 
    $item =~ s/\(\*key\*\)/$source/g; 
    print HTMLOUT "$item";
  }
  close HTMLOUT;  
}

sub draftdate {
#
# returns date & time, or year for the current draft
#
  local($type) = @_;
  ($dayofweek, $day, $month, $year, $hour, $minute, $second) = (localtime)[6,3,4,5,2,1,0];
  $date = sprintf("%04d-%02d-%02d", $year+1900, $month+1, $day);
  $time = sprintf("%02d:%02d:%02d", $hour, $minute, $second );
  if ($type eq 'draft') { return("$date $time"); }
  else { return($year+1900); }
}

