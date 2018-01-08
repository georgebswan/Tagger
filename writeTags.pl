#! \strawberry\perl\bin\perl
    eval 'exec perl $0 ${1+"$@"}'
	if 0;

use strict refs;
use strict vars;
use strict subs;
use File::Basename;
use File::Copy;
use lib 'D:\Aberscan\PerlApplications\PerlLibrary';
require "library.pl";

my $tagFile;

# Global Variables - initialized in parseCorecommandLine
my %cmdLine;
my $maxTagsInLine = 20;

########################################################################
# This script tags photos with the info contained in the csv file
########################################################################

MAIN: {
    my @tags;
    my $tagFileName;
    my $srcFolderName;
    my $destFolderName;
    my %tagLine;
    my $i = 0;
    my $tagCount = 0;
    my $photoMappingFile;
    

    my %switches = qw (
        -tagFileName required
	-srcFolder required
	-destFolder optional
	-photoMappingFile optional
    );

    %cmdLine = parseCommandLine( %switches );

    # For now, map the cmdLine back to variables. I should replace all the unique global variables, but
    # I can't be bothered at the moment
    $tagFileName = $cmdLine{ "tagFileName"};
    $srcFolderName = $cmdLine{ "srcFolder"};
    $destFolderName = $cmdLine{ "destFolder"};
    $photoMappingFile = $cmdLine{ "photoMappingFile"};

    #if destFolderName was not specified on the cmd line, then make it the same as the srcFolder
    if($destFolderName == "") {
        $destFolderName = "$srcFolderName\\tagged";
    }
    else {
        $destFolderName = "$destFolderName\\tagged";
    }

    #change the default name of the photoMappingFile so that in a copy of tagging folder to enhancedScans, we don't overwrite
    #the photoMappingfile that is there.
    $photoMappingFile =~ s/Mappings/Taggings/g;

    @tags = readTagFile ($tagFileName);

    $tagCount = scalar (@tags);

    #print out the tags
    print("Found $tagCount tags:\n");
    for($i = 0 ; $i < $tagCount ; $i++) {
	%tagLine = @{$tags[$i]};
	printtagInfo(%tagLine);
    }

    # Check that the src folder exists, and the final doesn't
    unless(-e $srcFolderName) {
	print ("Source folder '$srcFolderName' doesn't exist\n");
	exit 1;
    }

    # create the dest folder
    if(createDestinationFolder( $destFolderName ) == 0) {
	 exit 2;
    }

    #tag the files
    tagFiles( $srcFolderName, $destFolderName, $photoMappingFile, @tags);


} # MAIN



################################################################
# tagFiles
#
# This function adds the relevant tags to the photo
################################################################
sub tagFiles {
    my ($srcFolderName, $destFolderName, $photoMappingFile, @tags) = @_;
    my $i;
    my $tagCount;
    my %tagLine;
    my $jpgSrcPhoto;
    my $photo;
    my $destPhoto;
    my $tag;
    my $cmd;
    my $mapFile;
    my $exiv2Exe = "exiv2.exe";
    my $tagKeyword = "Iptc.Application2.Keywords";
    my $i;
    my $j;
    my $k;
    my $tag;
    my @gentags;
    my $gentagCount;
    my %gentagLine;


    # open the mapping file
    open($mapFile, '>', "$destFolderName\\$photoMappingFile") or die "Can't open '$destFolderName\\$photoMappingFile' for write: $!"; 

    $tagCount = scalar (@tags);
    for($i = 0 ; $i < $tagCount ; $i++) {
	%tagLine = @{$tags[$i]};

	#find the jpg file if one exists
	$jpgSrcPhoto = sprintf("%s\\%s", $srcFolderName, $tagLine{"photo"});
	#$jpgSrcPhoto = sprintf("%s\\photo%04d.jpg", $srcFolderName, $tagLine{"photo"});

	if(-e $jpgSrcPhoto) {
	    #here if the jpg file was found.

	    #create destination photo name and check if we have it already
    	    $destPhoto = generatePhotoName( $destFolderName, %tagLine);
    	    #$destPhoto = generatePhotoName( $destFolderName, "jpg", %tagLine);
	    tagFile($jpgSrcPhoto, $destPhoto, $mapFile, %tagLine);
	}
	else {
	    $photo = sprintf("Could not find photo jpg version '%s'\n", $jpgSrcPhoto);
 	    printError($photo, %tagLine);
	}
    }

    close ($mapFile);
}

################################################################
# tagFile
#
# 
#
################################################################
sub tagFile{
    my ($srcPhoto, $destPhoto, $mapFile, %tagLine) = @_;
    my $i;
    my $exiv2Exe = "exiv2.exe";
    my $tagKeyword = "Iptc.Application2.Keywords";
    my $tag;
    my $key;

    #do the copy
    copy($srcPhoto, $destPhoto) or die "File '$srcPhoto' cannot be copied.";

    print("Tagging '$destPhoto'\n");

    $tag = $tagLine{"tag0"};
    system("$exiv2Exe -M\"set $tagKeyword $tag\" \"$destPhoto\" ");

    # Iterate through the tags
    for($i = 1 ; $i < $maxTagsInLine ; $i++) {
	$key = sprintf("tag%d", $i);
    	if($tagLine{"$key"} ne "") {
    	    $tag = $tagLine{$key};
    	    system("$exiv2Exe -M\"add $tagKeyword $tag\" \"$destPhoto\" ");
	}
    }

    #print the index to the mappingFile so that I have a record of what was tagged
    $tag = $destPhoto . "-> ";
    for($i = 0 ; $i < $maxTagsInLine ; $i++) {
	$tag = $tag . $tagLine{"tag$i"} . " : ";
    }

    print $mapFile "$tag\n"; 
}



################################################################
# generatePhotoName
#
# 
#
################################################################
sub generatePhotoName{
    my ($destFolderName, %tagLine) = @_;
    my $name;

    $name = sprintf("%s\\%s", $destFolderName, $tagLine{"photo"});
    #$name = sprintf("%s\\photo%04d.%s", $destFolderName, $tagLine{"photo"}, $ext);

    return($name);
}


################################################################
# readtagFileName
#
# This function reads the tag from the input file and
# returns a two dimensional array containing the info
################################################################
sub readTagFile {
    my ($tagFileName) = @_;
    my $line;
    my @tags;
    my @tagLine;
    my @tmp;
    my $count = 0;
    my $i;

    # open up the mapping file in the output folder
    open(IN, "$tagFileName") or die "Can't open '$tagFileName' for read: $!";

    # ignore the first 2lines
    $line = <IN>;
    $line = <IN>;
    while ($line = <IN>) {
	@tmp = split(/, */,$line);

	# check to see if the line was empty
	#if($tmp[1] ne "") {
	if(1==1) {
	    # first, go through each tag and strip off any leading or ending quotes
	    for($i = 1 ; $i <= $maxTagsInLine ; $i++) {
		$tmp[$i] =~ s/^"+//g;
		$tmp[$i] =~ s/"+$//g;
	    }

	    @tagLine = ("photo", $tmp[0],
			"tag0", $tmp[1], 
			"tag1", $tmp[2], 
			"tag2", $tmp[3],  
			"tag3", $tmp[4], 
			"tag4", $tmp[5], 
			"tag5", $tmp[6], 
			"tag6", $tmp[7], 
			"tag7", $tmp[8],
			"tag8", $tmp[9],
			"tag9", $tmp[10],
			"tag10", $tmp[11],
			"tag11", $tmp[12],
			"tag12", $tmp[13],
			"tag13", $tmp[14],
			"tag14", $tmp[15],
			"tag15", $tmp[16],
			"tag16", $tmp[17],
			"tag17", $tmp[18],
			"tag18", $tmp[19],
			"tag19", $tmp[20]
			 );


	    #load the array - I should be able to do this in a simpler way, but I can't figure it out
	    $tags[$count][0] = @tagLine[0];
	    $tags[$count][1] = @tagLine[1];
	    $tags[$count][2] = @tagLine[2];
	    $tags[$count][3] = @tagLine[3];
	    $tags[$count][4] = @tagLine[4];
	    $tags[$count][5] = @tagLine[5];
	    $tags[$count][6] = @tagLine[6];
	    $tags[$count][7] = @tagLine[7];
	    $tags[$count][8] = @tagLine[8];
	    $tags[$count][9] = @tagLine[9];
	    $tags[$count][10] = @tagLine[10];
	    $tags[$count][11] = @tagLine[11];
	    $tags[$count][12] = @tagLine[12];
	    $tags[$count][13] = @tagLine[13];
	    $tags[$count][14] = @tagLine[14];
	    $tags[$count][15] = @tagLine[15];
	    $tags[$count][16] = @tagLine[16];
	    $tags[$count][17] = @tagLine[17];
	    $tags[$count][18] = @tagLine[18];
	    $tags[$count][19] = @tagLine[19];
	    $tags[$count][20] = @tagLine[20];
	    $tags[$count][21] = @tagLine[21];
	    $tags[$count][22] = @tagLine[22];
	    $tags[$count][23] = @tagLine[23];
	    $tags[$count][24] = @tagLine[24];
	    $tags[$count][25] = @tagLine[25];
	    $tags[$count][26] = @tagLine[26];
	    $tags[$count][27] = @tagLine[27];
	    $tags[$count][28] = @tagLine[28];
	    $tags[$count][29] = @tagLine[29];
	    $tags[$count][30] = @tagLine[30];
	    $tags[$count][31] = @tagLine[31];
	    $tags[$count][32] = @tagLine[32];
	    $tags[$count][33] = @tagLine[33];
	    $tags[$count][34] = @tagLine[34];
	    $tags[$count][35] = @tagLine[35];
	    $tags[$count][36] = @tagLine[36];
	    $tags[$count][37] = @tagLine[37];
	    $tags[$count][38] = @tagLine[38];
	    $tags[$count][39] = @tagLine[39];
	    $tags[$count++][40] = @tagLine[40];
	}
    }
    close( IN );

    return(@tags);

}


################################################################
# printtagInfo
#   Dumps tagInfo to the screen for debug
#
################################################################
sub printtagInfo {
        my (%tagLine) = @_;
        my $i;

	#print the contents of the tagInfo
	print("$tagLine{\"photo\"}");
	for($i = 0 ; $i < $maxTagsInLine ; $i++) {
	    print(" ; $tagLine{\"tag$i\"}");
	}
	print("\n"); 

}

################################################################
# printError
#   
#
################################################################
sub printError {
    my ($error, %tagLine) = @_;

    print("ERROR======================================================================\n");
    print("$error\n");
    printtagInfo(%tagLine);
    print("ERROR======================================================================\n");  
} 

 


