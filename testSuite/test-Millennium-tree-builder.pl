#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
use lib $ENV{'GALACTICUS_EXEC_PATH'}."/perl";
use File::Which;

# Take trees from the Millennium Database and process into both Galacticus and IRATE formats.
# Andrew Benson (12-October-2012)

# Create a file in Galacticus format.
system("cd ..; ./Galacticus.exe testSuite/parameters/mergerTreeFileBuildMillennium.xml");
die("FAILED: failed to make Galacticus-format merger tree file from Millennium database output")
    unless ( $? == 0 );

# Create a file in IRATE format.
system("cd ..; ./Galacticus.exe testSuite/parameters/mergerTreeFileBuildMillenniumIRATE.xml");
die("FAILED: failed to make IRATE-format merger tree file from Millennium database output")
    unless ( $? == 0 );

# Validate the IRATE format file.
my $validator = &File::Which::which('iratevalidate');
if ( $validator ) {
    system("cd ..; iratevalidate testSuite/outputs/millenniumTestTreesIRATE.hdf5");
    die("FAILED: IRATE-format file generated from Millennium database output did not validate")
	unless ( $? == 0 );
} else {
    print "SKIPPED: iratevalidate is not installed - validation of IRATE-format file will be skipped\n";
}

exit;
