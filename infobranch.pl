#! /usr/bin/perl -w

#!/usr/bin/perl
#
# MODIFICATION HISTORY
# 20080121,ylc,Initial version based on infotag.pl
#

###############################################
# Variables
# Default parameters for script
###############################################
sub INFOBRANCH_exportDefaults()
{

}

###############################################
# Create an empty INFOBRANCH file
###############################################
sub INFOBRANCH_create()
{

	open(INFOBRANCH, ">$BMPIC_WCOPY_INFOBRANCH") or die "Can't open $BMPIC_WCOPY_INFOBRANCH !";
	
	print(INFOBRANCH "#####################\n");
	print(INFOBRANCH "# BMPIC Branch Info File\n");
	print(INFOBRANCH "#####################\n");
	
	close(INFOBRANCH);
}

###############################################
# read entire contents into memory
###############################################
sub INFOBRANCH_readAll()
{
	open (INFOBRANCH, "$BMPIC_WCOPY_INFOBRANCH") or die "Can't open $BMPIC_WCOPY_INFOBRANCH !";
	@INFOBRANCH_LINES = <INFOBRANCH>;
	# strip newlines
	chomp(@INFOBRANCH_LINES);
	close(INFOBRANCH);
}

###############################################
# Add new line into the file, should be called after readAll()
###############################################
sub INFOBRANCH_addNewLine
{
	my ($INFOBRANCH_ITEM) = @_;
	
	$INFOBRANCH_REVISION = BMPIC_getLastRevisionNumber($INFOBRANCH_ITEM);
		
	print "The item $INFOBRANCH_ITEM is at revision $INFOBRANCH_REVISION \n" if $BMPIC_VERBOSE;
	
	$INFOBRANCH_NEWLINE = "$INFOBRANCH_REVISION,$BMPIC_DATE,$SCRIPT_BRANCHNAME,@SCRIPT_COMMENT";
	
	push(@INFOBRANCH_LINES, $INFOBRANCH_NEWLINE);

	open (INFOBRANCH,">$BMPIC_WCOPY_INFOBRANCH") or die "Can't open $BMPIC_WCOPY_INFOBRANCH !";
	foreach(@INFOBRANCH_LINES){
		print(INFOBRANCH"$_\n");
		}
	close(INFOBRANCH);
}