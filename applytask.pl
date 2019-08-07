#! /usr/bin/perl
# 
# MODIFICATION HISTORY
# 20080214,tj,intelligent delete (even if not changed)
# 20080214,tj,Recipes done. Can sleep now!
# 20080213,tj,Moving to recipe!
# 20080212,tj,For build.txt support
# 20080207,tj,Working! no build.txt though
# 20080206,tj,Initial version done
# 20080206,tj,Adapting from preparetask
#

do 'bmpic.pl';

###############################################
# Help display function
###############################################
sub SCRIPT_displayHelp()
{
	print("Applies an addable task on a destination\n");
	print("Usage: $0 OPTIONS <Destination> <TaskName>\n");
	print("\nOPTIONS\n");
	print("-b \t: Treat destination as branch\n");
	print("-k \t: Treat destination as trunk\n");
	print("-r \t: Refresh only, no additions\n");
	print("-x \t: Delete the items in task from destination\n");
	print("-d \t: Dumb update, apply no intelligence\n");
	print("-t \t: Force ownership of task-items in recipe\n");
	print("\n");
	
	print("Notes:\n");
	print("1. Can be used on local working copy only.\n");
	print("2. Compatible folder structure needed on destination.\n");
	print("\n");
	
	print("Example: $0 -b CA_0_1_1tj mp3Pause\n");
	print("Populates the CA_0_1_1tj branch with the contents of mp3Pause.task\n");
	print("\n");
	
	BMPIC_displayHelp() if exists $opt{'B'};
	print "For help on generic BIRD options give -HB option.\n";
	exit;
}

###############################################
# Variables
# Default parameters for script
###############################################

$SCRIPT_DELETEMODE = 0;
$SCRIPT_SMARTUPDATE = 1;
$SCRIPT_ADDONLYIFSAMETASK=1;
$SCRIPT_REFRESHONLY = 0;

sub SCRIPT_exportDefaults()
{
	# Framework-mandated step
	BMPIC_exportDefaults();
	
	$SCRIPT_DELETEMODE = 0;
	$SCRIPT_SMARTUPDATE = 1;
	$SCRIPT_ADDONLYIFSAMETASK=1;
	$SCRIPT_REFRESHONLY = 0;
}

###############################################
# Parse the command-line for options
###############################################
sub SCRIPT_parseCommandLine()
{
	use Getopt::Std;
	
	$getoptSyntax = 'bkrxdt'. $BMPIC_OPTIONS;
	
	$ok= getopts("$getoptSyntax",\%opt);
	
	SCRIPT_displayHelp() if exists $opt{'H'};
	die "Error parsing command-line for syntax $getoptSyntax. Invoke as $0 -H for help.\n" if !$ok;
	die "Incorrect number of parameters! Invoke as $0 -H for help.\n" if(@ARGV<2);
	
	# Store the remaining stuff for later! :-)
	@SCRIPT_GETOPTVOMIT = @ARGV;
	
	print("$getoptSyntax\n") if $BMPIC_VERBOSE;
	
}

###############################################
# Configure based on parsed options
###############################################
sub SCRIPT_configure()
{
	@SCRIPT_TASKLINES = ();
	
	# Framework-mandated step
	BMPIC_configure();
	
	($SCRIPT_TARGET, $SCRIPT_TASKFILENAME) = @SCRIPT_GETOPTVOMIT;
	
	$SCRIPT_SMARTUPDATE =0 if exists $opt{'d'};
	
	$SCRIPT_ADDONLYIFSAMETASK = 0 if exists $opt{'t'};
	
	$SCRIPT_REFRESHONLY = 1 if exists $opt{'r'};
	$SCRIPT_DELETEMODE = 1 if exists $opt{'x'};
	
	$SCRIPT_TASKFILE = "$BMPIC_NAME_TASKS$SCRIPT_TASKFILENAME.task"; 
	
	open (SCRIPT_TASKFILE,"$BMPIC_WCOPY$SCRIPT_TASKFILE") or die "Task file $SCRIPT_TASKFILE not found!\n";
	@SCRIPT_TASKLINES = <SCRIPT_TASKFILE>;
	chomp(@SCRIPT_TASKLINES);
	close SCRIPT_TASKFILE;
	
	$SCRIPT_TASKREV = BMPIC_getLastRevisionNumber("$BMPIC_NAME_TASKS$SCRIPT_TASKFILENAME.task");
	
	$SCRIPT_TARGETPATH = BMPIC_getRelativePath($SCRIPT_TARGET);
	$SCRIPT_TARGETPATH = $BMPIC_NAME_BRANCHES.$SCRIPT_TARGETPATH if exists $opt{'b'};
	$SCRIPT_TARGETPATH = $BMPIC_NAME_TRUNK.$SCRIPT_TARGETPATH if exists $opt{'k'};
	die "Not possible to apply tasks on non-directories" if !BMPIC_isDirectory($SCRIPT_TARGETPATH);
	$SCRIPT_TARGETPATH .= '/';
}


###############################################
# Construct the command(s)
###############################################
sub SCRIPT_constructCommand()
{
	foreach (@SCRIPT_CHANGELIST){
	
		($SCRIPT_CHANGEITEMREV, $SCRIPT_CHANGEFOUNDATION, $SCRIPT_CHANGEITEM, $SCRIPT_CHANGETASK)
			= split(/,/);
		
		$SCRIPT_SOURCE = $SCRIPT_RECIPEFOUNDATION.$SCRIPT_RECIPEITEMNAME;
		$SCRIPT_TARGET = $SCRIPT_TARGETPATH.$SCRIPT_RECIPEITEMNAME;
		
		# TODO : Tasks may only be applied on compatible trees. Compatibility check would
		# be good, but not essential. current limitation.
		
		# TODO:	Cannot modify directories because they would contain other files as well
		# Directory needs to be maintained in the task file for a permanenent solution
		# if and when implemented
		
		if(! BMPIC_isDirectory($SCRIPT_SOURCE)){
			# TODO: we need to use merge for this, to retain author info
			$SCRIPT_COMMAND = $SCRIPT_DELETEMODE?
				"delete $BMPIC_WCOPY$SCRIPT_TARGET":
				"export -r$SCRIPT_RECIPEITEMREV  --force $BMPIC_SVN_URL$SCRIPT_SOURCE $BMPIC_WCOPY$SCRIPT_TARGET";
			push(@SCRIPT_COMMANDLIST, $SCRIPT_COMMAND);
		}
		
	}
	
	$SCRIPT_COMMAND = "commit $BMPIC_WCOPY$SCRIPT_TARGETPATH -m\"~~BIRD~~ Applied task $SCRIPT_TASKFILE\n @SCRIPT_UPDATELIST\"";
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
		BMPIC_getSVNCommandOutput($SCRIPT_COMMAND,1);
	}
}

###############################################
# Update BMPIC stuff
###############################################
sub SCRIPT_maintainBMPIC()
{
	@SCRIPT_RECIPELINES = ();
	@SCRIPT_TASKLINES =();
	@SCRIPT_CHANGELIST=();
	
	$SCRIPT_DELETEMAGICVALUE = "~~~~xx!xx~~~~";
	$SCRIPT_RECIPEFILE = $SCRIPT_TARGETPATH . $BMPIC_FILE_RECIPE;
	
	BMPIC_ensureItemPresent("$SCRIPT_RECIPEFILE", 1);
	open (RECIPE, "$BMPIC_WCOPY$SCRIPT_RECIPEFILE") or die "Could not create recipe!";
	@SCRIPT_RECIPELINES = <RECIPE>;
	chomp(@SCRIPT_RECIPELINES);
	close RECIPE;
	
	open (TASKFILE,"$BMPIC_WCOPY$SCRIPT_TASKFILE") or die "Could not open file $BMPIC_WCOPY$SCRIPT_TASKFILE.";
	@SCRIPT_TASKLINES = <TASKFILE>;
	chomp(@SCRIPT_TASKLINES);
	close TASKFILE;
		
	# Look in task-file lines
	foreach $SCRIPT_TASKLINE(@SCRIPT_TASKLINES){

		my ($SCRIPT_TASKITEMREV, $SCRIPT_TASKFOUNDATION, $SCRIPT_TASKITEMNAME) 
			= split(/,/,$SCRIPT_TASKLINE,3);
				
		$SCRIPT_UPDATERECIPELINE = 1;
		$SCRIPT_TASKITEMNAME =~  s/\s+$//i;
		$i=0;
		$SCRIPT_FOUNDITEMINRECIPE=0;

		foreach $SCRIPT_RECIPELINE(@SCRIPT_RECIPELINES){
			($SCRIPT_RECIPEITEMREV, $SCRIPT_RECIPEFOUNDATION, $SCRIPT_RECIPEITEMNAME, $SCRIPT_RECIPETASK) = split(/,/,$SCRIPT_RECIPELINE);

			$SCRIPT_RECIPEITEMNAME =~ s/\s+$//i;
			if($SCRIPT_RECIPEITEMNAME =~ m/\Q$SCRIPT_TASKITEMNAME/i){
				print "$SCRIPT_TASKITEMNAME found...";
				$SCRIPT_FOUNDITEMINRECIPE=1;
				last if($SCRIPT_SMARTUPDATE == 0);

				# This is the smart zone!
				my $SCRIPT_SAMETASK = 0;
				my $SCRIPT_DIFFBASE = 1;
				my $SCRIPT_TASKITEMNEWER = 0;
				my $SCRIPT_ITEMCHANGED = 0;
				
				$SCRIPT_RECIPETASK =~ s/\s+$//i;
				$SCRIPT_RECIPEFOUNDATION =~ s/\s+$//i;
				
				# check item characteristics
				$SCRIPT_SAMETASK = 1 if ($SCRIPT_RECIPETASK eq $SCRIPT_TASKFILE);
				$SCRIPT_DIFFBASE = 0 if ($SCRIPT_RECIPEFOUNDATION eq $SCRIPT_TASKFOUNDATION);
				$SCRIPT_TASKITEMNEWER = 1 if($SCRIPT_TASKITEMREV != $SCRIPT_RECIPEITEMREV);
				
				$SCRIPT_ITEMCHANGED = $SCRIPT_SAMEFOUNDATION | $SCRIPT_TASKITEMNEWER;

				if ($SCRIPT_ADDONLYIFSAMETASK){
					if(!$SCRIPT_SAMETASK){
						$SCRIPT_UPDATERECIPELINE = 0;
						print "not owner...";
						last ;
					}
				}
				
				if(!$SCRIPT_ITEMCHANGED){
					$SCRIPT_UPDATERECIPELINE = 0 if !$SCRIPT_DELETEMODE;
					print "not changed...";
					last;
				}
				
				last;
			}
			$i++;
		} # Recipe foreach

		if (!$SCRIPT_FOUNDITEMINRECIPE){
			print "$SCRIPT_TASKITEMNAME absent...";
			$SCRIPT_UPDATERECIPELINE=0 if $SCRIPT_REFRESHONLY;
			$SCRIPT_UPDATERECIPELINE=0 if $SCRIPT_DELETEMODE;
		}

		# Update the recipe-lines if needed
		if($SCRIPT_UPDATERECIPELINE == 1) {
			$SCRIPT_RECIPELINES[$i] = "$SCRIPT_TASKITEMREV,$SCRIPT_TASKFOUNDATION,$SCRIPT_TASKITEMNAME,$SCRIPT_TASKFILE";
			
			push (@SCRIPT_CHANGELIST, $SCRIPT_RECIPELINES[$i]);
			push(@SCRIPT_UPDATELIST, "$SCRIPT_TASKITEMNAME\n");
			print "updating.\n";
			
			$SCRIPT_RECIPELINES[$i] = $SCRIPT_DELETEMAGICVALUE if $SCRIPT_DELETEMODE;
			# Using magic-value for marking for deletion
			# not shifting/splicing because in foreach loop based on list
			# TODO change magic value implementation
		}
		else{
			print "ignoring.\n";
		}
	
	}
	print "\n";
		
	# Save the changed(?) recipe
	open (RECIPE,">$BMPIC_WCOPY$SCRIPT_RECIPEFILE") or die "Could not create recipe.";
	foreach $SCRIPT_RECIPELINE(@SCRIPT_RECIPELINES){
		print RECIPE "$SCRIPT_RECIPELINE\n" unless $SCRIPT_RECIPELINE eq $SCRIPT_DELETEMAGICVALUE;
	}
	close RECIPE;
	
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

# system("pause");

