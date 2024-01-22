package geometry;
require Exporter;

use lib ("$ENV{GEMC}/io");
use utils;
use 5.010;

@ISA = qw(Exporter);
@EXPORT = qw(print_det init_det);


# Initialize hash maps
sub init_det
{
	my %detector = ();
	
	# These default value can be left off on the API
	$detector{"description"} = "no description";
	$detector{"pos"}         = "0 0 0";
	$detector{"rotation"}    = "0 0 0";
	$detector{"dimensions"}   = "0";
	$detector{"color"}       = "999999";
	$detector{"mfield"}      = "no";
	$detector{"ncopy"}       = "1";
	$detector{"pMany"}       = 1;
	$detector{"exist"}       = 1;
	$detector{"visible"}     = 1;
	$detector{"style"}       = 0;
	$detector{"sensitivity"} = "no";
	$detector{"hit_type"}    = "no";
	$detector{"identifiers"} = "no";
	
	return %detector;
}


# Print detector to TEXT file or upload it onto the DB
sub print_det
{
	my %configuration = %{+shift};
	my %det           = %{+shift};
	
	my $table = $configuration{"detector_name"}."__geometry";
	my $varia = $configuration{"variation"};
	my $runno = $configuration{"run_number"};

	
	# converting the hash maps in local variables
	# (this is necessary to parse the MYSQL command)
	
	my $lname        = trim($det{"name"});
	my $lmother      = trim($det{"mother"});
	my $ldescription = trim($det{"description"});
	my $lpos         = trim($det{"pos"});
	my $lrotation    = trim($det{"rotation"});
	my $lcolor       = trim($det{"color"});
	my $ltype        = trim($det{"type"});
	my $ldimensions  = trim($det{"dimensions"});
	my $lmaterial    = trim($det{"material"});
	my $lmfield      = trim($det{"mfield"});
	my $lncopy       = trim($det{"ncopy"});
	my $lpMany       = trim($det{"pMany"});
	my $lexist       = trim($det{"exist"});
	my $lvisible     = trim($det{"visible"});
	my $lstyle       = trim($det{"style"});
	my $lsensitivity = trim($det{"sensitivity"});
	my $lhit_type    = trim($det{"hit_type"});
	my $lidentifiers = trim($det{"identifiers"});
	
	# after 5.10 once can use "state" to use a static variable`
	state $counter = 0;
	state $this_variation = "";
	
	# TEXT Factory
	if($configuration{"factory"} eq "TEXT") {

		my $file = $configuration{"detector_name"}."__geometry_".$varia.".txt";
		if($counter == 0 || $this_variation ne  $varia) {
			`rm -f $file`;
			print "Overwriting if existing: ",  $file, "\n";
			$counter = 1;
			$this_variation = $varia;
		}

		open(INFO, ">>$file");
		printf INFO ("%20s  |", $lname);
		printf INFO ("%20s  |", $lmother);
		printf INFO ("%30s  |", $ldescription);
		printf INFO ("%50s  |", $lpos);
		printf INFO ("%40s  |", $lrotation);
		printf INFO ("%7s   |", $lcolor);
		printf INFO ("%20s  |", $ltype);
		printf INFO ("%60s  |", $ldimensions);
		printf INFO ("%20s  |", $lmaterial);
		printf INFO ("%20s  |", $lmfield);
		printf INFO ("%6s   |", $lncopy);
		printf INFO ("%6s   |", $lpMany);
		printf INFO ("%6s   |", $lexist);
		printf INFO ("%4s   |", $lvisible);
		printf INFO ("%4s   |", $lstyle);
		printf INFO ("%20s  |", $lsensitivity);
		printf INFO ("%20s  |", $lhit_type);
		printf INFO ("%40s \n", $lidentifiers);
		close(INFO);

	}
	
	# MYSQL Factory
	if($configuration{"factory"} eq "MYSQL") {

		my $dbh = open_db(%configuration);
		my $next_id = $configuration{"this_geo_id"};
		
		# after 5.10 once can use "state" to use a static variable`
		if($counter == 0)
		{
			print "   > Last Geometry ID: ", $next_id;
			print "\n \n";
			$counter = 1;
		}
		
		my $dbq = $dbh->do("insert into $table ( \
				    name,   mother,   description,   pos,        rot,     col,   type,   dimensions,   material, magfield,   ncopy,   pMany,   exist,   visible,   style,   sensitivity,    hitType,      identity,   rmin,   rmax,   variation,      id) \
			values(    ?,        ?,             ?,     ?,          ?,       ?,      ?,            ?,          ?,        ?,       ?,       ?,       ?,         ?,       ?,             ?,          ?,             ?,      ?,      ?,           ?,       ?)",  undef,
			      $lname, $lmother, $ldescription, $lpos, $lrotation, $lcolor, $ltype, $ldimensions, $lmaterial, $lmfield, $lncopy, $lpMany, $lexist, $lvisible, $lstyle, $lsensitivity, $lhit_type, $lidentifiers,  $rmin,  $rmax,      $varia, $next_id);
		
		if($configuration{"verbosity"} > 0 && $dbq == 1) {
			print "  + Detector element $lname uploaded successfully for variation \"$varia\" rmin=$rmin  rmax=$rmax  \n";
		}
		$dbh->disconnect();
	}

	# CSQL Factory
	if($configuration{"factory"} eq "SQLITE") {

		my $dbh = open_db(%configuration);
		my $system = $configuration{"detector_name"};
		my $names_string = "system, variation, run, name, mother, description, pos, rot, col, type, dimensions, material, magfield, ncopy, pMany, exist, visible, style, sensitivity, hitType, identity";

		# for each name in $names_string, we need to add a ? to the values string
	    my $qvalues_string = "";
	    my @names = split(/\s+/, $names_string);
	    foreach my $name (@names) {
	    	$qvalues_string = $qvalues_string . "?, ";
	    }
	    # remove last comma from $qvalues_string
	    $qvalues_string = substr($qvalues_string, 0, -2);

	#	my $values_string = "'$system', '$varia', '$runno',  '$lname', '$lmother', '$ldescription', '$lpos', '$lrotation', '$lcolor', '$ltype', '$ldimensions', '$lmaterial', '$lmfield', '$lncopy', '$lpMany', '$lexist', '$lvisible', '$lstyle', '$lsensitivity', '$lhit_type', '$lidentifiers', ";
#
#	    # SQL statement for inserting a row
#    	#my $sql = "INSERT INTO geometry (name, email, address) VALUES (?, ?, ?)";
    	my $sql = "INSERT INTO geometry ($names_string) VALUES ($qvalues_string)";

    	# print sql statement
    	#print "sql: $sql\n";
#
#    	# Prepare and execute the SQL statement
    	my $sth = $dbh->prepare($sql);
    	$sth->execute($system, $varia, $runno,  $lname, $lmother, $ldescription, $lpos, $lrotation, $lcolor, $ltype, $ldimensions, $lmaterial, $lmfield, $lncopy, $lpMany, $lexist, $lvisible, $lstyle, $lsensitivity, $lhit_type, $lidentifiers);


#		print "  + Detector element $lname uploaded successfully for variation \"$varia\", run number $runno \n";


#
#		my $dbq = $dbh->do("insert into $table ( \
#				    name,   mother,   description,   pos,        rot,     col,   type,   dimensions,   material, magfield,   ncopy,   pMany,   exist,   visible,   style,   sensitivity,    hitType,      identity,   rmin,   rmax,   variation,      id) \

	}
}


1;





