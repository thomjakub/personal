#! /usr/bin/perl 

# MODIFICATION HISTORY
# 20080215,tj,Reimplementing
# 20080215,tj,Refactoring to BIRD level!
# 20080129,tj,Using normalize path now
# 20080129,tj,Working for both local and remote, refactoring to do
# 20080128,tj,Rough functionality added
# 20080128,tj,Initial version
#

do 'bmpic.pl';

###############################################
# Help display function
###############################################
sub SCRIPT_displayHelp()
{
	print("Generate a unified diff patch for the DESTINATION\n");
	print("Usage: $0 OPTIONS <PatchName>\n");
	print("\nOPTIONS\n");
	print("-s ARG\t: From Source Path\n");
	print("-d ARG\t: To Destination Path\n");
	print("-a\t: Auto-commit destination\n");
	print("-b\t: Treat SOURCE as branch\n");
	print("-k\t: Treat DESTINATION as trunk\n");
	print("-g\t: Treat DESTINATION as tag\n");
	print("-p ARG\t: Put patch in directory\n");
	print("-r\t: Generate remotely\n");
	print("-y ARG\t: Patch type prefix\n");
	print("\n");
	
	print("Notes:\n");
	print("1. SOURCE is the path on which changes (of interest) have been made.\n");
	print("2. Use remote option when SOURCE and DESTINATION have same trees.\n");
	print("3. Patch-type prefix will be added to the patchname if given.\n");
	print("\n");
	print("Example: $0 -bs PROJ_0_1_1tj/ -gd PROJ_0_1 bugfix\n");
	print("The patch file bugfix.patch will be generated.");
	print("To apply the patch, use TortoiseMerge.\n");
	print("\n");
	
	BMPIC_displayHelp() if exists $opt{'B'};
	print "For help on generic BIRD options give -HB option.\n";

	exit;
}

###############################################
# Variables
# Default parameters for script
###############################################

$SCRIPT_AUTOCOMMIT = 0;
$SCRIPT_GENERATELOCALLY = 1;
$SCRIPT_PATCHPREFIX = "";

sub SCRIPT_exportDefaults()
{
	# Framework-mandated step
	BMPIC_exportDefaults();
	
	$SCRIPT_AUTOCOMMIT = 0;
	$SCRIPT_GENERATELOCALLY = 1;
	$SCRIPT_PATCHPREFIX = "";
}

###############################################
# Parse the command-line for options
###############################################
sub SCRIPT_parseCommandLine()
{
	use Getopt::Std;
	
	$getoptSyntax = 's:d:p:y:abkgr'. $BMPIC_OPTIONS;
	
	$ok= getopts("$getoptSyntax",\%opt);
	
	SCRIPT_displayHelp() if exists $opt{'H'};
	die "Error parsing command-line for syntax $getoptSyntax. Invoke as $0 -H for help.\n" if !$ok;
	die "Incorrect number of parameters! Invoke as $0 -H for help.\n" if(@ARGV<1);
	
	die "Remote option not implemented!" if exists $opt{'r'};
	
	BMPIC_optionCheckAllNeeded('sd');
	BMPIC_optionCheckIncompatible('gk');
	
	# Store the remaining stuff for later! :-)
	@SCRIPT_GETOPTVOMIT = @ARGV;
	
	print("$getoptSyntax successfully parsed\n") if exists $opt{'V'};
	
}

###############################################
# Configure based on parsed options
###############################################
sub SCRIPT_configure()
{
	# Framework-mandated step
	BMPIC_configure();

	# Get the rest of the parameters (non-getopt)
	($SCRIPT_PATCHNAME) = @SCRIPT_GETOPTVOMIT; 
	$SCRIPT_PATCHDIR = $BMPIC_NAME_PATCHES;
	
	$SCRIPT_SOURCE = $opt{'s'} if exists $opt{'s'};
	$SCRIPT_DESTINATION = $opt{'d'} if exists $opt{'d'};
	$SCRIPT_PATCHDIR = $opt{'p'} if exists $opt{'p'};
	
	$SCRIPT_PATCHPREFIX = $opt{'y'} . '_' if exists $opt{'y'};
	$SCRIPT_AUTOCOMMIT = 1 if exists $opt{'a'};
	$SCRIPT_GENERATELOCALLY = 0 if exists $opt{'r'};

	$SCRIPT_SOURCE = BMPIC_getRelativePath($SCRIPT_SOURCE);
	$SCRIPT_DESTINATION = BMPIC_getRelativePath($SCRIPT_DESTINATION);
	$SCRIPT_PATCHDIR = BMPIC_getRelativePath($SCRIPT_PATCHDIR);
	
	$SCRIPT_SOURCE = $BMPIC_NAME_BRANCHES.$SCRIPT_SOURCE if exists $opt{'b'};
	$SCRIPT_DESTINATION = $BMPIC_NAME_TAGS.$SCRIPT_DESTINATION if exists $opt{'g'};
	$SCRIPT_DESTINATION = $BMPIC_NAME_TRUNK.$SCRIPT_DESTINATION if exists $opt{'k'};
	
	$SCRIPT_SOURCE .='/' if BMPIC_isDirectory($SCRIPT_SOURCE);
	$SCRIPT_DESTINATION .='/' if BMPIC_isDirectory($SCRIPT_DESTINATION);
	$SCRIPT_PATCHDIR .='/' if BMPIC_isDirectory($SCRIPT_PATCHDIR);
	
	$SCRIPT_PATCHFILE = "$SCRIPT_PATCHDIR$SCRIPT_PATCHPREFIX$SCRIPT_PATCHNAME.patch";
	$SCRIPT_OUTPUTPATCH = "$BMPIC_WCOPY$SCRIPT_PATCHFILE";
	
	BMPIC_ensureItemPresent($SCRIPT_PATCHFILE,1);
	
}

###############################################
# Generate the patch on working copy
###############################################
sub SCRIPT_generatePatchLocally()
{
	$SCRIPT_FROMPATH = "$BMPIC_WCOPY$SCRIPT_SOURCE";
	$SCRIPT_TOPATH = "$BMPIC_WCOPY$SCRIPT_DESTINATION";
	
	# export to target path
	# TODO: replace with merge instead of export?
	$SCRIPT_COMMAND = "export --force $SCRIPT_FROMPATH $SCRIPT_TOPATH";
	BMPIC_issueSVNCommand($SCRIPT_COMMAND);

	@SCRIPT_ADDLIST = BMPIC_addToWorkingCopy($SCRIPT_DESTINATION);
	
	# Generate the patch file
	$SCRIPT_COMMAND = "diff $SCRIPT_TOPATH > $SCRIPT_OUTPUTPATCH";
	BMPIC_issueSVNCommand($SCRIPT_COMMAND);

	# Make patch-file path-neutral

	open(SCRIPT_PATCHFILE, $SCRIPT_OUTPUTPATCH) or die "Couldn't open file: $SCRIPT_OUTPUTPATCH!\n";
	@SCRIPT_LINES=<SCRIPT_PATCHFILE>;
	close(SCRIPT_PATCHFILE);

	open (SCRIPT_PATCHFILE, ">$SCRIPT_OUTPUTPATCH");
	foreach $SCRIPT_LINE(@SCRIPT_LINES){
		$SCRIPT_LINE =~ s/$SCRIPT_TOPATH//i;
		print SCRIPT_PATCHFILE $SCRIPT_LINE;
	}
	close(SCRIPT_PATCHFILE);		

	if(!$SCRIPT_AUTOCOMMIT){
		# Undo the changes made to target
		# TODO: Possible bug, if OUTPUTPATCH is in TOPATH! 
		$SCRIPT_COMMAND = "revert -R $SCRIPT_TOPATH";
		BMPIC_issueSVNCommand($SCRIPT_COMMAND);

		# Delete added files
		foreach $SCRIPT_ITEM(@$SCRIPT_ADDLIST){
			$SCRIPT_COMMAND = "delete --force $SCRIPT_TOPATH$SCRIPT_ITEM";
			BMPIC_issueSVNCommand($SCRIPT_COMMAND);
		}
		
		# Restore deleted files
		$SCRIPT_COMMAND = "update $SCRIPT_TOPATH";
		BMPIC_issueSVNCommand($SCRIPT_COMMAND);
	}

}


###############################################
# Generate the patch from repo 
###############################################
sub SCRIPT_generatePatchRemotely()
{	
	$SCRIPT_FROMPATH = "$BMPIC_SVN_URL$SCRIPT_SOURCE";
	$SCRIPT_TOPATH = "$BMPIC_SVN_URL$SCRIPT_DESTINATION";

	$SCRIPT_COMMAND = "diff $SCRIPT_TOPATH $SCRIPT_FROMPATH > $SCRIPT_OUTPUTPATCH";
	BMPIC_issueSVNCommand($SCRIPT_COMMAND);
}

###############################################
# Construct the command(s)
###############################################
sub SCRIPT_constructCommand()
{
	@SCRIPT_COMMANDLIST=();
	
	if($SCRIPT_GENERATELOCALLY){
		SCRIPT_generatePatchLocally();
	}
	else{
		SCRIPT_generatePatchRemotely();
	}
	
	
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

		$SCRIPT_SVN_COMMAND = $BMPIC_SVNCLIENT . $SCRIPT_COMMAND;
	
		print("Issuing command...\n") if $BMPIC_VERBOSE;
		print("$SCRIPT_SVN_COMMAND\n") ;
	
		system("$SCRIPT_SVN_COMMAND") if !$BMPIC_DEBUG;
	}
}


###############################################
# Update BMPIC stuff
###############################################
sub SCRIPT_maintainBMPIC()
{
	$SCRIPT_COMMAND = "commit \"$SCRIPT_OUTPUTPATCH\" -m \"Patch: $SCRIPT_PATCHNAME generated - BMPIC Script \"";
	#BMPIC_issueSVNCommand($SCRIPT_COMMAND);
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


