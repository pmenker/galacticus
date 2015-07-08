#!/usr/bin/env perl
use strict;
use warnings;
my $galacticusPath;
if ( exists($ENV{"GALACTICUS_ROOT_V094"}) ) {
 $galacticusPath = $ENV{"GALACTICUS_ROOT_V094"};
 $galacticusPath .= "/" unless ( $galacticusPath =~ m/\/$/ );
} else {
 $galacticusPath = "./";
}
unshift(@INC,$galacticusPath."perl"); 
use Scalar::Util 'reftype';
use XML::LibXML qw(:libxml);
use XML::LibXML::PrettyPrint;
use Data::Dumper;
require Galacticus::Options;
require List::ExtraUtils;

# Update a Galacticus parameter file from one version to a later version.
# Andrew Benson (13-September-2014)

# Get arguments.
die("Usage: parametersMigrate.pl <inputFile> <outputFile> [options]")
    unless ( scalar(@ARGV) >= 2 );
my $inputFileName  = $ARGV[0];
my $outputFileName = $ARGV[1];
my %options =
    (
     inputVersion        => "0.9.3",
     outputVersion       => "0.9.4",
     validate            => "yes"  ,
     prettyify           => "no"   ,
     inputFormatVersion  => 1      ,
     outputFormatVersion => 2
    );
# Parse options.
my %optionsDefined = &Options::Parse_Options(\@ARGV,\%options);

# Define translations.
my @translations =
    (
      {
	 inputVersion  => "0.9.0",
	 outputVersion => "0.9.1",
 	 names         =>
	 {
 	     Omega_0 => "Omega_Matter",
	 },
	 values        =>
	 {
	     adafEnergyOption                      =>
	     {
		 "pure ADAF"                => "pureADAF"               ,
	     },
	     coolingFunctionMethods                =>
	     {
		 "atomic_CIE_Cloudy"        => "atomicCIECloudy"        ,
		 "CIE_from_file"            => "cieFromFile"            ,
	     },
	     coolingSpecificAngularMomentumMethod  => 
	     {
		 "constant rotation"        => "constantRotation"       ,
	     },
	     coolingTimeAvailableMethod            => 
	     {
		 "White-Frenk"              => "White-Frenk1991"        ,
	     },
	     coolingRateMethod                     => 
	     {
		 "White + Frenk"            => "White-Frenk1991"        ,
	     },
	     cosmologyMethod                       =>
	     {
		 "matter + lambda"          => "matter-lambda"          ,
	     },
	     criticalOverdensityMethod             =>
	     {
		 "spherical top hat"        => "sphericalTopHat"        ,
	     },
	     darkMatterConcentrationMethod         =>
	     {
		 "Gao 2008"                 => "Gao2008"                ,
	     },
	     hotHaloCoolingFromNode                =>
	     {
		 "current node"             => "currentNode"            ,
		 "formation node"           => "formationNode"
	     },
	     hotHaloDensityMethod                  =>
	     {
		 "cored isothermal"         => "coredIsothermal"
	     },
	     infallRadiusMethod                    =>
	     {
		 "cooling and freefall"     => "coolingAndFreefall"     ,
	     },
	     nodeMergersMethod                     => 
	     {
		 "single level hierarchy"   => "singleLevelHierarchy"   ,
	     },
	     powerSpectrumMethod                   => 
	     {
		 "power law"                => "powerLaw"               ,
	     },
	     satelliteMergingMethod                => 
	     {
		 "Lacey-Cole + Tormen"      => "Lacey-Cole+Tormen"      ,
	     },
	     starFormationHistoriesMethod          => 
	     {
		 "metallicity split"        => "metallicitySplit"       ,
	     },
	     starFormationHistoriesMethod          => 
	     {
		 "metallicity split"        => "metallicitySplit"       ,
	     },
	     starFormationFeedbackDisksMethod      => 
	     {
		 "power law"                => "powerLaw"               ,
	     },
	     starFormationFeedbackSpheroidsMethod  => 
	     {
		 "power law"                => "powerLaw"               ,
	     },
	     starFormationTimescaleDisksMethod     => 
	     {
		 "dynamical time"           => "dynamicalTime"          ,
	     },
	     starFormationTimescaleSpheroidsMethod => 
	     {
		 "dynamical time"           => "dynamicalTime"          ,
	     },
	     transferFunctionMethod                => 
	     {
		 "Eisenstein + Hu"          => "Eisenstein-Hu1999"      ,
	     },
	     treeBranchingMethod                   => 
	     {
		 "modified Press-Schechter" => "modifiedPress-Schechter",
	     },
	     virialDensityContrastMethod           =>
	     {
		 "spherical top hat"        => "sphericalTopHat"        ,
	     },
	 },
      },
      {
	 inputVersion  => "0.9.1",
	 outputVersion => "0.9.2",
 	 names         =>
	 {
 	     treeNodeMethodSatelliteOrbit                => "treeNodeMethodSatellite",
	 },
	 values        =>
	 {
 	     treeNodeMethodSatellite              =>
	     {
		 "simple"                    => "standard"
	     },
	     treeNodeMethodSpheroid               =>
	     {
		 "Hernquist"                 => {
		                                 value => "standard",
						 new   => [
						           {
							    name  => "spheroidMassDistribution",
							    value => "hernquist"
						           }
                                                          ]
		                                },
		 "sersic"                    => {
		                                 value => "standard",
						 new   => [
						           {
							    name  => "spheroidMassDistribution",
							    value => "sersic"
						           }
                                                          ]
		                                }
	     },
	 }
     },
     {
	 inputVersion  => "0.9.2",
	 outputVersion => "0.9.3",
	 names         =>
	 {
	     accretionHalosMethod                        => "accretionHaloMethod"                             ,
	     cosmologyMethod                             => "cosmologyFunctionsMethod"                        ,
	     darkMatterConcentrationMethod               => "darkMatterProfileConcentrationMethod"            ,
	     hotHaloCoredIsothermalCoreRadiiMethod       => "hotHaloColdModeCoredIsothermalCoreRadiiMethod"   ,
	     hotHaloDensityMethod                        => "hotHaloMassDistributionMethod"                   ,
	     ionizationStateFile                         => "chemicalStateFile"                               ,
	     isothermalCoreRadiusOverScaleRadius         => "hotHaloCoreRadiusOverScaleRadius"                ,
	     isothermalCoreRadiusOverVirialRadius        => "hotHaloCoreRadiusOverVirialRadius"               ,
	     isothermalCoreRadiusOverVirialRadiusMaximum => "hotHaloCoreRadiusOverVirialRadiusMaximum"        ,
	     mergerTreeBuildCole2000MassResolution       => "mergerTreeHaloMassResolution"                    ,
	     nfw96ConcentrationC                         => "nfw1996ConcentrationC"                           ,
	     satelliteMergingMethod                      => "satelliteMergingTimescalesMethod"                ,
	     treeNodeMethodFormationTimes                => "treeNodeMethodFormationTime"                     ,
	     luminosityFilterAbsoluteMagnitudeThresholds => "luminosityFilterAbsoluteMagnitudeThresholdMaxima"
	 },
	 values        =>
         {
	     cosmologyFunctionsMethod             =>
	     {
		 "matter-lambda"             => "matterLambda"                 ,
		 "matter-darkEnergy"         => "matterDarkEnergy"             ,
	     },
	     darkMatterProfileConcentrationMethod =>
	     {
		 "Gao2008"                   => "gao2008"                      ,
		 "Munoz-Cuartas2011"         => "munozCuartas2011"             ,
		 "Prada2011"                 => "prada2011"                    ,
		 "Zhao2009"                  => "zhao2009"
	     },
	     hotHaloMassDistributionMethod        =>
	     {
		 "coredIsothermal"           => "betaProfile"
	     },
	     satelliteMergingTimescalesMethod     => 
	     {
		 "BoylanKolchin2008"         => "boylanKolchin2008"            ,
		 "Jiang2008"                 => "jiang2008"                    ,
		 "Lacey-Cole"                => "laceyCole1993"                ,
		 "Lacey-Cole+Tormen"         => "laceyCole1993Tormen"          ,
		 "Wetzel-White2010"          => "wetzelWhite2010"
	     },
	     virialDensityContrastMethod          =>
	     {
		 "Bryan-Norman1998"          => "bryanNorman1998"              ,
		 "sphericalTopHatDarkEnergy" => "sphericalCollapseMatterDE"    ,
		 "sphericalTopHat"           => "sphericalCollapseMatterLambda",
		 "Kitayama-Suto1996"         => "kitayamaSuto1996"
	     },
	     virialOrbitsMethod                   =>
	     {
		 "Benson2005"                => "benson2005"                   ,
		 "Wetzel2010"                => "wetzel2010"
 
	     },
	 }
     },
     {
	 inputVersion  => "0.9.3",
	 outputVersion => "0.9.4",
	 names         =>
	 {
	     "mergerTreeBuildMethod"                             => "mergerTreeBuilderMethod"                                        ,
	     "darkMatterShapeMethod"                             => "darkMatterProfileShapeMethod"                                   ,
	     "H_0"                                               => "cosmologyParametersMethod->HubbleConstant"                      ,
	     "Omega_Matter"                                      => "cosmologyParametersMethod->OmegaMatter"                         ,
	     "Omega_DE"                                          => "cosmologyParametersMethod->OmegaDarkEnergy"                     ,
	     "Omega_b"                                           => "cosmologyParametersMethod->OmegaBaryon"                         ,
	     "T_CMB"                                             => "cosmologyParametersMethod->temperatureCMB"                      ,
	     "effectiveNumberNeutrinos"                          => "transferFunctionMethod->neutrinoNumberEffective"                ,
	     "summedNeutrinoMasses"                              => "transferFunctionMethod->neutrinoMassSummed"                     ,
	     "transferFunctionWDMFreeStreamingLength"            => "transferFunctionMethod->freeStreamingLength"                    ,
	     "transferFunctionWdmCutOffScale"                    => "transferFunctionMethod->scaleCutOff"                            ,
	     "transferFunctionWdmEpsilon"                        => "transferFunctionMethod->epsilon"                                ,
	     "transferFunctionWdmEta"                            => "transferFunctionMethod->eta"                                    ,
	     "transferFunctionWdmNu"                             => "transferFunctionMethod->nu"                                     ,
	     "stellarPopulationSpectraFileForceZeroMetallicity"  => "stellarPopulationSpectraMethod->forceZeroMetallicity"           ,
	     "stellarPopulationSpectraForChabrierIMF"            => "stellarPopulationSpectraMethod->fileNameForChabrierIMF"         ,
	     "stellarPopulationSpectraForBaugh2005TopHeavyIMF"   => "stellarPopulationSpectraMethod->fileNameForBaugh2005TopHeavyIMF",
	     "stellarPopulationSpectraForKroupaIMF"              => "stellarPopulationSpectraMethod->fileNameForKroupaIMF"           ,
	     "stellarPopulationSpectraForMiller-ScaloIMF"        => "stellarPopulationSpectraMethod->fileNameForMiller-ScaloIMF"     ,
	     "stellarPopulationSpectraForSalpeterIMF"            => "stellarPopulationSpectraMethod->fileNameForSalpeterIMF"         ,
	     "stellarPopulationSpectraForScaloIMF"               => "stellarPopulationSpectraMethod->fileNameForScaloIMF"            ,
	     "stellarPopulationSpectraForKennicuttIMF"           => "stellarPopulationSpectraMethod->fileNameForKennicuttIMF"        ,
	     "accretionDiskSpectraFileName"                      => "accretionDiskSpectraMethod->fileName"                           ,
	     "chemicalStateFile"                                 => "chemicalStateMethod->fileName"                                  ,
	     "coolingFunctionsMethod"                            => "coolingFunctionMethod"                                          ,
	     "powerSpectrumMethod"                               => "powerSpectrumPrimordialMethod"                                  ,
	     "powerSpectrumIndex"                                => "powerSpectrumPrimordialMethod->index"                           ,
	     "powerSpectrumRunning"                              => "powerSpectrumPrimordialMethod->running"                         ,
	     "powerSpectrumReferenceWavenumber"                  => "powerSpectrumPrimordialMethod->wavenumberReference"	     
	 },
 	 values        =>
         {
	     mergerTreeBuilderMethod        =>
	     {
		 "Cole2000"              => "cole2000"
	     },
	     treeNodeMethodDisk      =>
	     {
		 "exponential"       => {
		                         value => "standard",
		                         new   => [
					           {
			                            name  => "diskMassDistribution",
			                            value => "exponentialDisk"
			                           }
			                          ]
		                        }
	     },
	     darkMatterProfileShapeMethod   =>
	     {
		 "Gao2008"               => "gao2008"
	     },
	     transferFunctionMethod         =>
	     {
		 "null"                  => "identity"        ,
		 "Eisenstein-Hu1999"     => "eisensteinHu1999"
	     },
	     stellarPopulationSpectraMethod =>
	     {
	         "Conroy-White-Gunn2009" => "FSPS"
             }		     
	 }
    }
    );

# Define known defaults.
my %knownDefaults =
    (
     "cosmologyParametersMethod" => "simple"
    );

# Parse the input file.
my $parser     = XML::LibXML->new();
my $input      = $parser->parse_file($inputFileName);
my @parameterSets;
if ( $input->findnodes('parameters') ) {
    @parameterSets = $input->findnodes('parameters');
} elsif ( $input->findnodes('parameterGrid') ) {
    my $parameterGrid = $input->findnodes('parameterGrid')->[0];
    if ( $parameterGrid->findnodes('parameters') ) {
	@parameterSets = $parameterGrid->findnodes('parameters');
    } else {
	die('can not find parameters')
    }
} else {
    die('can not find parameters')
}

# Write starting message.
print "Translating file: ".$inputFileName."\n";

# Iterate over parameter sets.
foreach my $parameters ( @parameterSets ) {
    &Translate($parameters,1,$inputFileName);
}

# Output the resulting file.
my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");
$pp->pretty_print($input)
    if ( $options{'prettyify'} eq "yes" );
$input->toFile($outputFileName);

exit;

sub Translate {
    my $parameters    = shift();
    my $rootLevel     = shift();
    my $inputFileName = shift();

    # Set initial input/output versions.
    my $inputVersion  = $options{'inputVersion' };
    my $outputVersion = $options{'outputVersion'};

    # Check for a version element.
    my $version    = $parameters->findnodes('version')->[0];
    if ( defined($version) ) {
	$inputVersion = $version->textContent()
	    unless ( exists($optionsDefined{'inputVersion'}) );
	$version->firstChild()->setData("0.9.4");
    } elsif ( $rootLevel ) {
	my $versionNode = $input->createElement ("version");
	my $newVersion  = $input->createTextNode("0.9.4"  );
	my $newBreak    = $input->createTextNode("\n  "   );
	$versionNode->addChild($newVersion);
	$parameters->insertBefore($versionNode,$parameters->firstChild());
	$parameters->insertBefore($newBreak   ,$parameters->firstChild());
    }
    
    # Determine output format version.
    unless ( exists($options{'outputFormatVersion'}) ) {
	$options{'outputFormatVersion'} = 1;
	my @outputVersionSubstrings = split(/\./,$outputVersion);
	$options{'outputFormatVersion'} = 2
	    if (
		$outputVersionSubstrings[0] >  0
		||
		(
		 $outputVersionSubstrings[0] == 0
		 &&    
		 $outputVersionSubstrings[1] >  9
		)
		||
		(
		 $outputVersionSubstrings[0] == 0
		 &&    
		 $outputVersionSubstrings[1] == 9
		 &&    
		 $outputVersionSubstrings[2] >  3
		)
	    );
    }
    
    # Check for a format version element.
    my $formatVersion = $parameters->findnodes('formatVersion')->[0];
    if ( defined($formatVersion) ) {
	$options{'inputFormatVersion'} = $formatVersion->textContent();
	$formatVersion->firstChild()->setData($options{'outputFormatVersion'});
    } elsif ( $rootLevel ) {
	my $formatVersionNode = $input->createElement ("formatVersion"                );
	my $newFormatVersion  = $input->createTextNode($options{'outputFormatVersion'});
	my $newBreak          = $input->createTextNode("\n  "                         );
	$formatVersionNode->addChild($newFormatVersion);
	$parameters->insertBefore($formatVersionNode,$parameters->firstChild());
	$parameters->insertBefore($newBreak         ,$parameters->firstChild());
    }

    # Validate the parameter file.
    if ( $options{'validate'} eq "yes" ) {
	system($galacticusPath."scripts/aux/validateParameters.pl ".$inputFileName);
	die('input file "'.$inputFileName.'"is not a valid Galacticus parameter file')
	    unless ( $? == 0 );
    }
    
    # Iterate over translations.
    foreach my $translation ( @translations ) {
	# Skip irrelevant translation.
	next
	    unless ( $translation->{'inputVersion'} eq $inputVersion );
	# Report.
	print "Translating from v".$translation->{'inputVersion'}." to v".$translation->{'outputVersion'}."\n";
	$inputVersion = $translation->{'outputVersion'};
	# Find parameter nodes.
	my @parameterNodes;
	if ( $options{'inputFormatVersion'} <= 1 ) {
	    @parameterNodes = $parameters->findnodes('parameter');
	} else {
	    @parameterNodes = map {($_->exists('value') || $_->hasAttribute('value') ) ? $_ : ()} $parameters->findnodes('*');
	}
	# Apply translations.
	for my $parameter ( @parameterNodes ) {
	    # Get name and value text elements.
	    my $name;
	    my $nameText;
	    my @allValues;
	    if ( $options{'inputFormatVersion'} <= 1 ) {
		$name      = $parameter->findnodes('name' )->[0]->firstChild();
		$nameText  = $name->textContent();
		@allValues = $parameter->findnodes('value');
	    } else {
		$name     = $parameter;
		$nameText = $name->nodeName();
		if ( $parameter->exists('value') ) {
		    @allValues = $parameter->findnodes('value');
		} else {
		    @allValues = $parameter;
		}
	    }
	    # Translate names.
	    if ( exists($translation->{'names'}->{$nameText}) ) {
		print "   translate parameter name: ".$nameText." --> ".$translation->{'names'}->{$nameText}."\n";
		if ( $options{'inputFormatVersion'} <= 1 ) {
		    $name->setData    ($translation->{'names'}->{$nameText});
		} else {
		    $name->setNodeName($translation->{'names'}->{$nameText});
		}
	    }
	    # Translate values.
	    foreach my $value ( @allValues ) {
		if ( exists($translation->{'values'}->{$nameText}) ) {
		    # Split values.
		    my $valuesText;
		    if ( $value->isSameNode($name) ) {
			$valuesText = $value->getAttribute('value');
		    } else {
			$valuesText = $value->firstChild()->textContent();
		    }
		    $valuesText =~ s/^\s*//;
		    $valuesText =~ s/\s*$//;
		    my @values;
		    if ( $translation->{'inputVersion'} eq "0.9.0" ) {
			# For v0.9.0, we cannot split as method names were permitted to contain spaces.
			push(@values,$valuesText);
		    } else {
			@values = split(/\s+/,$valuesText);
		    }
		    foreach my $thisValue ( @values ) {
			if ( exists($translation->{'values'}->{$nameText}->{$thisValue}) ) {
			    print "   translate parameter value: ".$nameText."\n";
			    if ( ref($translation->{'values'}->{$nameText}->{$thisValue}) ) {
				my $newValue = $translation->{'values'}->{$nameText}->{$thisValue};
				print "                                 ".$thisValue." --> ".$newValue->{'value'}."\n";
				$thisValue = $newValue->{'value'};
				if ( exists($newValue->{'new'}) ) {
				    foreach my $newParameter ( &ExtraUtils::as_array($newValue->{'new'}) ) {
					print "      add parameter: ".$newParameter->{'name'}." = ".$newParameter->{'value'}."\n";
					if ( $options{'inputFormatVersion'} <= 1 ) {
					    my $parameterNode = $input->createElement (                "parameter" );
					    my $name          = $input->createElement (                "name"      );
					    my $value         = $input->createElement (                "value"     );
					    my $nameText      = $input->createTextNode($newParameter->{'name'     });
					    my $valueText     = $input->createTextNode($newParameter->{'value'    });
					    $name ->addChild($nameText );
					    $value->addChild($valueText);
					    $parameterNode->addChild($input->createTextNode("\n    "));
					    $parameterNode->addChild($name  );
					    $parameterNode->addChild($input->createTextNode("\n    "));
					    $parameterNode->addChild($value );
					    $parameterNode->addChild($input->createTextNode("\n  "));
					    $parameters->insertAfter($parameterNode,$parameter);
					    $parameters->insertAfter($input->createTextNode("\n  "),$parameter);
					} else {
					    my $parameterNode = $input->createElement($newParameter->{'name'});
					    $parameterNode->setAttribute('value',$newParameter->{'value'});
					    $parameters->insertAfter($parameterNode,$parameter);
					    $parameters->insertAfter($input->createTextNode("\n  "),$parameter);
					}
				    }
				}
			    } else {
				print "                                 ".$thisValue." --> ".$translation->{'values'}->{$nameText}->{$thisValue}."\n";
				$thisValue = $translation->{'values'}->{$nameText}->{$thisValue};
			    }
			}
			if ( $value->isSameNode($name) ) {
			    $value->setAttribute('value',join(" ",@values));
			} else {
			    $value->firstChild()->setData(join(" ",@values));
			}
		    }
		}
	    }
	}
	# Finished if output version is reached.
	last
	    if ( $outputVersion eq $inputVersion );
    }
    
    # Handle transition from old to new.
    if ( $options{'outputFormatVersion'} >= 2 && $options{'inputFormatVersion'} < 2) {
	print "Converting to new format (v2)...\n";
	for my $parameter ( $parameters->findnodes('parameter') ) {
	    # Get name and value text elements.
	    my $name   = $parameter->findnodes('name' )->[0]->firstChild();
	    my @values = $parameter->findnodes('value');
	    # Create the new node.
	    my $parameterNode = $input->createElement($name->textContent());
	    # Determine if we can use a value attribute or not.
	    my $useAttribute = 1;
	    $useAttribute = 0
		if ( scalar(@values) > 1 );
	    foreach my $valueNode ( @values ) {
		$useAttribute = 0
		    if ( $valueNode->findnodes('*') );
	    }
	    # Add values.
	    foreach my $valueNode ( @values ) {
		my $value  = $valueNode->firstChild();
		# Find any subparameters.
		my @subParameters = $valueNode->findnodes('*');
		if ( $useAttribute ) {
		    $parameterNode->setAttribute('value',$value->textContent());
		} else {
		    &Translate($valueNode,0,$inputFileName)
			if ( @subParameters );
		    $parameterNode->addChild($input->createTextNode("\n"));
		    $parameterNode->addChild($valueNode);
		}
	    }
	    $parameterNode->addChild($input->createTextNode("\n"))
		unless ( $useAttribute );
	    # Insert the new node.
	    $parameters->insertAfter($parameterNode,$parameter);
	    # Remove the old parameter.
	    $parameters->removeChild($parameter);
	}
	for my $parameter ( $parameters->getChildrenByTagName("*") ) {
	    if ( $parameter->nodeName() =~ m/(.+)\-\>(.+)/ ) {
		my $hostName = $1;
		my $subName  = $2;
		$parameters->removeChild($parameter->nextSibling());
		my $sibling = $parameter->nextSibling();
		my $hostFound;
		$parameter->setNodeName($subName);
		for my $hostParameter ( $parameters->getChildrenByTagName("*") ) {
		    if ( $hostParameter->nodeName() eq $hostName ) {
			$hostParameter->addChild($input     ->createTextNode("  "      ));
			$hostParameter->addChild($parameters->removeChild   ($parameter));
			$hostParameter->addChild($input     ->createTextNode("\n  "    ));
			$hostFound = 1;
		    }
		}
		unless ( $hostFound ) {
		    # Create the new node.
		    die('parametersMigrate.pl: attempting to insert a "'.$hostName.'" element, but no default value is known')
			unless ( exists($knownDefaults{$hostName}) );
		    my $parameterNode = $input->createElement($hostName);
		    $parameterNode->setAttribute('value',$knownDefaults{$hostName});
		    $parameterNode->addChild($input     ->createTextNode("\n    "  ));
		    $parameterNode->addChild($parameters->removeChild   ($parameter));
		    $parameterNode->addChild($input     ->createTextNode("\n  "    ));
		    $parameters->insertBefore($parameterNode,$sibling);
		}
	    }
	}
    }
}
