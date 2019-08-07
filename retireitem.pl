#! /usr/bin/perl
#
# MODIFICATION HISTORY
# 20080315,ylc,changing the name to retireitem.pl and cleaning the code
# 20080131,tj,Documentation, refactoring, stricter command-line
# 20080131,tj,Integration fix: --force option needed
# 20080124,ylc,Initial version to deleteitem
#

do 'bmpic.pl';
do 'infodelete.pl';

# perl deleteitem.pl E:\BMPIC\LAB\TestArea\BMPIC_0_4\ deleting an item
# check for the item
# if present delete and commit  else message
# check for the BMPIC_Branches.txt file, if not present create it
# update the file with the item and version number
#

###############################################
# Help display function
###############################################
sub SCRIPT_displayHelp()
{
	print("Delete the specified item and update delete-tracker\n");
	print("Usage: $0 OPTIONS <ItemToDelete> [WhyDelete?]>\n");
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
	INFODELETE_exportDefaults();
}

###############################################
# Parse the command-line for options
###############################################
sub SCRIPT_parseCommandLine()
{
	use Getopt::Std;
	
	$getoptSyntax = 'r'. $BMPIC_OPTIONS;
	
	$ok= getopts("$getoptSyntax",\%opt);
	
	if(!$ok)
	{
		print("Error parsing command-line for syntax $getoptSyntax\n\n");
	}
	
	if(@ARGV<1){
		print "Incorrect number of parameters!\n\n";
		$ok = 0;
	}

	if(!$ok  or exists $opt{'H'} )
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
	($SCRIPT_DELETEITEM, @SCRIPT_COMMENT) = @SCRIPT_GETOPTVOMIT; 
	
	$SCRIPT_DELETEITEM = BMPIC_normalizePath($SCRIPT_DELETEITEM);
	if(BMPIC_doesItemExist($SCRIPT_DELETEITEM)){
		print "Exists!\n" if $BMPIC_DEBUG;
	}
	else{
		die "$SCRIPT_DELETEITEM Not Found!\n";
	}
}

###############################################
# Construct the command(s)
###############################################
sub SCRIPT_constructCommand()
{
	@SCRIPT_COMMANDLIST=();
	
	print("$SCRIPT_DELETEITEM Delete item name\n") if $BMPIC_DEBUG;
	
	$SCRIPT_PARENTDIR = BMPIC_getParent($SCRIPT_DELETEITEM);
	$SCRIPT_ITEM = BMPIC_getItemName($SCRIPT_DELETEITEM);
	
	print("$SCRIPT_DELETEITEM is file to be deleted\n") if $BMPIC_DEBUG;
	print("$SCRIPT_PARENTDIR is the Parent DIRECTORY to be commited\n") if $BMPIC_DEBUG;
	print("$SCRIPT_ITEM is the Item name\n") if $BMPIC_DEBUG;
	
	$SCRIPT_COMMAND = "update $BMPIC_WCOPY$SCRIPT_DELETEITEM";
	push(@SCRIPT_COMMANDLIST, $SCRIPT_COMMAND);
		
	$SCRIPT_RELATIVEPATH_DELETEITEM = BMPIC_getRelativePath($SCRIPT_DELETEITEM);	
	$ITEMDELETE_REVISION = BMPIC_getLastRevisionNumber($SCRIPT_RELATIVEPATH_DELETEITEM);
	
	print ("$ITEMDELETE_REVISION is the version number for $SCRIPT_DELETEITEM\n\n");
	
	$SCRIPT_COMMAND = "delete --force $BMPIC_WCOPY$SCRIPT_DELETEITEM";
	push(@SCRIPT_COMMANDLIST, $SCRIPT_COMMAND);
	$SCRIPT_COMMAND = "commit $SCRIPT_PARENTDIR -m \"@SCRIPT_COMMENT - BMPIC Script \"";
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
	$BMPIC_WCOPY_INFODELETE = $SCRIPT_PARENTDIR."/".$BMPIC_FILE_DELETES;
	
	# check if delete info file exists, else create
	if (! -e  $BMPIC_WCOPY_INFODELETE){
		#TODO issue an update for this file		
		$SCRIPT_COMMAND = "update $BMPIC_WCOPY_INFODELETE";
		BMPIC_issueSVNCommand($SCRIPT_COMMAND);	
		#TODO Check for return value

		#if still not present, then create
		if (! -e  $BMPIC_WCOPY_INFODELETE){		
			INFODELETE_create();
			
			#after create then svn add
			$SCRIPT_COMMAND = "add $BMPIC_WCOPY_INFODELETE";
			BMPIC_issueSVNCommand($SCRIPT_COMMAND);		
		}
	}
	$SCRIPT_COMMAND = "update $SCRIPT_PARENTDIR";
	BMPIC_issueSVNCommand($SCRIPT_COMMAND);	
	
	INFODELETE_readAll();
	print "Adding new line for $SCRIPT_PARENTDIR \n" if $BMPIC_DEBUG;
	
	INFODELETE_addNewLine($SCRIPT_ITEM);
	#INFOBRANCH_commit();
	$SCRIPT_COMMAND = "commit $BMPIC_WCOPY_INFODELETE -m \"Maintaining delete info - BMPIC Script\"";
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
