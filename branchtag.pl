#! /usr/bin/perl
#
# MODIFICATION HISTORY
# 20080222,ylc,updated the functionality file
# 20080214,ylc,Re structuring the script with option
# 20080213,ylc,Re structuring the script
# 20080207,ylc,updated the checking for destination path existance.
# 20080206,ylc,supported -r option
# 20080131,tj,Documentation update, stricter command-line
# 20080123,ylc,Advanced version
# 20080121,tj,Initial version based on tagtrunk.pl
#

do 'bmpic.pl';
do 'infobranch.pl';

# Simple case

# Check whether the tag exists
# Do the SVN copy 
# Update branchinfo file
# Update functionality file
# Do the commit
#

# Advanced case

# Convert version to tagname
# Check if it exists
# Get author's abbrev from authors file
# Construct branch-name
# Same as above simple case

###############################################
# Help display function
###############################################
sub SCRIPT_displayHelp()
{
	print("Creates a branch from the tag to the specified name according to BMPIC conventions\n");
	print("Usage: $0 OPTIONS <SourcePath - Foundation> <ItemName> <Message>\n");
	print("\nOPTIONS\n");
	
	print("-s \t: Source, Specify the source path\n");
	
	print("Notes:\n");
	print("1. Enter relative paths.\n");
	print("2. Use . if foundation is the same as source\n");
	print("\n");
	
	print("Example: $0 BMPIC_0_1 <Message>\n");
	print("Creates a branch called BMPIC_0_1_1ylc in BRANCHES folder.\n");
	
	print("Example: $0 -s TRUNK/ . <Message>\n");
	print("Creates a branch called TRUNK_1_ylc in BRANCHES folder.\n");	
	
	BMPIC_displayHelp();	
	print("\n");
	exit;
}

###############################################
# Variables
# Default parameters for script
###############################################

sub SCRIPT_exportDefaults()
{
	# Framework-mandated step
	BMPIC_exportDefaults();
	INFOBRANCH_exportDefaults();
}

###############################################
# Parse the command-line for options
###############################################
sub SCRIPT_parseCommandLine()
{
	use Getopt::Std;
	
	$getoptSyntax = 's:'. $BMPIC_OPTIONS;
	
	$ok= getopts("$getoptSyntax",\%opt);
	
	SCRIPT_displayHelp() if exists $opt{'H'};
	die "Error parsing command-line for syntax $getoptSyntax\n" if !$ok;
	die "Incorrect number of parameters!\n" if(@ARGV<2);
	
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
	
	($SCRIPT_ITEMNAME, @SCRIPT_COMMENT) = @SCRIPT_GETOPTVOMIT; 

	$SCRIPT_FOUNDATION = $BMPIC_NAME_TAGS;
	if(exists $opt{'s'}){
		$SCRIPT_FOUNDATION = $opt{'s'};
		$SCRIPT_FOUNDATION = BMPIC_getRelativePath($SCRIPT_FOUNDATION);
		$SCRIPT_ITEMNAME = "" if($SCRIPT_ITEMNAME eq ".") ;
		$SCRIPT_FOUNDATION = $SCRIPT_FOUNDATION."/";
	}
	die "Foundation is not a directory!!" if !BMPIC_isDirectory($SCRIPT_FOUNDATION);
	
	$SCRIPT_REL_TAGVERSION = $SCRIPT_FOUNDATION.$SCRIPT_ITEMNAME;
	print ("REL TAG version: $SCRIPT_REL_TAGVERSION !!!!\n\n") if $BMPIC_DEBUG;
	
	# check if tag file exists, thomas CHECK this
	die ("Tag $SCRIPT_REL_TAGVERSION not found!!!") if (!BMPIC_doesItemExist($SCRIPT_REL_TAGVERSION));
	
	$SCRIPT_BRANCHNAME = BMPIC_getItemName($SCRIPT_REL_TAGVERSION);
	
	# Constructing the BRANCH NAME 
	$SCRIPT_BRANCHOUTVERSION = 1;
	# if BRANCHED out then increment the $SCRIPT_BRANCHOUTVERSION  
	$SCRIPT_NEWBRANCH = $BMPIC_NAME_BRANCHES . $SCRIPT_BRANCHNAME. "_" . $SCRIPT_BRANCHOUTVERSION. $BMPIC_AUTHORSHORT ;
	while (BMPIC_doesItemExist($SCRIPT_NEWBRANCH))  { 
		$SCRIPT_BRANCHOUTVERSION = $SCRIPT_BRANCHOUTVERSION + 1;
		$SCRIPT_NEWBRANCH = $BMPIC_NAME_BRANCHES . $SCRIPT_BRANCHNAME. "_" . $SCRIPT_BRANCHOUTVERSION. $BMPIC_AUTHORSHORT ;
	}
	print ("New Branch Name: $SCRIPT_NEWBRANCH !!!!\n") if $BMPIC_DEBUG;
}

###############################################
# Construct the command(s)
###############################################
sub SCRIPT_constructCommand()
{
	@SCRIPT_COMMANDLIST=();	
	# copy (tag) the trunk
	$SCRIPT_COMMAND = "copy $BMPIC_SVNINFOSOURCE$SCRIPT_REL_TAGVERSION $BMPIC_SVNINFOSOURCE$SCRIPT_NEWBRANCH";
	push(@SCRIPT_COMMANDLIST, $SCRIPT_COMMAND);
	
	$SCRIPT_COMMAND = "add $BMPIC_SVNINFOSOURCE$SCRIPT_NEWBRANCH";
	push(@SCRIPT_COMMANDLIST, $SCRIPT_COMMAND);
	print ("Adding new version\n");
	
	# on local copy, we need a commit
	$SCRIPT_COMMAND = "commit $BMPIC_SVNINFOSOURCE$SCRIPT_NEWBRANCH -m \"@SCRIPT_COMMENT - BMPIC Script \"";
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
	# check if taginfo file exists, else create
	if (! -e  $BMPIC_WCOPY_INFOBRANCH){
		#TODO issue an update for this file		
		$SCRIPT_COMMAND = "update $BMPIC_WCOPY_INFOBRANCH";
		BMPIC_issueSVNCommand($SCRIPT_COMMAND);	
		#TODO Check for return value

		#if still not present, then create
		if (! -e  $BMPIC_WCOPY_INFOBRANCH){		
			INFOBRANCH_create();
			
			#after create then svn add
			$SCRIPT_COMMAND = "add $BMPIC_WCOPY_INFOBRANCH";
			BMPIC_issueSVNCommand($SCRIPT_COMMAND);		
		}
	}
	
	INFOBRANCH_readAll();
	print "Adding new line for $SCRIPT_NEWBRANCH \n" if $BMPIC_DEBUG;
	
	$SCRIPT_BRANCHNAME = BMPIC_getItemName($SCRIPT_NEWBRANCH);
	
	INFOBRANCH_addNewLine($SCRIPT_NEWBRANCH);
	#INFOBRANCH_commit();
	$SCRIPT_COMMAND = "commit $BMPIC_WCOPY_INFOBRANCH -m \"Maintaining branch info - BMPIC Script\"";
	BMPIC_issueSVNCommand($SCRIPT_COMMAND);
	
	$SCRIPT_FXNLT_FILE = $BMPIC_SVNINFOSOURCE.$SCRIPT_NEWBRANCH."/".$BMPIC_FILE_CHANGELOG;
	
	print "Fxnlt file - $SCRIPT_FXNLT_FILE\n" if $BMPIC_DEBUG;
	
	# check if taginfo file exists, else create
	if (! -e  $SCRIPT_FXNLT_FILE){
		#TODO issue an update for this file		
		$SCRIPT_COMMAND = "update $SCRIPT_FXNLT_FILE";
		BMPIC_issueSVNCommand($SCRIPT_COMMAND);	
		#TODO Check for return value

		#if still not present, then create
		if (! -e  $SCRIPT_FXNLT_FILE){		
			open(INFOFXNLT, ">$SCRIPT_FXNLT_FILE") or die "Can't open $SCRIPT_FXNLT_FILE !";
			
			#after create then svn add
			$SCRIPT_COMMAND = "add $SCRIPT_FXNLT_FILE";
			BMPIC_issueSVNCommand($SCRIPT_COMMAND);		
		}
	}
	
	$SCRIPT_BRANCHITEMNAME = BMPIC_getItemName($SCRIPT_NEWBRANCH);
	push(@APPENDFxNLT_LINES, $SCRIPT_BRANCHITEMNAME);
	push(@APPENDFxNLT_LINES, "Date: ".$BMPIC_DATE);
	push(@APPENDFxNLT_LINES, "* @SCRIPT_COMMENT");
	
	open (INFOFXNLT, "$SCRIPT_FXNLT_FILE") or die "Can't open $SCRIPT_FXNLT_FILE !";
	@INFOFXNLT_LINES = <INFOFXNLT>;
	# strip newlines
	chomp(@INFOFXNLT_LINES);
	close(INFOFXNLT);

	open (INFOFXNLT,">$SCRIPT_FXNLT_FILE") or die "Can't open $SCRIPT_FXNLT_FILE !";
	foreach(@APPENDFxNLT_LINES){
		print(INFOFXNLT"$_\n");
		}
		
	print(INFOFXNLT"\n");
	
	foreach(@INFOFXNLT_LINES){
		print(INFOFXNLT"$_\n");
		}
	close(INFOFXNLT);	
	
	$SCRIPT_COMMAND = "commit $SCRIPT_FXNLT_FILE -m \"Maintaining Fxnlt info - BMPIC Script\"";
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

