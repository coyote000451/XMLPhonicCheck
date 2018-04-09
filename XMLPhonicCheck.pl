#! c:\perl\bin\perl

################################################################################
# This script is for parsing out the XML Generic vs. the Phonic tags in XML
# It is trying to close the loop on the CR which found the title did not match
# with the phonic pronunciation
################################################################################
# Created 1/8/14
################################################################################
# Updates:
# 
################################################################################


use warnings;
use diagnostics;
use XML::Parser;
use XML::Simple;
use Data::Dumper;
use ReadDir;
use ReadFile;
use XMLScrape;
use Array::Utils qw(:all);      
use List::MoreUtils;

# Enter in Version as first argument
	$Version = $ARGV[0];

	if (! $Version)
	{
	printf "\<\n\nUSAGE:  Missing version i.e., 177 178 179...";
	exit;
	}

# Print output
$PRINT = "NO";
$NOPRINT = "YES";

# For now leave this as static defaulted to "NO"
$CHECKMATE = "NO";
$CHECKMATEFILE = "c:\\temp\\CheckMate.txt";

# Create a file to write if CHECKMATE is set
	if ($CHECKMATE eq "YES")
	{
		
# if the checkmate file exists, remove it
		if (-e "$CHECKMATEFILE")
		{
			unlink($CHECKMATEFILE);
		}
	open (FILE, ">>", $CHECKMATEFILE);
	}

# Set the leaflet path
	#$SGML = "\\\\bluffton\\ProdLeaflets\\Leaflets_v$Version\\SGML";
	#$SGML = "\\\\IPMULQA2K12R2-4\\C\\Temp\\Leaflets_v$Version\\SGML";
	$SGML = "\\\\ada\\1-qa\\Temp\\Leaflets_v$Version\\SGML";

# Added error handling to make sure the path exists
	if (!-d $SGML)
	{
		print "$SGML does not exist, GOODBYE\n";
		exit;
	}

# Read leaflets into @DirArray
	$TOP_DIR = ReadDir->new($SGML);
	@DirArray = $TOP_DIR->Directory();

# Set up the path for leaflets by adding "\\" so as to pass it to the XML object
	$DIR_PATH = $SGML."\\";

	for $file (@DirArray) 
	{
		if ($file =~ m/\.xml/) # Filter out the *.dtd
		{
			#if ($file =~ m/a1/ || $file =~ m/v1/ || $file =~ m/o1/) # Filter only on certain leaflet types
			#if ($file =~ m/a1/ || $file =~ m/a3/) # Filter only on certain leaflet types # removing spanish leaflets as they have no pronun
			if ($file =~ m/a1/)
			{
			$SCRAPE = XMLScrape->new($DIR_PATH, $file);
			$booklist = $SCRAPE->scrape();
			
				if ($PRINT eq "YES")
				{
					print Dumper($booklist);
					print "$file | ", $booklist->{Pronounce}. " | ". $booklist->{Generic}, "\n";
				}
			
# Take the extracted files from the directory and load then to an array "@VerArray"
			$RowCheck = $file."|".$booklist->{Pronounce}."|".$booklist->{Generic};
			push (@VerArray, $RowCheck);
			
# If we want to create a new checkmate file
				if ($CHECKMATE eq "YES")
				{
					print FILE $file, "|", $booklist->{Pronounce}. "|". $booklist->{Generic}, "\n";
					#print FILE $file, "|", $booklist->{Pronounce}. "|". $booklist->{Generic}, "|", $booklist->{Attribute icontype="dizzy"},"\n";
				}	
			}
		}
	}
	
	if ($CHECKMATE eq "YES")
	{
	close (FILE);
	}
	
# Temporary to check array values

if ($PRINT eq "YES")
{
	for $tfile (@VerArray)
	{
		print "From SGML:  $tfile\n";
	}
}

# Read the checkmate file into an array
 	$file = ReadFile->new($CHECKMATEFILE);
 	@FileArray = $file->GetFile();

if ($PRINT eq "YES")
{
 	for $files (@FileArray)
 	{
		print "From CHECKMATE:  $files\n";
 	}
}

 # Build and send the two arrays to a comparison object
 
 	my @diff = array_diff(@FileArray, @VerArray);
 	
 	foreach my $name (@diff)
	{

		my $index = List::MoreUtils::first_index {$_ eq $name} @FileArray;
		
		if ($index > 1)
		{
			push (@Checkmate, "Checkmate|$name");
		}
		elsif ($index < 0)
		{
			push (@Leaflet, "Leaflet|$name");
		}

	}


# This really just concatonates the two arrays from above
	
	@ndiff = array_diff(@Checkmate, @Leaflet);
	
	foreach my $fname (@ndiff)
	{
		my $index = List::MoreUtils::first_index {$_ eq $fname} @Checkmate;
		
		my @values = split('\|',$fname);
		
			foreach my $val (@values)
			{
				if ($val =~ m/xml/)
				{
					push (@Dnum, $val);
				}
			}
	}


@Dnum1 = unique(@Dnum,@Dnum); # Remove the duplicates from the array performing union on itself

# This finds the updates
foreach $dfile (@Dnum1)
{ 
	foreach $cfile (@Checkmate)
	{	
		if ($cfile =~ m/$dfile/) 
		{
			foreach $lfile (@Leaflet)
			{ 
				if ($lfile =~ m/$dfile/) 
				{

					push (@UPDATE, $dfile);
					
					$UPDATEOUT = $cfile.$lfile;
					push (@UPDATEOUTPUT, $UPDATEOUT);
					last;
				}
			}
		}
	}
}

@Dnum2 = array_diff(@Dnum1, @UPDATE); # this will remove the updates from the dnum list

foreach $dfile2 (@Dnum2)
{ 
	foreach $cfile (@Checkmate)
	{	
		if ($cfile =~ m/$dfile2/) 
		{
			foreach $lfile (@Leaflet)
			{ 
				if ($lfile !~ m/$dfile2/) 
				{
					push (@DELETION, $dfile2);
					
					$DELETEOUT = $cfile;
					push (@DELETEOUTPUT, $DELETEOUT);
					last;
				}
			}
		}
	}
}

@Dnum3 = array_diff(@Dnum2, @DELETION); # Remove the already identified deletions

foreach $dfile3 (@Dnum3)
{ 
	foreach $cfile (@Checkmate)
	{	
		if ($cfile !~ m/$dfile3/) 
		{
			foreach $lfile (@Leaflet)
			{ 
				if ($lfile =~ m/$dfile3/) 
				{

					push (@NEW, $dfile3);
					
					$NEWOUT = $lfile;
					push (@NEWOUTPUT, $NEWOUT);
					last;
				}
			}
		}
	}
}

if ($NOPRINT eq "NO")
{
	foreach $one (@UPDATE) 
	{
		print "$one UPDATE\n";
	}
	foreach $two (@DELETION) 
	{
		print "$two DELETION\n";
	}

	@NEWNEW = unique(@NEW, @NEW);

	foreach $three (@NEWNEW) 
	{
		print "$three NEW\n";
	}
}
foreach $four (@UPDATEOUTPUT)
{
	$four =~ s/Checkmate/UPDATE/g;
	$four =~ s/Leaflet//g;
	print "$four\n";
}

foreach $five (@DELETEOUTPUT)
{
	$five =~ s/Checkmate/DELETE/g;
	print "$five\n";
}

@NEWNEWOUTPUT = unique(@NEWOUTPUT, @NEWOUTPUT);

foreach $six (@NEWNEWOUTPUT)
{
	$six =~ s/Leaflet/NEW/g;
	print "$six\n";
}


