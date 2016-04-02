#!/usr/bin/env perl
use strict;
use warnings;
my $galacticusPath;
if ( exists($ENV{"GALACTICUS_ROOT_V094"}) ) {
 $galacticusPath  = $ENV{"GALACTICUS_ROOT_V094"};
 $galacticusPath .= "/" unless ( $galacticusPath =~ m/\/$/ );
} else {
 $galacticusPath  = "./";
}
unshift(@INC,$galacticusPath."perl"); 
use PDL;
use PDL::NiceSlice;
use PDL::IO::HDF5;
use Data::Dumper;
require Galacticus::Options;
require Galacticus::Constraints::MassFunctions;
require Galacticus::StellarMass;

# Compute likelihood (and make a plot) for a Galacticus model given the HI mass function data from Martin et al. (2010;
# http://adsabs.harvard.edu/abs/2010ApJ...723.1359M),

# Data structure to hold the specification for our mass function.
my $massFunctionConfig;

# Get name of input and output files.
die("hiMassFunction_ALFALFA_z0.0.pl <galacticusFile> [options]") unless ( scalar(@ARGV) >= 1 );
$massFunctionConfig->{'self'          } = $0;
$massFunctionConfig->{'galacticusFile'} = $ARGV[0];
# Create a hash of named arguments.
my $iArg = -1;
my %arguments =
    (
     quiet => 0
    );
&Options::Parse_Options(\@ARGV,\%arguments);

# Specify the properties of this mass function.
my $entry                                    = 0;
$massFunctionConfig->{'redshift'           } = pdl 0.000;
$massFunctionConfig->{'analysisLabel'      } = "alfalfaHiMassFunctionZ0.00";
$massFunctionConfig->{'discrepancyFileName'} = "discrepancy".ucfirst($massFunctionConfig->{'analysisLabel'}).".hdf5";
$massFunctionConfig->{'massType'           } = "massColdGas";
$massFunctionConfig->{'massMap'            } = \&ALFALFA_Mass_Map;
$massFunctionConfig->{'massErrorRandomDex' } = \&ALFALFA_Mass_Error_Model;
$massFunctionConfig->{'xRange'             } = "1.0e6:3.0e11";
$massFunctionConfig->{'yRange'             } = "1.0e-6:1.0e0";
$massFunctionConfig->{'xLabel'             } = "\$M_{\\rm HI}\$ [\$M_\\odot\$]";
$massFunctionConfig->{'yLabel'             } = "\${\\rm d}n/{\\rm d}\\log M_{\\rm HI}\$ [Mpc\$^{-3}\$]";
$massFunctionConfig->{'title'              } = "HI mass function at \$z\\approx 0.00\$";

# Read the observed data.
my $observations                                        = new PDL::IO::HDF5($galacticusPath."data/observations/massFunctionsHI/HI_Mass_Function_ALFALFA_2010.hdf5");
$massFunctionConfig ->{'x'                           }  = $observations->dataset('mass'                )->get    (                  );
$massFunctionConfig ->{'y'                           }  = $observations->dataset('massFunctionObserved')->get    (                  );
$massFunctionConfig ->{'yIsPer'                      }  = "ln";
$massFunctionConfig ->{'xScaling'                    }  = "linear";
$massFunctionConfig ->{'yScaling'                    }  = "linear";
$massFunctionConfig ->{'covariance'                  }  = $observations->dataset('covariance'          )->get    (                  );
$massFunctionConfig ->{'errorModel'                  }  = "logNormal"                                                                ;
($massFunctionConfig->{'observationLabel'            }) = $observations                                 ->attrGet('label'           );
($massFunctionConfig->{'hubbleConstantObserved'      }) = $observations->group  ('Parameters'          )->attrGet('H_0'             );
($massFunctionConfig->{'omegaMatterObserved'         }) = $observations->group  ('Parameters'          )->attrGet('Omega_Matter'    );
($massFunctionConfig->{'omegaDarkEnergyObserved'     }) = $observations->group  ('Parameters'          )->attrGet('Omega_DE'        );
($massFunctionConfig->{'cosmologyScalingMass'        }) = $observations->dataset('mass'                )->attrGet('cosmologyScaling');
($massFunctionConfig->{'cosmologyScalingMassFunction'}) = $observations->dataset('massFunction'        )->attrGet('cosmologyScaling');

# Construct the mass function.
&MassFunctions::Construct(\%arguments,$massFunctionConfig);

exit;

sub ALFALFA_Mass_Error_Model {
    # Return the error on log10(mass) for the ALFALFA 40% survey.
    my $logarithmicMass = shift;
    my $galacticus      = shift;
    # Use a simple model fit to Fig. 19 of Haynes et al. (2011).
    # See constraints/dataAnalysis/hiMassFunction_ALFALFA_z0.00/alfalfaHIMassErrorModel.pl for details.
    my $a                                  = pdl $galacticus->{'parameters'}->{'alfalfaHiMassFunctionZ0.00ErrorA'}->{'value'};
    my $b                                  = pdl $galacticus->{'parameters'}->{'alfalfaHiMassFunctionZ0.00ErrorB'}->{'value'};
    my $c                                  = pdl $galacticus->{'parameters'}->{'alfalfaHiMassFunctionZ0.00ErrorC'}->{'value'};
    my $logarithmicMassLimited             = $logarithmicMass->copy();
    my $lowMasses                          = which($logarithmicMassLimited < 6.0);
    $logarithmicMassLimited->($lowMasses) .= 6.0;
    my $errorObserved                      = $a+exp(-($logarithmicMassLimited-$b)/$c);
    my $errorModel                         = $galacticus->{'parameters'}->{'alfalfaHiMassFunctionZ0.00MolecularFractionScatter'}->{'value'};
    my $error                              = sqrt($errorObserved**2+$errorModel**2);
    return $error;
}

sub ALFALFA_Mass_Map {
    # Compute logarithmic HI mass for the ALFALFA 40% survey.
    my $config                                  = shift;
    my $galacticus                              = shift;
    my $hydrogenFractionByMassPrimordial        = pdl 0.778;
    my $megaParsec = pdl 3.086e22;
    my $massSolar = pdl 1.99e30;
    &HDF5::Get_Dataset($galacticus,['diskRadius','massStellar','nodeIndex']);
    # Compute central molecular ratio.
    my $molecularRatioCentral = 
	(
	 $massSolar  **2
	 /$megaParsec**4
	 *$galacticus->{'parameters'}->{'alfalfaHiMassFunctionZ0.00MolecularFractionK'}->{'value'}
	 *$galacticus->{'dataSets'  }->{$config->{'massType'}                         }                       
	 *(
	     +$galacticus->{'dataSets'  }->{$config->{'massType'}                              }
	     +$galacticus->{'parameters'}->{'alfalfaHiMassFunctionZ0.00MolecularFractionfSigma'}->{'value'}
	     *$galacticus->{'dataSets'  }->{'massStellar'                                      }
	 )
	 /$galacticus->{'dataSets'}->{'diskRadius'}**4
	)**$galacticus->{'parameters'}->{'alfalfaHiMassFunctionZ0.00MolecularFractionBeta'}->{'value'};
    # Compute net molecular ratio.
    my $molecularRatio = 
	1.0
	/(
	    +                        $galacticus->{'parameters'}->{'alfalfaHiMassFunctionZ0.00MolecularFractionA1'    }->{'value'}
	    /$molecularRatioCentral**$galacticus->{'parameters'}->{'alfalfaHiMassFunctionZ0.00MolecularFractionAlpha1'}->{'value'}
	    +                        $galacticus->{'parameters'}->{'alfalfaHiMassFunctionZ0.00MolecularFractionA2'    }->{'value'}
            /$molecularRatioCentral**$galacticus->{'parameters'}->{'alfalfaHiMassFunctionZ0.00MolecularFractionAlpha2'}->{'value'}
	);
    my $negativeMolecularRatio                  = which($molecularRatio < 0.0);
    $molecularRatio->($negativeMolecularRatio) .= 0.0;
    my $logarithmicMass                         = log10($hydrogenFractionByMassPrimordial*$galacticus->{'dataSets'}->{$config->{'massType'}}/(1.0+$molecularRatio));
    my $zeroMasses                              = which($galacticus->{'dataSets'}->{$config->{'massType'}} <= 0.0);
    $logarithmicMass->($zeroMasses)            .= -100.0;
    return $logarithmicMass;
}
