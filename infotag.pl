#! /usr/bin/perl -w

#!/usr/bin/perl
#
# MODIFICATION HISTORY
# 20080215,ylc,providing options for taging  and restructuring the code
# 20080123,tj,Working, bug: missing ; corrected
# 20080123,tj,Adding revision number in format
# 20080122,tj,Adapted from ylc branch
#

###############################################
# Variables
# Default parameters for script
###############################################
sub INFOTAG_exportDefaults()
{

}

###############################################
# Create an empty INFOTAG file
###############################################
sub INFOTAG_create()
{

	open(INFOTAG, ">$BMPIC_WCOPY_INFOTAGS") or die "Can't open $BMPIC_WCOPY_INFOTAGS !";
	
	print(INFOTAG "#####################\n");
	print(INFOTAG "# BMPIC TAG Info File\n");
	print(INFOTAG "#####################\n");
	
	close(INFOTAG);
}

###############################################
# read entire contents into memory
###############################################
sub INFOTAG_readAll()
{
	open (INFOTAG, "$BMPIC_WCOPY_INFOTAGS") or die "Can't open $BMPIC_WCOPY_INFOTAGS !";
	@INFOTAG_LINES = <INFOTAG>;
	# strip newlines
	chomp(@INFOTAG_LINES);
	close(INFOTAG);
	print "Read the tag-information file.\n" if $BMPIC_VERBOSE;
}


###############################################
# Add new line into the file, 
# should be called after readAll()
###############################################
sub INFOTAG_addNewLine
{
	my ($INFOTAG_ITEM) = @_;
	
	$INFOTAG_REVISION = BMPIC_getLastRevisionNumber($INFOTAG_ITEM);

	print "The item $INFOTAG_ITEM is at revision $INFOTAG_REVISION \n" if $BMPIC_VERBOSE;

	$SCRIPT_TAGNAME = BMPIC_getItemName($INFOTAG_ITEM);
	$INFOTAG_NEWLINE = "$INFOTAG_REVISION,$BMPIC_DATE,$SCRIPT_TAGNAME,@SCRIPT_COMMENT";
	
	push(@INFOTAG_LINES, $INFOTAG_NEWLINE);

	open (INFOTAG,">$BMPIC_WCOPY_INFOTAGS") or die "Can't open $BMPIC_WCOPY_INFOTAGS !";
	foreach(@INFOTAG_LINES){
		print(INFOTAG"$_\n");
		}
	close(INFOTAG);
	
	print "Added line to $BMPIC_WCOPY_INFOTAGS: \n" if $BMPIC_VERBOSE;
	print "$INFOTAG_NEWLINE \n";
}

