#! /usr/bin/perl
# 
# MODIFICATION HISTORY
# 20080214,tj,intelligent delete (even if not changed)
# 20080214,tj,sourcing from tasks too, simplifying intelligence
# 20080213,tj,incorporating ensureItemPresent
# 20080212,tj,delete option
# 20080212,tj,newer-only, refresh-only options
# 20080211,tj,Adding task to SVN
# 20080211,tj,Smart update
# 20080211,tj,Adding foundation
# 20080207,tj,Adding support for multiple sources
# 20080207,tj,Fixed the separate field as PARENT
# 20080207,tj,Putting path info as separate field
# 20080206,tj,Storing path info as well
# 20080206,tj,Basic version done
# 20080204,tj,Adapting from restoreitem
#

do 'bmpic.pl';

###############################################
# Help display function
###############################################
sub SCRIPT_displayHelp()
{
	print("Prepares a task includable in a build\n");
	print("Usage: $0 OPTIONS <SourceItem> <TaskName>\n");
	print("\nOPTIONS\n");
	print("-f ARG \t: Foundation directory\n");
	print("-b \t: Treat foundation as branch\n");
	print("-k \t: Treat foundation as trunk\n");
	print("-d \t: Dumb, brute-force update for files with same relative path\n");
	print("-r \t: Refresh items in the task only, no additions\n");
	print("-x \t: Delete items from task\n");
	print("-t \t: Treat Source-Item as task.\n");
	print("-o \t: Consider old items for addition too. Skip if-newer check.\n");
	print("\n");
	
	print("Notes:\n");
	print("1. Enter relative paths.\n");
	print("2. Use . if foundation is the same as source\n");
	print("\n");
	
	print("Example: $0 -bf CA_0_1_1tj/ AudioPlayer mp3Pause\n");
	print("Updates mp3Pause.task with changes from BRANCHES/CA_0_1_1tj/AudioPlayer.\n");
	print("The created task can be included in a build using applytask.pl.\n");
	print("\n");
	
	BMPIC_displayHelp() if exists $opt{'B'};
	print "For help on generic BIRD options give -HB option.\n";
	exit;
}

###############################################
# Variables
# Default parameters for script
###############################################

$SCRIPT_SMARTUPDATE = 1;
$SCRIPT_NOOLDCHECK = 0;
$SCRIPT_REFRESHONLY = 0;
$SCRIPT_DELETEMODE = 0;
$SCRIPT_SOURCEISTASK = 0;


sub SCRIPT_exportDefaults()
{
	# Framework-mandated step
	BMPIC_exportDefaults();
	
	$SCRIPT_SMARTUPDATE = 1;
	$SCRIPT_NOOLDCHECK = 0;
	$SCRIPT_REFRESHONLY = 0;
	$SCRIPT_DELETEMODE = 0;
	$SCRIPT_SOURCEISTASK = 0;
}

###############################################
# Parse the command-line for options
###############################################
sub SCRIPT_parseCommandLine()
{
	use Getopt::Std;
	
	$getoptSyntax = 'f:bkrxtod'. $BMPIC_OPTIONS;
	
	$ok= getopts("$getoptSyntax",\%opt);
	
	SCRIPT_displayHelp() if exists $opt{'H'};
	die "Error parsing command-line for syntax $getoptSyntax. Invoke as $0 -H for help.\n" if !$ok;
	die "Incorrect number of parameters! Invoke as $0 -H for help.\n" if(@ARGV<2);
	
	# Store the remaining stuff for later! :-)
	@SCRIPT_GETOPTVOMIT = @ARGV;
	
	print("$getoptSyntax\n") if $BMPIC_VERBOSE;
	
}

###############################################
# Get list of items to consider for addition 
# from foundation + item
###############################################
sub SCRIPT_makeAddListFromFoundation
{
	$SCRIPT_FOUNDATION .= "/";
	die "Foundation $SCRIPT_FOUNDATION is not a directory" if !BMPIC_isDirectory($SCRIPT_FOUNDATION);

	$SCRIPT_FIRSTREVISION = BMPIC_getFirstRevisionNumber($SCRIPT_FOUNDATION);
	print "First revision of item: $SCRIPT_FIRSTREVISION\n" if $BMPIC_VERBOSE;
	
	# svn list has to be issued against the foundation directory to get relative paths
	my $SCRIPT_COMMAND = "list --verbose -R $BMPIC_SVNINFOSOURCE$SCRIPT_FOUNDATION$SCRIPT_SOURCE";
	@SCRIPT_SOURCERAWLIST = BMPIC_getSVNCommandOutput($SCRIPT_COMMAND);
	
	my @SCRIPT_SPLITLIST = ();
	
	foreach (@SCRIPT_SOURCERAWLIST){
		s/^\s+//;               # no leading white
		s/\s+$//;               # no trailing white
		push(@SCRIPT_SPLITLIST, $_);
	}
	
	if (BMPIC_isDirectory($SCRIPT_FOUNDATION.$SCRIPT_SOURCE)){
		$SCRIPT_ITEMPREFIX = "$SCRIPT_SOURCE"; 
	}
	else {
		$SCRIPT_ITEMPREFIX = BMPIC_getParent($SCRIPT_SOURCE);
	}
	$SCRIPT_ITEMPREFIX .='/' if !$SCRIPT_SOURCE eq '';
	
	# Remove lines with revisions which are older than that of item's first revision

	foreach $SCRIPT_RAWLINE(@SCRIPT_SPLITLIST){
		
		# Get the first field
		($SCRIPT_RAWREVISION) = split(/ /, $SCRIPT_RAWLINE);
		
		# Get the last field
		$SCRIPT_RAWLINE = reverse($SCRIPT_RAWLINE);
		($SCRIPT_RAWITEMNAME) = split(/ /, $SCRIPT_RAWLINE);
		
		# Take only newer revisions than foundation's origin
		
		$SCRIPT_TAKEITEM = 0;
		$SCRIPT_TAKEITEM = 1 if $SCRIPT_FIRSTREVISION <= $SCRIPT_RAWREVISION;
		$SCRIPT_TAKEITEM = 1 if $SCRIPT_NOOLDCHECK;
		
		if($SCRIPT_TAKEITEM){
		
			$SCRIPT_RAWREVISION = sprintf("%05d", $SCRIPT_RAWREVISION);
			$SCRIPT_RAWITEMNAME = reverse($SCRIPT_RAWITEMNAME);
			print "$SCRIPT_RAWREVISION,$SCRIPT_RAWITEMNAME\n" if $BMPIC_DEBUG;

			$SCRIPT_RAWITEMNAME = $SCRIPT_ITEMPREFIX . $SCRIPT_RAWITEMNAME;
			
			# adding both to a list 
			push (@SCRIPT_CHANGEDITEMS, "$SCRIPT_RAWREVISION,$SCRIPT_FOUNDATION,$SCRIPT_RAWITEMNAME");
		}
	}

}

###############################################
# Get list of items to consider for addition 
# from foundation + item
###############################################
sub SCRIPT_makeAddListFromTask
{
	$SCRIPT_SOURCETASKFILE = "$BMPIC_NAME_TASKS$SCRIPT_SOURCE.task"; 

	open (SOURCETASKFILE,"$BMPIC_WCOPY$SCRIPT_SOURCETASKFILE") or die "Task file $SCRIPT_SOURCETASKFILE not found!\n";
	@SCRIPT_CHANGEDITEMS = <SOURCETASKFILE>;
	chomp(@SCRIPT_CHANGEDITEMS);
	close SOURCETASKFILE;
	
	$SCRIPT_FOUNDATION = "$BMPIC_NAME_TASKS$SCRIPT_SOURCE.task";

}

###############################################
# Configure based on parsed options
###############################################
sub SCRIPT_configure()
{
	
	# Framework-mandated step
	BMPIC_configure();
	
	($SCRIPT_SOURCE, $SCRIPT_TASKFILENAME) = @SCRIPT_GETOPTVOMIT;
	
	$SCRIPT_NOOLDCHECK =1 if exists $opt{'o'};
	$SCRIPT_SMARTUPDATE =0 if exists $opt{'d'};
	$SCRIPT_REFRESHONLY = 1 if exists $opt{'r'};
	$SCRIPT_DELETEMODE = 1 if exists $opt{'x'};
	$SCRIPT_SOURCEISTASK = 1 if exists $opt{'t'};
	
	$SCRIPT_SOURCE = BMPIC_getRelativePath($SCRIPT_SOURCE);
	$SCRIPT_SOURCE = "" if $SCRIPT_SOURCE eq '.';
	
	$SCRIPT_TASKFILENAME .= ".task";
	
	if(exists $opt{'f'}){
		$SCRIPT_FOUNDATION = $opt{'f'};
		$SCRIPT_FOUNDATION = BMPIC_getRelativePath($SCRIPT_FOUNDATION);
		$SCRIPT_FOUNDATION = $BMPIC_NAME_TRUNK . $SCRIPT_FOUNDATION if exists $opt{'k'};
		$SCRIPT_FOUNDATION = $BMPIC_NAME_BRANCHES . $SCRIPT_FOUNDATION if exists $opt{'b'};
	}
	else {
		die "Foundation directory must be given for task-creation!" if !$SCRIPT_SOURCEISTASK;
	}
	
	
	@SCRIPT_CHANGEDITEMS = ();
	
	if($SCRIPT_SOURCEISTASK){
		SCRIPT_makeAddListFromTask();
	}
	else {
		SCRIPT_makeAddListFromFoundation();
	}
	
	
}



###############################################
# Construct the command(s)
###############################################
sub SCRIPT_constructCommand()
{
	@SCRIPT_COMMANDLIST=();

	$SCRIPT_COMMAND ="commit $BMPIC_WCOPY$SCRIPT_TASKFILE -m \"~~BIRD~~ Updated from $SCRIPT_FOUNDATION \n @SCRIPT_UPDATELIST\"";
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
		BMPIC_getSVNCommandOutput($SCRIPT_COMMAND);
	}
}

###############################################
# Update BMPIC stuff
###############################################
sub SCRIPT_maintainBMPIC()
{
	@SCRIPT_TASKLINES = ();
	$SCRIPT_DELETEMAGICVALUE = "~~~~xx!xx~~~~";
	
	$SCRIPT_TASKFILE = $BMPIC_NAME_TASKS . $SCRIPT_TASKFILENAME;
	
	BMPIC_ensureItemPresent($SCRIPT_TASKFILE, 1);
	
	open (TASKFILE,"$BMPIC_WCOPY$SCRIPT_TASKFILE") or die "Could not open file.";
	@SCRIPT_TASKLINES = <TASKFILE>;
	chomp(@SCRIPT_TASKLINES);
	close TASKFILE;
	
	foreach $SCRIPT_CHANGEDITEM(@SCRIPT_CHANGEDITEMS){
		my ($SCRIPT_CHANGEDITEMREV, $SCRIPT_CHANGEDITEMBASE, $SCRIPT_CHANGEDITEMNAME) 
			= split(/,/, $SCRIPT_CHANGEDITEM, 3);
		
		$SCRIPT_UPDATETASKLINE = 1;
		$SCRIPT_CHANGEDITEMNAME =~  s/\s+$//i;
		$i=0;
		$SCRIPT_FOUNDITEMINTASK=0;
		
		# Look in task-file lines
		foreach $SCRIPT_TASKLINE(@SCRIPT_TASKLINES){
		
			($SCRIPT_TASKITEMREV, $SCRIPT_TASKITEMPATH, $SCRIPT_TASKITEMNAME) = split(/,/, $SCRIPT_TASKLINE);
			
			$SCRIPT_TASKITEMNAME =~ s/\s+$//i;
			
			if($SCRIPT_TASKITEMNAME =~ m/\Q$SCRIPT_CHANGEDITEMNAME/i){
				print "$SCRIPT_CHANGEDITEMNAME found...";
				$SCRIPT_FOUNDITEMINTASK=1;
				last if($SCRIPT_SMARTUPDATE == 0);
		
				# This is the smart zone!
				my $SCRIPT_DIFFBASE = 1;
				my $SCRIPT_NEWER = 1;
				my $SCRIPT_CHANGED = 0;
				
				# check if file from different source
				$SCRIPT_TASKITEMPATH =~ s/\s+$//i;
				print ":$SCRIPT_TASKITEMPATH:$SCRIPT_CHANGEDITEMBASE:" if $BMPIC_DEBUG;

				$SCRIPT_DIFFBASE = 0 if ($SCRIPT_TASKITEMPATH eq $SCRIPT_CHANGEDITEMBASE);
				$SCRIPT_CHANGEDNEWER = 1 if ($SCRIPT_CHANGEDITEMREV != $SCRIPT_TASKITEMREV );
				$SCRIPT_CHANGED = $SCRIPT_DIFFBASE | $SCRIPT_CHANGEDNEWER;
				
				# check if file is newer
				if (!$SCRIPT_CHANGED){
					print "not changed...";
					$SCRIPT_UPDATETASKLINE = 0 if !$SCRIPT_DELETEMODE;
				}
				last;
			}
			$i++;
		}
		
		if (!$SCRIPT_FOUNDITEMINTASK){
			print "$SCRIPT_CHANGEDITEMNAME absent...";
			$SCRIPT_UPDATETASKLINE=0 if $SCRIPT_REFRESHONLY;
			$SCRIPT_UPDATETASKLINE=0 if $SCRIPT_DELETEMODE;
		}

		# Update the task-lines if needed
		if($SCRIPT_UPDATETASKLINE == 1) {
			if (!$SCRIPT_DELETEMODE) {
				$SCRIPT_TASKLINES[$i] = "$SCRIPT_CHANGEDITEMREV,$SCRIPT_CHANGEDITEMBASE,$SCRIPT_CHANGEDITEMNAME";
			}
			else {
				$SCRIPT_TASKLINES[$i] = $SCRIPT_DELETEMAGICVALUE;
				# Using magic-value for marking for deletion
				# not shifting/splicing because in foreach loop based on list
				# TODO change magic value implementation
			}
			push(@SCRIPT_UPDATELIST, $SCRIPT_CHANGEDITEMNAME."\n");
			print "updating.\n";
		}
		else{
			print "ignoring.\n";
		}
		
	}
	print "\n";
	
	# Save the task to the file
	open (TASKFILE,">$BMPIC_WCOPY$SCRIPT_TASKFILE") or die "Could not open file.";
	foreach (@SCRIPT_TASKLINES){
		print TASKFILE "$_\n" unless $_ eq $SCRIPT_DELETEMAGICVALUE;
	}
	close TASKFILE;
	
	

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

# Do BMPIC maintenance stuff
SCRIPT_maintainBMPIC();

# Construct the command
SCRIPT_constructCommand();

# Execute the command
SCRIPT_issueCommand();




###############################################
###############################################
###############################################
