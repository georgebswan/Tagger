#! \strawberry\perl\bin\perl
    eval 'exec perl $0 ${1+"$@"}'
	if 0;

use strict refs;
use strict vars;
use strict subs;
use File::Basename;
use File::Copy;
use Image::MetaData::JPEG;
require "library.pl";


my $srcFolder;
my %cmdLine;


################################################################
# This script will find all of the directories in $srcFolder that match any
# of the names that are stored in file "$wantedFoldersFileName" that exists in the $srcFolder
# 
# Foreach directory found, copy all the contents over to $destFolder, while renumbering the files
#

MAIN: {
    my %switches = qw (
        -srcFolder required
        -help optional
    );

    %cmdLine = parseCommandLine( %switches );

    # For now, map the cmdLine back to variables. I should replace all the unique global variables, but
    # I can't be bothered at the moment
    $srcFolder = $cmdLine{ "srcFolder"};

    ## Check that the src folder exists, and the destination doesn't
    unless(-e $srcFolder) {
	print ("Source folder '$srcFolder' doesn't exist\n");
	exit 1;
    }

    print( "Processing Source Folder '$srcFolder'\n");
    processTopFolder ($srcFolder);

} # MAIN

################################################################
# processTopFolder
#

################################################################
sub processTopFolder {
    my ($path) = @_;
    my @contents = ();
    my $content;
    my $fileBaseName;
    my $dirName;
    my $fileExtension;
    

    ## append a trailing / if it's not there
    $path .= '\\' if($path !~ /\/$/);

    ## print the directory being searched
    print("Path is '$path'\n");

 
    ## First, find all the src folders and store them. Content in the field means 'not found'
    foreach $content (findDirContent($path)) {
	if (-d $content) { processTopFolder($content); }
	else {
	    ## check to see if the file is a photo, then copy it to destination
	    ($fileBaseName, $dirName, $fileExtension) = fileparse 
                       ($content, ('\.[^.]+$') );
	    print("\tFile bits are '$dirName', '$fileBaseName', '$fileExtension'\n");

	    if($fileExtension eq ".jpg" || $fileExtension eq ".JPG") {		#use an extension I prefer 
	        print("AAA - File name is '$content'\n");
	    }
	}
    }



}

################################################################
# processWantedFolder
################################################################
sub processWantedFolder {
    my ($topPath, $nameMatched) = @_;
    my @contents = ();
    my $content;
    my $fileBaseName;
    my $dirName;
    my $fileExtension;
    my $path;
    my $origName;
    my $photoCount = 0;

    ## append a trailing / if it's not there
    $topPath .= '\\' if($topPath !~ /\/$/);

    ## print the directory being searched
    ##print("\tProcessing sub folder'$topPath'\n");

    ## Now deal with all of the files before we start recursing
    ## down the dirs
    @contents = findDirContent($topPath);
    foreach $content (findDirContent($topPath)) {
	if( -f $content) {
	    ## check to see if the file is a photo
	    ($fileBaseName, $dirName, $fileExtension) = fileparse 
                       ($content, ('\.[^.]+$') );
	    #print("\tFile bits are '$dirName', '$fileBaseName', '$fileExtension'\n");

	    if($fileExtension eq ".jpg" || $fileExtension eq ".JPG") {
		# count it

		$photoCount++;
	    }
	}
    }

    foreach $content (@contents) {
	if( -d $content) {
	    ## here if a direcory. Recurse
	    $photoCount = $photoCount + processWantedFolder( $content, $nameMatched );
	}
    }

    return($photoCount);
}



