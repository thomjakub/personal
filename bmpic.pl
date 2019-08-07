#!/usr/bin/perl
#
# MODIFICATION HISTORY
# 20080215,ylc,Adding support for relative path in getParent and getItemname
# 20080215,tj,Adding addToWorkingCopy
# 20080214,tj,optionCheckDependencyChain, cleaning up unnecessary debugs
# 20080214,tj,Removing display for internal info getting functions
# 20080213,tj,Adding buildrecipe parameter to INI file
# 20080213,tj,Adding ensureItemPresent
# 20080213,tj,Adding options to getSVNCommandOutput
# 20080213,ylc,Added some SVN info for supporting relative paths
# 20080212,tj,BMPIC_doesItemExist bug fixed, convention not followed
# 20080211,tj,adding tasks folder support
# 20080211,tj,making it support relative paths only
# 20080209,tj,adding option-compatibility check functions
# 20080206,tj,added isURL, changed to just getRelativePath
# 20080206,tj,getItemRelativePathURL, getItemRelativePathLocal, getItemName
# 20080206,tj,Adding getFirstRevisionNumber
# 20080129,tj,Added BMPIC_normalizePath
# 20080129,tj,Does ~BIRD~ for all commands! :-)
# 20080129,tj,Added getSVNCommandOutput
# 20080128,tj,Changed help-style
# 20080121,tj,getLastRevisionNumber functionality
# 20080123,ylc,To add advanced version of branchtag
# 20080110,tj,Added date
# 20080109,tj,Debug option, upper-case
# 20080109,tj,More perl-style
# 20080109,tj,Layered getopt options
# 20080108,tj,Initial version
#

###############################################
# Variables
# Default parameters for script
###############################################

$BMPIC_CONFIG_FILE = './bmpic.ini';
$BMPIC_VERBOSE = 0;
$BMPIC_OPTIONS = 'HBI:VD';
$BMPIC_DEBUG = 0;

sub BMPIC_exportDefaults()
{
	$BMPIC_CONFIG_FILE = './bmpic.ini';
	$BMPIC_VERBOSE = 0;
	$BMPIC_OPTIONS = 'HI:VD';
	$BMPIC_DEBUG = 0;
}

###############################################
# Read INI file
###############################################
sub BMPIC_readINIFile()
{
#Recipe from http://www.unix.org.ua/orelly/perl/cookbook/ch08_17.htm

	print ("Read $BMPIC_CONFIG_FILE.\n") if $BMPIC_VERBOSE;
	open(INI, $BMPIC_CONFIG_FILE) or die "Couldn't open config file: $BMPIC_CONFIG_FILE!\n";
	while (<INI>) {
	    chomp;                  # no newline
	    s/#.*//;                # no comments
	    s/^\s+//;               # no leading white
	    s/\s+$//;               # no trailing white
	    next unless length;     # anything left?
	    			#length is a Perl keyword
	    
	    # Split it into key/value
	    my ($var, $value) = split(/\s*=\s*/, $_, 2);
	    
	    # We store the values in a hash
	    $BMPIC_Parameter{$var} = $value;
	}
	close(INI);
}

###############################################
# BMPIC Help display function
###############################################
sub BMPIC_displayHelp()
{
	print("OPTIONS: General BMPIC\n");
	print("-D\t: Debug/test mode\n");
	print("-I ARG\t: Specify INI file to use\n");
	print("-V\t: Verbose mode\n");
	print("-H\t: Print help message\n");
}


###############################################
# Display BMPIC parameters, for debug
###############################################
sub BMPIC_displayReadParameters()
{
	print("Parameters read from INI file: $BMPIC_CONFIG_FILE\n");
	
	foreach $key (keys %BMPIC_Parameter) {
	    $value = $BMPIC_Parameter{$key};
	    print("\t$key = $value\n");
	}
}


###############################################
# Store generally useful paths based on SVN URL
# and WCOPY path. Pass in order URL, PATH
# Should not use () in declaration here
###############################################
sub BMPIC_generatePaths
{
	my ($SVN, $WCOPY) = @_;
		
	$BMPIC_SVN_TRUNK = $SVN . $BMPIC_Parameter{'nametrunk'}; 
	print("\t$BMPIC_SVN_TRUNK\n") if $BMPIC_VERBOSE ; 
	$BMPIC_SVN_TAGS  = $SVN . $BMPIC_Parameter{'nametag'};
	print("\t$BMPIC_SVN_TAGS\n") if $BMPIC_VERBOSE;
	$BMPIC_SVN_BRANCHES = $SVN . $BMPIC_Parameter{'namebranch'};
	print("\t$BMPIC_SVN_BRANCHES\n") if $BMPIC_VERBOSE;
	$BMPIC_SVN_PATCHES = $SVN . $BMPIC_Parameter{'namepatch'};
	print("\t$BMPIC_SVN_PATCHES\n") if $BMPIC_VERBOSE;
	$BMPIC_SVN_TASKS = $SVN . $BMPIC_Parameter{'nametasks'};
	
	$BMPIC_WCOPY_TRUNK = $WCOPY . $BMPIC_Parameter{'nametrunk'}; 
	print("\t$BMPIC_WCOPY_TRUNK\n") if $BMPIC_VERBOSE; 
	$BMPIC_WCOPY_TAGS  = $WCOPY . $BMPIC_Parameter{'nametag'};
	print("\t$BMPIC_WCOPY_TAGS\n") if $BMPIC_VERBOSE;
	$BMPIC_WCOPY_BRANCHES = $WCOPY . $BMPIC_Parameter{'namebranch'};
	print("\t$BMPIC_WCOPY_BRANCHES\n") if $BMPIC_VERBOSE;
	$BMPIC_WCOPY_PATCHES = $WCOPY . $BMPIC_Parameter{'namepatch'};
	print("\t$BMPIC_WCOPY_PATCHES\n") if $BMPIC_VERBOSE;
	$BMPIC_WCOPY_TASKS = $WCOPY . $BMPIC_Parameter{'nametasks'};
	
	# The following are process-mandated single-ton files
	# So, storing paths.
	$BMPIC_SVN_INFOAUTHOR = $BMPIC_SVN_BRANCHES . $BMPIC_FILE_AUTHORS;
	print("\t$BMPIC_SVN_INFOAUTHOR\n") if $BMPIC_VERBOSE;
	$BMPIC_SVN_INFOBRANCH = $BMPIC_SVN_BRANCHES . $BMPIC_FILE_BRANCHES;
	print("\t$BMPIC_SVN_INFOBRANCH\n") if $BMPIC_VERBOSE;
	$BMPIC_SVN_INFOTAGS = $BMPIC_SVN_TAGS . $BMPIC_FILE_TAGS;
	print("\t$BMPIC_SVN_INFOTAGS\n") if $BMPIC_VERBOSE;
	
	$BMPIC_WCOPY_INFOAUTHOR = $BMPIC_WCOPY_BRANCHES . $BMPIC_FILE_AUTHORS;
	print("\t$BMPIC_WCOPY_INFOAUTHOR\n") if $BMPIC_VERBOSE;
	$BMPIC_WCOPY_INFOBRANCH = $BMPIC_WCOPY_BRANCHES . $BMPIC_FILE_BRANCHES;
	print("\t$BMPIC_WCOPY_INFOBRANCH\n") if $BMPIC_VERBOSE;
	$BMPIC_WCOPY_INFOTAGS = $BMPIC_WCOPY_TAGS . $BMPIC_FILE_TAGS;
	print("\t$BMPIC_WCOPY_INFOTAGS\n") if $BMPIC_VERBOSE;

}

###############################################
# Generate BMPIC parameters, for debug
###############################################
sub BMPIC_generateParameters()
{
	# Direct parameters
	$BMPIC_PROJECT = $BMPIC_Parameter{'projectname'};
	print("\t$BMPIC_PROJECT\n") if $BMPIC_VERBOSE;
	$BMPIC_AUTHORSHORT = $BMPIC_Parameter{'authorshort'};
	print("\t$BMPIC_AUTHORSHORT\n") if $BMPIC_VERBOSE;
	$BMPIC_AUTHORNAME = $BMPIC_Parameter{'authorname'};
	print("\t$BMPIC_AUTHORNAME\n") if $BMPIC_VERBOSE;
	$BMPIC_SVN_URL = $BMPIC_Parameter{'svnrepo'};
	print("\t$BMPIC_SVN_URL\n") if $BMPIC_VERBOSE;
	$BMPIC_SVNCLIENTDIR = $BMPIC_Parameter{'svnclientdir'};
	print("\t$BMPIC_SVNCLIENTDIR\n") if $BMPIC_VERBOSE;
	$BMPIC_SVNCLIENTBIN = $BMPIC_Parameter{'svnbinary'};
	print("\t$BMPIC_SVNCLIENTBIN\n") if $BMPIC_VERBOSE;
	$BMPIC_WCOPY = $BMPIC_Parameter{'workingcopy'};
	print("\t$BMPIC_WCOPY\n") if $BMPIC_VERBOSE;
	
	$BMPIC_FILE_AUTHORS = $BMPIC_Parameter{'fileauthors'};
	print("\t$BMPIC_FILE_AUTHORS\n") if $BMPIC_VERBOSE;
	$BMPIC_FILE_BRANCHES = $BMPIC_Parameter{'filebranchinfo'};
	print("\t$BMPIC_FILE_BRANCHES\n") if $BMPIC_VERBOSE;
	$BMPIC_FILE_CHANGELOG = $BMPIC_Parameter{'filechangelog'};
	print("\t$BMPIC_FILE_CHANGELOG\n") if $BMPIC_VERBOSE;
	$BMPIC_FILE_DELETES = $BMPIC_Parameter{'filedeletions'};
	print("\t$BMPIC_FILE_DELETES\n") if $BMPIC_VERBOSE;
	$BMPIC_FILE_TAGS = $BMPIC_Parameter{'filetaginfo'};
	print("\t$BMPIC_FILE_TAGS\n") if $BMPIC_VERBOSE;
	$BMPIC_FILE_RECIPE = $BMPIC_Parameter{'filebuildrecipe'};

	$BMPIC_NAME_TRUNK = $BMPIC_Parameter{'nametrunk'}; 
	$BMPIC_NAME_TAGS  = $BMPIC_Parameter{'nametag'};
	$BMPIC_NAME_BRANCHES = $BMPIC_Parameter{'namebranch'};
	$BMPIC_NAME_PATCHES = $BMPIC_Parameter{'namepatch'};
	$BMPIC_NAME_TASKS = $BMPIC_Parameter{'nametasks'};
	
	$BMPIC_DATE = sprintf("%04d-%02d-%02d", (localtime(time))[5] + 1900,
		(localtime(time))[4]+1, (localtime(time))[3]);
	print("\t$BMPIC_DATE\n") if $BMPIC_VERBOSE;

	# Derived/combinational parameters
	$BMPIC_SVNCLIENT = $BMPIC_SVNCLIENTDIR . $BMPIC_SVNCLIENTBIN . ' ';
	print("\t$BMPIC_SVNCLIENT\n") if $BMPIC_VERBOSE;
	
	$BMPIC_SVNINFOSOURCE = $BMPIC_WCOPY;
	
	BMPIC_generatePaths($BMPIC_SVN_URL, $BMPIC_WCOPY);

}

###############################################
# Load BMPIC parameters, call after getopt only
###############################################
sub BMPIC_configure()
{
	if (exists $opt{'I'}){
		$BMPIC_CONFIG_FILE =  $opt{'I'};
	}

	if (exists $opt{'V'}){
		$BMPIC_VERBOSE =  1;
	}
	
	if (exists $opt{'D'}){
		$BMPIC_DEBUG = 1;
	}

	BMPIC_readINIFile();
	BMPIC_displayReadParameters() if $BMPIC_VERBOSE;
	
	# TODO Validation of each parameter
	
	BMPIC_generateParameters();
}

###############################################
# Issue if not Debug, else print
###############################################
sub BMPIC_issueSVNCommand
{
	# TODO: Remove this function, use getSVNCommandOutput instead
	my ($BMPIC_COMMAND) = @_;
	$BMPIC_SVN_COMMAND = $BMPIC_SVNCLIENT . $BMPIC_COMMAND;
	print("Issuing command...\n") if $BMPIC_VERBOSE;
	print("~~ BIRD ~~ $BMPIC_SVN_COMMAND\n") ;
	system("$BMPIC_SVN_COMMAND") if !$BMPIC_DEBUG;
}


###############################################
# Issue if not Debug, else print
###############################################
sub BMPIC_getSVNCommandOutput
{
	my ($BMPIC_COMMAND, $BMPIC_HIDECOMMAND, $BMPIC_DISPLAYOUTPUT, $BMPIC_WHY) = @_;
	
	my ($BMPIC_SHOW) = !$BMPIC_HIDECOMMAND;

	$BMPIC_SVN_COMMAND = $BMPIC_SVNCLIENT . $BMPIC_COMMAND;
	
	print("Issuing command...") if $BMPIC_VERBOSE;
	print "$BMPIC_WHY" if $BMPIC_WHY;
	print("\n~~ BIRD ~~\n$BMPIC_SVN_COMMAND") if $BMPIC_SHOW;

	# TODO Capture error stream separately
	open(BMPIC_SVN_OUTPUT, "$BMPIC_SVN_COMMAND 2>&1 |");
	my @BMPIC_SVNOUTPUTLINES = <BMPIC_SVN_OUTPUT>;
	chomp(@BMPIC_SVNOUTPUTLINES);
	close(BMPIC_SVN_OUTPUT);

	foreach $BMPIC_LINE(@BMPIC_SVNOUTPUTLINES){
		print "\n$BMPIC_LINE" if $BMPIC_DISPLAYOUTPUT;
	}

	print("\n") if ($BMPIC_SHOW || $BMPIC_DISPLAYOUTPUT || $BMPIC_WHY);
	return @BMPIC_SVNOUTPUTLINES;
}

###############################################
# Makes paths platform-neutral
###############################################
sub BMPIC_normalizePath
{
	my ($BMPIC_PATH) = @_;
	
	# Replace backslashes with forward slash
	# Weird Perl! any character can be used to delimit the regex! ;-)
	$BMPIC_PATH =~ s@\\@/@g; 

	# Remove trailing /s
	# Weird Perl! any character can be used to delimit the regex! ;-)
	$BMPIC_PATH =~ s@/+$@@;

	return $BMPIC_PATH;
}

###############################################
# Minimal checks for item is  URL(0) or Path(1)
# Returns -1 when neither, 
# Returns  0 when URL
# Returns  1 when Path
###############################################
sub BMPIC_isPathOrURL
{
	($BMPIC_ITEM) = @_;
	
	$BMPIC_ITEM = BMPIC_normalizePath($BMPIC_ITEM);
	
	# Check for slashes
	# Weird Perl! any character can be used to delimit the regex! ;-)
	return -1 if(! $BMPIC_ITEM =~ m@/@i);
	
	# Check whether :// is present
	return 0 if($BMPIC_ITEM =~ m@://@);

	# Must be a path if it got this far
	return 1;
}

###############################################
# Returns last changed revision number of $item
###############################################
sub BMPIC_getLastRevisionNumber
{
	my ($BMPIC_ITEM) = @_;
	my $BMPIC_VALUE = "Not found!";
	my $BMPIC_COMMAND = "info $BMPIC_SVNINFOSOURCE$BMPIC_ITEM";
	
	@BMPIC_STATUS_LINES = BMPIC_getSVNCommandOutput($BMPIC_COMMAND,1);
	
	foreach $BMPIC_LINE(@BMPIC_STATUS_LINES){
	
		chomp($BMPIC_LINE);
		my ($var, $value) = split(/Last Changed Rev: /, $BMPIC_LINE, 2);
		if($value != "") {
			print "." if $BMPIC_DEBUG;
			$BMPIC_VALUE = sprintf("%05d", $value);
			return $BMPIC_VALUE;
		}
	} 
	
	$BMPIC_VALUE = 0;
	return $BMPIC_VALUE;
}
###############################################

###############################################
# Returns first changed revision number of $item
###############################################
sub BMPIC_getFirstRevisionNumber
{
	my ($BMPIC_ITEM) = @_;
	my $BMPIC_OLDEST = 0;
	my @BMPIC_REVLIST =();
	
	my $BMPIC_COMMAND = "log -q --stop-on-copy $BMPIC_SVNINFOSOURCE$BMPIC_ITEM";
	@BMPIC_LOGLINES = BMPIC_getSVNCommandOutput($BMPIC_COMMAND,1);
	
	foreach (@BMPIC_LOGLINES){
		chomp;
	    	s/-.*//;                # no -s, present log -q output
	    	s/\s+//;		# Not interested in spaces either
	    	next unless length;
	    	
	    	# log -q out is delimited by |s
	    	($BMPIC_TEST,$discard, $discard) = split(/\|/,$_,3);

	    	$BMPIC_TEST =~ s/r//;	#log -q output is in rXXXX format
	    	
	    	push(@BMPIC_REVLIST,$ BMPIC_TEST);
	} 
	
	# Determine the oldest
	$BMPIC_OLDEST = $BMPIC_REVLIST[0];
	foreach (@BMPIC_REVLIST) {
	        $BMPIC_OLDEST = ($_ < $BMPIC_OLDEST)? $_:$BMPIC_OLDEST;
    	}
	
	$BMPIC_OLDEST = sprintf("%05d", $BMPIC_OLDEST);
	return $BMPIC_OLDEST;
}
###############################################

###############################################
# Returns ITEM path given full path
###############################################
sub BMPIC_getRelativePath
{
	my ($BMPIC_ITEM) = @_;
	my $BMPIC_ITEMPATH = BMPIC_normalizePath($BMPIC_ITEM);
	
	$BMPIC_PATHTYPE = BMPIC_isPathOrURL($BMPIC_ITEMPATH);
	
	die "Not a path" if $BMPIC_PATHTYPE == -1;
	
	$BMPIC_REPLACE = ($BMPIC_PATHTYPE == 0)? $BMPIC_SVN_URL : $BMPIC_WCOPY;
	
	$BMPIC_ITEMPATH =~ s/\Q$BMPIC_REPLACE//i;
	print "$BMPIC_REPLACE replaced in $BMPIC_ITEMPATH\n" if $BMPIC_DEBUG;
	
	return $BMPIC_ITEMPATH;
}
###############################################

###############################################
# Checks whether directory or not
###############################################
sub BMPIC_isDirectory
{
	my ($BMPIC_ITEM) = @_;
	
	$BMPIC_ITEM = BMPIC_normalizePath($BMPIC_ITEM);
	
	my $BMPIC_COMMAND ="info $BMPIC_SVNINFOSOURCE$BMPIC_ITEM";
	
	@BMPIC_STATUS_LINES = BMPIC_getSVNCommandOutput($BMPIC_COMMAND,1);
	
	foreach $BMPIC_LINE(@BMPIC_STATUS_LINES){
	
		chomp($BMPIC_LINE);
		my ($var, $value) = split(/Node Kind: /, $BMPIC_LINE, 2);
		if($value eq "directory") {
			return 1;
		}
	} 
	
	return 0;
}
###############################################

###############################################
# Returns ITEM name given path
###############################################
sub BMPIC_getItemName
{
	my ($BMPIC_ITEM) = @_;
	$BMPIC_ITEM = $BMPIC_WCOPY.$BMPIC_ITEM;
	$BMPIC_ITEM = BMPIC_normalizePath($BMPIC_ITEM);
	
	$BMPIC_ITEM = reverse($BMPIC_ITEM);
	($BMPIC_ITEM) = split(/\//,$BMPIC_ITEM,2);
	$BMPIC_ITEM = reverse($BMPIC_ITEM);
	
	return $BMPIC_ITEM;
}
###############################################

###############################################
# Returns ITEM's parent directory
###############################################
sub BMPIC_getParent
{
	my ($BMPIC_ITEM) = @_;
	$BMPIC_ITEM = $BMPIC_WCOPY.$BMPIC_ITEM;
	$BMPIC_ITEM = BMPIC_normalizePath($BMPIC_ITEM);
	
	$BMPIC_ITEM = reverse($BMPIC_ITEM);
	($BMPIC_ITEM, $BMPIC_PARENT) = split(/\//,$BMPIC_ITEM,2);
	$BMPIC_PARENT = reverse($BMPIC_PARENT);
	
	return $BMPIC_PARENT;
}
###############################################

###############################################
# Dies if mutually incompatible option
###############################################
sub BMPIC_optionCheckIncompatible
{
	my ($BMPIC_SYNTAX) = @_;
	my @BMPIC_OPTIONS = split(//,$BMPIC_SYNTAX);
	my $BMPIC_ISNOTOK= 0;
	
	foreach $BMPIC_OPTION(@BMPIC_OPTIONS){
		$BMPIC_PRESENT = exists $opt{$BMPIC_OPTION}? 1:0;
		$BMPIC_ISNOTOK += $BMPIC_PRESENT;
	}
	
	die "Incompatible options given:$BMPIC_SYNTAX\n" if $BMPIC_ISNOTOK>1;	
}
###############################################

###############################################
# Dies if all these options not given
###############################################
sub BMPIC_optionCheckAllNeeded
{
	my ($BMPIC_SYNTAX) = @_;
	my @BMPIC_OPTIONS = split(//,$BMPIC_SYNTAX);
	my $BMPIC_ISOK=1;
	
	foreach $BMPIC_OPTION(@BMPIC_OPTIONS){
		$BMPIC_PRESENT = exists $opt{$BMPIC_OPTION}? 1:0;
		$BMPIC_ISOK &= $BMPIC_PRESENT;
	}

	die "Necessary option not given out of:$BMPIC_SYNTAX\n" if(!$BMPIC_ISOK);	

}
###############################################
# Dies if all these options not given
###############################################
sub BMPIC_optionCheckDependencyChain
{
	my ($BMPIC_SYNTAX) = @_;
	my @BMPIC_OPTIONS = split(//,$BMPIC_SYNTAX);
	my $BMPIC_PREVGIVEN = 0;
	my $BMPIC_ISOK = 1;
	
	foreach $BMPIC_OPTION(@BMPIC_OPTIONS){
		$BMPIC_PRESENT = exists $opt{$BMPIC_OPTION}? 1:0;
		$BMPIC_ISOK &= $BMPIC_PRESENT if $BMPIC_PREVGIVEN;
		$BMPIC_PREVGIVEN = $BMPIC_PRESENT;
		print "\n";# if $BMPIC_DEBUG;
	}

	die "Necessary option not given out of:$BMPIC_SYNTAX\n" if(!$BMPIC_ISOK);	
}


###############################################

###############################################
# Check for item exist, returns TRUE  if exist else FALSE
###############################################
sub BMPIC_doesItemExist
{
	my ($BMPIC_ITEM) = @_;
	
	$BMPIC_COMMAND = "info $BMPIC_SVNINFOSOURCE$BMPIC_ITEM";
	@BMPIC_STATUSLINES = BMPIC_getSVNCommandOutput($BMPIC_COMMAND,1);
	
	$BMPIC_PRESENT = 1;
	# process the changeset
	foreach (@BMPIC_STATUSLINES){
		chomp($_);#no newline
		if($_ =~ /Not a/i) {
			$BMPIC_PRESENT = 0;
			last;
		}
	}
	
	print ("$BMPIC_ITEM exists? $BMPIC_PRESENT\n") if $BMPIC_DEBUG;
	return $BMPIC_PRESENT;
}

###############################################
# If item does not exist, create and add
###############################################
sub BMPIC_ensureItemPresent
{
	my ($BMPIC_ITEM, $BMPIC_CREATE) = @_;
	my $BMPIC_PRESENT = BMPIC_doesItemExist($BMPIC_ITEM);
	
	my $BMPIC_COMMAND ="";
	
	if($BMPIC_PRESENT){
		# Ensure latest version
		$BMPIC_COMMAND = "update $BMPIC_WCOPY$BMPIC_ITEM";
		BMPIC_getSVNCommandOutput($BMPIC_COMMAND,1);
	}
	else{
	
		if($BMPIC_CREATE){
			# Create and add, only files supported
			open (TASKFILE,">$BMPIC_WCOPY$BMPIC_ITEM") or die "Could not create file.";
			close TASKFILE;
		
			$BMPIC_COMMAND = "add $BMPIC_WCOPY$BMPIC_ITEM";
			BMPIC_getSVNCommandOutput($BMPIC_COMMAND,1);
		}
	}
}

###############################################
# Adds/deletes item present in item to working
# copy.
###############################################
sub BMPIC_addToWorkingCopy
{
	my ($BMPIC_ITEM, $BMPIC_DONTDELETE) = @_;
	
	my $BMPIC_COMMAND ="";
	my @BMPIC_ADDLIST = ();
	my @BMPIC_DELLIST =();
	
	# get changeset
	$BMPIC_TESTCOMMAND = "status $BMPIC_WCOPY$BMPIC_ITEM";
	
	@BMPIC_STATUSLINES = BMPIC_getSVNCommandOutput($BMPIC_TESTCOMMAND,0);
		
	# process the changeset
	foreach $BMPIC_STATUSLINE(@BMPIC_STATUSLINES){
		# 6 spaces in SVN diff output
		($BMPIC_STATUS, $BMPIC_ITEM)= split(/\s+/,$BMPIC_STATUSLINE); 
		print "Processed:$BMPIC_STATUS,$BMPIC_ITEM \n";# if $BMPIC_DEBUG;
			
		# Not added indication
		push(@BMPIC_ADDLIST, $BMPIC_ITEM) if $BMPIC_STATUS eq '?'; 
		
		if(!$BMPIC_DONTDELETE){
			#Not present indication
			push(@BMPIC_DELLIST, $BMPIC_ITEM) if $BMPIC_STATUS eq '!'; 
		}
	}
		
	# Make the changeset also tracked in the WC, for deleted/added files
	print"Add list:\n" if $BMPIC_VERBOSE;
	foreach (@BMPIC_ADDLIST){
		$BMPIC_COMMAND = "add \"$_\"";
		BMPIC_getSVNCommandOutput($BMPIC_COMMAND);
	}

	print"Del list:\n" if $BMPIC_VERBOSE ;
	foreach (@BMPIC_DELLIST){
		$BMPIC_COMMAND = "delete --force \"$_\"";
		BMPIC_getSVNCommandOutput($BMPIC_COMMAND);
	}
	
	return (@BMPIC_ADDLIST);
}


###############################################


################################################
################ MAIN ##########################
################################################

# Only for DEBUG!! Comment out if not debugging

# BMPIC_initialize();
# BMPIC_displayReadParameters();

################################################
################################################
################################################

#system("pause");
