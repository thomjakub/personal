#!/usr/bin/perl
#
# MODIFICATION HISTORY
# 20080222,ylc,updating the functionality file
# 20080215,ylc,providing options for taging and restructuring the code
# 20080211,ylc,providing version numbers as argument
# 20080131,tj,Documentation, stricter command-line
# 20080123,tj,Working with full info-tag
# 20080121,tj,refactoring done.
# 20080110,tj,updating infotag also! order not checked. refactoring pending.
# 20080109,tj,done for local, command-pool, taginfo pending   
# 20080109,tj,Changed option to remote/local, done for repo commit not done for local
# 20080109,tj,Frameworkized, comment message bug
# 20080108,tj,Initial version
#

do 'bmpic.pl';
do 'infotag.pl';

###############################################
# Help display function
###############################################
sub SCRIPT_displayHelp()
{
	print("Tags the trunk to the specified name\n");
	print("Usage: $0 OPTIONS <tagname> [comment-message]\n");
	print("\nOPTIONS\n");

	print("-d \t: Changing the Tag Name (Destination) , Specify the TAG Name\n");
	print("-s \t: Changing the Source, Specify the source path\n");
	
	print("Notes:\n");
	print("1. Enter relative paths.\n");
	print("2. Use . if foundation is the same as source\n");
	print("\n");

	print("Example: $0 -d BMPIC_0_1 <Message>\n");
	print("Creates a Tag called BMPIC_0_1 in TAG folder from TRUNK.\n");
	
	print("Example: $0 -d BMPIC_0_2 -s BRANCHES/BMPIC_0_1_1ylc . <Message>\n");
	print("Creates a Tag called BMPIC_0_2 in TAG folder from BRANCHES/BMPIC_0_1_1ylc.\n");	
	
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
	INFOTAG_exportDefaults();
}

###############################################
# Parse the command-line for options
###############################################
sub SCRIPT_parseCommandLine()
{
	use Getopt::Std;
	
	$getoptSyntax = 'd:s:'. $BMPIC_OPTIONS;
	
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
	
	# Get the rest of the parameters (non-getopt)	
	$SCRIPT_SRC_FOUNDATION = $BMPIC_NAME_TRUNK;
	# get the local/repo option
	if (exists $opt{'d'}) {
		$SCRIPT_TAG_NAME = $opt{'d'};
	}
	else{
		die "Foundation directory must be given for TAGING!";
	}
	$SCRIPT_REL_TAGVERSION = $BMPIC_NAME_TAGS.$SCRIPT_TAG_NAME;
	$SCRIPT_REL_TAGVERSION = BMPIC_normalizePath($SCRIPT_REL_TAGVERSION);
	print ("REL TAG version: $SCRIPT_REL_TAGVERSION !!!!\n\n") if $BMPIC_DEBUG;
	
	die ("TAG $SCRIPT_REL_SRCVERSION already exist!!!") if (BMPIC_doesItemExist($SCRIPT_REL_TAGVERSION));
	
	if (exists $opt{'s'}) {

		$SCRIPT_SRC_FOUNDATION = $opt{'s'};
		$SCRIPT_SRC_FOUNDATION = BMPIC_getRelativePath($SCRIPT_SRC_FOUNDATION);
		$SCRIPT_SRC_FOUNDATION = "" if($SCRIPT_ITEMNAME eq ".") ;
		$SCRIPT_SRC_FOUNDATION = $SCRIPT_SRC_FOUNDATION."/";
		($SCRIPT_ITEMNAME, @SCRIPT_COMMENT) = @SCRIPT_GETOPTVOMIT; 
	}
	else{
		(@SCRIPT_COMMENT) = @SCRIPT_GETOPTVOMIT; 
	}
	
	die "Foundation is not a directory!!" if !BMPIC_isDirectory($SCRIPT_SRC_FOUNDATION);
	$SCRIPT_REL_SRCVERSION = $SCRIPT_SRC_FOUNDATION.$SCRIPT_ITEMNAME;
	print ("REL SOUCE version: $SCRIPT_REL_SRCVERSION !!!!\n\n") if $BMPIC_DEBUG;
	
	# check if tag file exists, thomas CHECK this
	die ("SOUCRE $SCRIPT_REL_SRCVERSION not found!!!") if (!BMPIC_doesItemExist($SCRIPT_REL_SRCVERSION));
	
	
}

###############################################
# Construct the command(s)
###############################################
sub SCRIPT_constructCommand()
{
	@SCRIPT_COMMANDLIST=();
	
	# copy (tag) the trunk
	$SCRIPT_COMMAND = "copy $BMPIC_SVNINFOSOURCE$SCRIPT_REL_SRCVERSION $BMPIC_SVNINFOSOURCE$SCRIPT_REL_TAGVERSION";
	push(@SCRIPT_COMMANDLIST, $SCRIPT_COMMAND);
	
	$SCRIPT_COMMAND = "commit $BMPIC_SVNINFOSOURCE$SCRIPT_REL_TAGVERSION -m \"@SCRIPT_COMMENT - BMPIC Script \"";
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
	if (! -e  $BMPIC_WCOPY_INFOTAGS){
		#TODO issue an update for this file		
		$SCRIPT_COMMAND = "update $BMPIC_WCOPY_INFOTAGS";
		BMPIC_issueSVNCommand($SCRIPT_COMMAND);	
		#TODO Check for return value

		#if still not present, then create
		if (! -e  $BMPIC_WCOPY_INFOTAGS){		
			INFOTAG_create();
			
			#after create then svn add
			$SCRIPT_COMMAND = "add $BMPIC_WCOPY_INFOTAGS";
			BMPIC_issueSVNCommand($SCRIPT_COMMAND);		
		}
	}
	INFOTAG_readAll();
	print "Adding new line for $SCRIPT_NEWTAG \n" if $BMPIC_DEBUG;
	
	INFOTAG_addNewLine($SCRIPT_REL_TAGVERSION);
	#INFOTAG_commit();
	$SCRIPT_COMMAND = "commit $BMPIC_WCOPY_INFOTAGS -m \"Maintaining TAG info - BMPIC Script\"";
	BMPIC_issueSVNCommand($SCRIPT_COMMAND);
		
	$SCRIPT_FXNLT_FILE = $BMPIC_SVNINFOSOURCE.$SCRIPT_REL_TAGVERSION."/".$BMPIC_FILE_CHANGELOG;
	
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
	
	$SCRIPT_TAGITEMNAME = BMPIC_getItemName($SCRIPT_REL_TAGVERSION);
	push(@APPENDFxNLT_LINES, $SCRIPT_TAGITEMNAME);
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

