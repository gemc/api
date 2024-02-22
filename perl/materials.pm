package materials;
require Exporter;

use lib ("$ENV{GEMC}/io");
use warnings;
use utils;
use 5.010;

@ISA = qw(Exporter);
@EXPORT = qw(init_mat print_mat);


# Initialize hash maps
sub init_mat {
    my %mat = ();

    # The default value for identifier is "id"
    $mat{"description"} = "id";

    # The optical properties are defaulted to none
    # User can define a optical property with arrays of:
    #
    # - photon wavelength (mandatory)
    # - At least one of the following quantities arrays
    $mat{"photonEnergy"} = "none";
    $mat{"indexOfRefraction"} = "none";
    $mat{"absorptionLength"} = "none";
    $mat{"reflectivity"} = "none";
    $mat{"efficiency"} = "none";

    # scintillation specific
    $mat{"fastcomponent"} = "none";
    $mat{"slowcomponent"} = "none";
    $mat{"scintillationyield"} = "-1";
    $mat{"resolutionscale"} = "-1";
    $mat{"fasttimeconstant"} = "-1";
    $mat{"slowtimeconstant"} = "-1";
    $mat{"yieldratio"} = "-1";
    $mat{"rayleigh"} = "none";
    $mat{"birkConstant"} = "-1";

    return %mat;
}


# Print material to TEXT file or upload it onto the DB
sub print_mat {
    my %configuration = %{+shift};
    my %mats = %{+shift};

	my $varia = $configuration{"variation"};
	my $runno = $configuration{"run_number"};

    # converting the hash maps in local variables
    # (this is necessary to parse the MYSQL command)
    my $lname = trim($mats{"name"});
    my $ldesc = trim($mats{"description"});
    my $ldensity = trim($mats{"density"});
    my $lncomponents = trim($mats{"ncomponents"});
    my $lcomponents = trim($mats{"components"});

    # optical properties
    my $lphotonEnergy = trim($mats{"photonEnergy"});
    my $lindexOfRefraction = trim($mats{"indexOfRefraction"});
    my $labsorptionLength = trim($mats{"absorptionLength"});
    my $lreflectivity = trim($mats{"reflectivity"});
    my $lefficiency = trim($mats{"efficiency"});

    # scintillation specific
    my $lfastcomponent = trim($mats{"fastcomponent"});
    my $lslowcomponent = trim($mats{"slowcomponent"});
    my $lscintillationyield = trim($mats{"scintillationyield"});
    my $lresolutionscale = trim($mats{"resolutionscale"});
    my $lfasttimeconstant = trim($mats{"fasttimeconstant"});
    my $lslowtimeconstant = trim($mats{"slowtimeconstant"});
    my $lyieldratio = trim($mats{"yieldratio"});
    my $lrayleigh = trim($mats{"rayleigh"});
    my $lbirkConstant = trim($mats{"birkConstant"});

    # after perl 5.10 once can use "state" to use a static variable`
	state $counter_text = 0;
	state $counter_mysql = 0;
	state $counter_sqlite = 0;

    state $this_variation = "";

    # TEXT Factory
    if ($configuration{"factory"} eq "TEXT") {
        my $file = $configuration{"detector_name"} . "__materials_" . $varia . ".txt";

        if ($counter_text == 0 || $this_variation ne $varia) {
            `rm -f $file`;
            print "Overwriting if existing: ", $file, "\n";
            $counter_text = 1;
            $this_variation = $varia;
        }

        open(INFO, ">>$file");
        # notice INFO( will not work, there has to be a space after INFO
        printf INFO ("%20s  |", $lname);
        printf INFO ("%30s  |", $ldesc);
        printf INFO ("%10s  |", $ldensity);
        printf INFO ("%10s  |", $lncomponents);
        printf INFO ("%50s  |", $lcomponents);

        if ($lphotonEnergy eq "none") {
            printf INFO ("%5s  |", $lphotonEnergy);
            printf INFO ("%5s  |", $lindexOfRefraction);
            printf INFO ("%5s  |", $labsorptionLength);
            printf INFO ("%5s  |", $lreflectivity);
            printf INFO ("%5s  |", $lefficiency);

            # scintillation
            printf INFO ("%5s  |", $lfastcomponent);
            printf INFO ("%5s  |", $lslowcomponent);
            printf INFO ("%5s  |", $lscintillationyield);
            printf INFO ("%5s  |", $lresolutionscale);
            printf INFO ("%5s  |", $lfasttimeconstant);
            printf INFO ("%5s  |", $lslowtimeconstant);
            printf INFO ("%5s  |", $lyieldratio);
            printf INFO ("%5s  |", $lrayleigh);
            printf INFO ("%5s  \n", $lbirkConstant);

        }
        else {
            printf INFO ("%s  |", $lphotonEnergy);

            # index of refraction
            if ($lindexOfRefraction eq "none") {printf INFO ("%5s |", $lindexOfRefraction);}
            else {printf INFO ("%s  |", $lindexOfRefraction);}
            # absorption length
            if ($labsorptionLength eq "none") {printf INFO ("%5s |", $labsorptionLength);}
            else {printf INFO ("%s  |", $labsorptionLength);}
            # reflectivity
            if ($lreflectivity eq "none") {printf INFO ("%5s |", $lreflectivity);}
            else {printf INFO ("%s  |", $lreflectivity);}
            # efficiency
            if ($lefficiency eq "none") {printf INFO ("%5s |", $lefficiency);}
            else {printf INFO ("%s  |", $lefficiency);}

            # scintillation

            # fast component (as function of wavelength)
            if ($lfastcomponent eq "none") {printf INFO ("%5s |", $lfastcomponent);}
            else {printf INFO ("%s  |", $lfastcomponent);}
            # slow component (as function of wavelength)
            if ($lslowcomponent eq "none") {printf INFO ("%5s |", $lslowcomponent);}
            else {printf INFO ("%s  |", $lslowcomponent);}
            # scintillation yield (constant)
            if ($lscintillationyield eq "-1") {printf INFO ("%5s |", $lscintillationyield);}
            else {printf INFO ("%s  |", $lscintillationyield);}
            # resolution scale (constant)
            if ($lresolutionscale eq "-1") {printf INFO ("%5s |", $lresolutionscale);}
            else {printf INFO ("%s  |", $lresolutionscale);}
            # fast time (constant)
            if ($lfasttimeconstant eq "-1") {printf INFO ("%5s |", $lfasttimeconstant);}
            else {printf INFO ("%s  |", $lfasttimeconstant);}
            # slow time (constant)
            if ($lslowtimeconstant eq "-1") {printf INFO ("%5s |", $lslowtimeconstant);}
            else {printf INFO ("%s  |", $lslowtimeconstant);}
            # ratio of yield to total yield for slow component (constant)
            if ($lyieldratio eq "-1") {printf INFO ("%5s |", $lyieldratio);}
            else {printf INFO ("%s  |", $lyieldratio);}
            # rayleigh scattering
            if ($lrayleigh eq "none") {printf INFO ("%5s |", $lrayleigh);}
            else {printf INFO ("%s  |", $lrayleigh);}
            # Birk constant
            if ($lbirkConstant eq "-1") {printf INFO ("%5s\n", $lbirkConstant);}
            else {printf INFO ("%s \n", $lbirkConstant);}
        }

        close(INFO);
    }

    # MYSQL Factory
    my $err;
    if ($configuration{"factory"} eq "MYSQL") {

    }

    # SQLITE Factory
    if ($configuration{"factory"} eq "SQLITE") {
        my $dbh = open_db(%configuration);
        my $system = $configuration{"detector_name"};

        # first time this module is run, delete everything in geometry table for this variation, system and run number
        if ($counter_sqlite == 0) {
            my $sql = "DELETE FROM materials WHERE system = ?";
            my $sth = $dbh->prepare($sql);
            $sth->execute($system);
            print "   > Deleted all materials for system $system \n";
            $counter_sqlite = 1;
        }

        my $mnames_string = "system, variation, run, name, description, density, ncomponents, components, photonEnergy, indexOfRefraction, absorptionLength, reflectivity, efficiency, fastcomponent, slowcomponent, scintillationyield, resolutionscale, fasttimeconstant, slowtimeconstant, yieldratio, rayleigh, birkConstant ";

        # for each name in $mnames_string, we need to add a ? to the values string
        my $qvalues_string = "";
        my @names = split(/\s+/, $mnames_string);
        foreach my $name (@names) {
            $qvalues_string = $qvalues_string . "?, ";
        }
        # remove last comma from $qvalues_string
        $qvalues_string = substr($qvalues_string, 0, -2);

        my $sql = "INSERT INTO materials ($mnames_string) VALUES ($qvalues_string)";

        my $sth = $dbh->prepare($sql);
        $sth->execute($system, $varia, $runno, $lname, $ldesc, $ldensity, $lncomponents, $lcomponents, $lphotonEnergy, $lindexOfRefraction, $labsorptionLength, $lreflectivity, $lefficiency, $lfastcomponent, $lslowcomponent, $lscintillationyield, $lresolutionscale, $lfasttimeconstant, $lslowtimeconstant, $lyieldratio, $lrayleigh, $lbirkConstant)
        	or die "SQL Error: $DBI::errstr\n";

    }

    if ($configuration{"verbosity"} > 0) {
        print "  + Material $lname uploaded successfully for variation \"$varia\" \n";
    }
}

1;
