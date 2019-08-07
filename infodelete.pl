#! /usr/bin/perl -w

#!/usr/bin/perl
#
# MODIFICATION HISTORY
# 20080121,ylc,Initial version based on infobranch.pl
#

###############################################
# Variables
# Default parameters for script
###############################################
sub INFODELETE_exportDefaults()
{

}

###############################################
# Create an empty INFODELETE file
###############################################
sub INFODELETE_create()
{

	open(INFODELETE, ">$BMPIC_WCOPY_INFODELETE") or die "Can't open $BMPIC_WCOPY_INFODELETE !";
	
	print(INFODELETE "#####################\n");
	print(INFODELETE "# BMPIC Delete Info File\n");
	print(INFODELETE "#####################\n");
	
	close(INFODELETE);
}

###############################################
# read entire contents into memory
###############################################
sub INFODELETE_readAll()
{
	open (INFODELETE, "$BMPIC_WCOPY_INFODELETE") or die "Can't open $BMPIC_WCOPY_INFODELETE !";
	@INFODELETE_LINES = <INFODELETE>;
	# strip newlines
	chomp(@INFODELETE_LINES);
	close(INFODELETE);
}

###############################################
# Add new line into the file, should be called after readAll()
###############################################
sub INFODELETE_addNewLine
{
	my ($DELETED_ITEM) = @_;
	
	$INFODELETE_NEWLINE = "$ITEMDELETE_REVISION,$BMPIC_DATE,$DELETED_ITEM,@SCRIPT_COMMENT";
	
	push(@INFODELETE_LINES, $INFODELETE_NEWLINE);

	open (INFODELETE,">$BMPIC_WCOPY_INFODELETE") or die "Can't open $BMPIC_WCOPY_INFODELETE !";
	foreach(@INFODELETE_LINES){
		print(INFODELETE"$_\n");
		}
	close(INFODELETE);
}