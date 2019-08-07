#! /usr/bin/perl
# 
# MODIFICATION HISTORY
# 20080218,ylc,Changed to relative path, and code clean up.
# 20080131,tj,Documentation, refactoring changes, stricter cmd-line
# 20080131,tj,Backslash to forward-slash conversion needed
# 20080130,ylc,Initial version to restoreitem
#

do 'bmpic.pl';

# perl restoreitem.pl E:\BMPIC\LAB\TestArea\BMPIC_0_4 restoring an item
# goto the parentDirectory and open the BMPIC_Deletion.txt
# read the field using split for each line
#

###############################################
# Help display function
###############################################
sub SCRIPT_displayHelp()
{
	print("Restore the specified item and updates delete-tracker\n");
	print("Usage: $0 OPTIONS <ItemToRestore>\n");
	print("\nOPTIONS\n");
	print("NONE\n");
	print("\n");
	
	print("Notes:\n");
	print("Enter relative paths.\n");
	print("NONE\n");
	print("\n");
	
	print("Example: $0 CA_0_1 <Message>\n");
	print("\n");
	
	BMPIC_displayHelp();	
	print("\n");
	exit;
}

###############################################
# Variables
# Default parameters for script
###############################################

# NONE

sub SCRIPT_exportDefaults()
{
	# Framework-mandated step
	BMPIC_exportDefaults();
}

###############################################
# Parse the command-line for options
###############################################
sub SCRIPT_parseCommandLine()
{
	use Getopt::Std;
	
	$getoptSyntax = ''. $BMPIC_OPTIONS;
	
	$ok= getopts("$getoptSyntax",\%opt);
	
	if(!$ok)
	{
		print("Error parsing command-line for syntax $getoptSyntax\n\n");
	}
	
	if(@ARGV<1){
		print "Incorrect number of parameters!\n\n";
		$ok = 0;
	}
	
	if(!$ok  or exists $opt{'H'})
	{ 
		SCRIPT_displayHelp();
	}
	
	# Store the remaining stuff for later! :-)
	@SCRIPT_GETOPTVOMIT = @ARGV;
	
	print("$getoptSyntax\n") if $BMPIC_VERBOSE;
	
}

###############################################
# Configure based on parsed options
###############################################
sub SCRIPT_configure()
{
	# Framework-mandated step
	BMPIC_configure();
	
	# Get the rest of the parameters (non-getopt)
	($SCRIPT_RESTOREITEM, @SCRIPT_COMMENT) = @SCRIPT_GETOPTVOMIT; 
	
	$SCRIPT_RESTOREITEM = BMPIC_normalizePath($SCRIPT_RESTOREITEM);

}

###############################################
# Construct the command(s)
###############################################
sub SCRIPT_constructCommand()
{
	@SCRIPT_COMMANDLIST=();
	
	$SCRIPT_PARENTDIR = BMPIC_getParent($SCRIPT_RESTOREITEM);
	$SCRIPT_ITEM = BMPIC_getItemName($SCRIPT_RESTOREITEM);

	$SCRIPT_DELETEINFOFILE = $SCRIPT_PARENTDIR."/".$BMPIC_FILE_DELETES;	
	print ("BMPIC Delete info file is $SCRIPT_DELETEINFOFILE\n") if $BMPIC_DEBUG;
	
	if(BMPIC_doesItemExist($SCRIPT_DELETEINFOFILE)){
	$SCRIPT_COMMAND = "update $SCRIPT_DELETEINFOFILE";
	BMPIC_issueSVNCommand($SCRIPT_COMMAND);	
	}
	else{
		die "Delete Info File not found!\n";
	}
	
	open(FILE, "$SCRIPT_DELETEINFOFILE") or die "Couldn't open Delete Info file: $SCRIPT_DELETEINFOFILE!\n";
	@SCRIPT_FILELINES = <FILE>;
	close FILE;
	
	$SCRIPT_SEARCHINDEX = -1;
	$SCRIPT_FOUNDATLINE = -1;
	print ("SCRIPTITEM 	   $SCRIPT_ITEM\n\n") if $BMPIC_DEBUG;
	foreach $SCRIPT_FILELINE(@SCRIPT_FILELINES) {
	    chomp($SCRIPT_FILELINE);                  # no newline
	    $SCRIPT_SEARCHINDEX ++;
		$SCRIPT_FILELINES[$SCRIPT_SEARCHINDEX] = $SCRIPT_FILELINE;
		
		#  no comments
		if( $SCRIPT_FILELINE =~ m/^#.*/) {
			next;
		}
					
	 	$SCRIPT_FILELINE =~ s/^\s+//;               # no leading white
	    $SCRIPT_FILELINE =~ s/\s+$//;               # no trailing white
		$SCRIPT_FILELINES[$SCRIPT_SEARCHINDEX] = $SCRIPT_FILELINE;
   
	    # Split it into key/value
	    my ($REVNUM,$DATE,$ITEM) = split(/,/, $SCRIPT_FILELINE);
		print ("Revision Number is $REVNUM\n\n") if $BMPIC_DEBUG;
		print ("Date is 		   $DATE\n\n") if $BMPIC_DEBUG;
		print ("ITEM is 		   $ITEM\n\n") if $BMPIC_DEBUG;
		print ("SearchIndex 	   $SCRIPT_SEARCHINDEX\n\n") if $BMPIC_DEBUG;
		#if ($ITEM =~ m/\$SCRIPT_ITEM/i){
		if ($ITEM eq $SCRIPT_ITEM){
			$SCRIPT_REVNUM = $REVNUM;
			$SCRIPT_FOUNDATLINE = $SCRIPT_SEARCHINDEX;
			last;
		}
	}
	
	if ($SCRIPT_FOUNDATLINE == -1){
	die "No such item found!" ;
	}
	
	$SCRIPT_SRCPATH = $BMPIC_SVN_URL.$SCRIPT_RESTOREITEM;
	$SCRIPT_DESTPATH = $BMPIC_WCOPY.$SCRIPT_RESTOREITEM;
	
	print "Src path : $SCRIPT_SRCPATH\n" if $BMPIC_DEBUG;
	print "Dest path: $SCRIPT_DESTPATH\n" if $BMPIC_DEBUG;
		
	# Remove the found line 
	$SCRIPT_COMMAND = "copy -r $SCRIPT_REVNUM $SCRIPT_SRCPATH $SCRIPT_DESTPATH";
	push(@SCRIPT_COMMANDLIST, $SCRIPT_COMMAND);
	
	#after copy then svn add
	$SCRIPT_COMMAND = "add $SCRIPT_DESTPATH";
	push(@SCRIPT_COMMANDLIST, $SCRIPT_COMMAND);
	
	$SCRIPT_COMMAND = "commit $SCRIPT_DESTPATH -m \"@SCRIPT_COMMENT - BMPIC Script \"";
	push(@SCRIPT_COMMANDLIST, $SCRIPT_COMMAND);
	
	
}

###############################################
# Execute the constructed command(s)
# operates on @SCRIPT_COMMANDLIST
###############################################
sub SCRIPT_issueCommand()
{
	foreach (@SCRIPT_COMMANDLIST) {
		#Get the command
		$SCRIPT_COMMAND = $_;
		BMPIC_issueSVNCommand($SCRIPT_COMMAND);
	}
}

###############################################
# Update BMPIC stuff
###############################################
sub SCRIPT_maintainBMPIC()
{
	# remove one line
	splice (@SCRIPT_FILELINES, $SCRIPT_FOUNDATLINE, 1);
	
	open(FILE, ">$SCRIPT_DELETEINFOFILE") || die "Couldn't open Delete Info file: $SCRIPT_DELETEINFOFILE!\n";
	foreach $SCRIPT_FILELINE(@SCRIPT_FILELINES) {
		print FILE "$SCRIPT_FILELINE\n";
	}

	close FILE;
	
	$SCRIPT_COMMAND = "commit $SCRIPT_DELETEINFOFILE -m \"Maintaining delete info - BMPIC Script\"";
	BMPIC_issueSVNCommand($SCRIPT_COMMAND);
}

################################################
################ MAIN ##########################
################################################

# Set default operation environments 
SCRIPT_exportDefaults();

# Get required parameters from command-line
SCRIPT_parseCommandLine();

# Load options
SCRIPT_configure();

# Construct the command
SCRIPT_constructCommand();

# Execute the command
SCRIPT_issueCommand();

# Do BMPIC maintenance stuff
SCRIPT_maintainBMPIC();



###############################################
###############################################
###############################################

# system("pause");

# $ svn copy --revision 807 \
#			http://svn.example.com/repos/calc/trunk/real.c ./real.c
