package bank;
require Exporter;

use lib ("$ENV{GEMC}/io");
use utils;
use 5.010;

@ISA = qw(Exporter);
@EXPORT = qw(insert_bank_variable);


# Print bank to TEXT file or upload it onto the DB
sub insert_bank_variable
{
	
	if (@_ != 6){
		print " ERROR: To define a bank variable 4 arguments should be passed to <insert_bank_variable> \n";
	}
	
	my %configuration = %{+shift};
	
	my $varia = $configuration{"variation"};
	my $runno = $configuration{"run_number"};

	my $bname        = shift;  # bank name
	my $lname        = shift;  # variable name
	my $lnum         = shift;  # variable int (unique id)
	my $ltype        = shift;  # variable type
	my $ldescription = shift;  # description
	
    # after perl 5.10 once can use "state" to use a static variable`
	state $counter_text = 0;
	state $counter_mysql = 0;
	state $counter_sqlite = 0;


	# TEXT Factory
	if($configuration{"factory"} eq "TEXT") {
		my $file = $configuration{"detector_name"}."__bank.txt";
		if($counter_text == 0) {
			`rm -f $file`;
			print "Overwriting if existing: ",  $file, "\n";
			$counter_text = 1;
		}
		
		open(INFO, ">>$file");
		printf INFO ("%20s  |",  $bname);
		printf INFO ("%20s  |",  $lname);
		printf INFO ("%50s  |",  $ldescription);
		printf INFO ("%5s   |",  $lnum);
		printf INFO ("%20s  \n", $ltype);
		close(INFO);
	}
	
	# MYSQL Factory
	if($configuration{"factory"} eq "MYSQL") {

	}

    # SQLITE Factory
    if ($configuration{"factory"} eq "SQLITE") {
        my $dbh = open_db(%configuration);
        my $system = $configuration{"detector_name"};

        # first time this module is run, delete everything in geometry table for this variation, system and run number
        if ($counter_sqlite == 0) {
            my $sql = "DELETE FROM banks WHERE system = ?";
            my $sth = $dbh->prepare($sql);
            $sth->execute($system);
            print "   > Deleted all materials for system $system \n";
            $counter_sqlite = 1;
        }

        my $mnames_string = "system, bank_name, variable_name, description, int_id, type";
        my $mvalues_string = "?, ?, ?, ?, ?, ?";

        # for each name in $mnames_string, we need to add a ? to the values string
        my $qvalues_string = "";
        my @names = split(/\s+/, $mnames_string);
        foreach my $name (@names) {
            $qvalues_string = $qvalues_string . "?, ";
        }
        # remove last comma from $qvalues_string
        $qvalues_string = substr($qvalues_string, 0, -2);

        my $sql = "INSERT INTO banks ($mnames_string) VALUES ($qvalues_string)";

        my $sth = $dbh->prepare($sql);
        $sth->execute($system, $bname, $lname, $ldescription, $lnum, $ltype)
			or die "Can't execute insert statement: $DBI::errstr";
	}

	if($configuration{"verbosity"} > 0) {
		print "  + variable $lname uploaded successfully for variation \"$varia\" \n";
	}
	
	
}


1;





