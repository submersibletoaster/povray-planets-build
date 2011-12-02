#!/usr/bin/perl
use strict;
use warnings;
use Text::CSV;
use File::Temp;
use Digest::JHash 'jhash';
use Data::Dumper;

my $max = 1 << 31;
$max*=2;
my $n_planets = 8 * 256;

my $galaxy_csv = shift @ARGV;
my $render = shift @ARGV;


my $POV_template = <<POV;
#version unofficial megapov 1.21;
#include "cm_camera.inc"
#include "pp_textures.inc"
#include "pp_continental.inc"
#include "pp_gas.inc"

#debug  "%s" 

#declare Radius = 1;

sphere { <0,0,0> Radius
        hollow no_shadow inverse double_illuminate
                %s(
                        %d,  // colour
                        %d,  // pattern
                        %d,  // galaxy X
                        %d,  // galaxy Y
                        %f // float modifier 1
                        %f // float modifier 2
                )
}


CubeMapBoxes(Radius)
//CubeLight(4,Radius)
CubeMapCamera()




POV


my $csv = Text::CSV->new;
open( my $fh , $galaxy_csv ) or die $!;
my $headings = $csv->getline($fh);
#die Dumper $headings;

while ( my $row = $csv->getline($fh) ) {
        my %info;
        @info{@$headings} = @$row;
        
        my $seed = jhash $info{Name};
        my $seed2= jhash scalar reverse $info{Name};
        my $norm_seed = $seed/$max; # normalised to 0..1
        my $norm_seed2= $seed2/$max; 
        my $galaxy_X = $info{X};
        $galaxy_X =~ s/[^\d]//g;
        my $galaxy_Y = $info{Y};
        $galaxy_Y =~ s/[^\d]//g;
        my $planet_type = $seed % $n_planets+1;
        my $planet_specifier = $seed % int(sqrt($n_planets+1));

        # Barren/rocky , Gas Giant , Continental , Artificial
        my $formation_seed = $seed % 11;
        my %formations = (
                0 => 'Gas' ,               
                1 => 'Rocky',
                2 => 'Continental',

                3 => 'Gas' , 
                4 => 'Rocky',
                5 => 'Continental',

                6 => 'Gas' ,                
                7 => 'Rocky',
                8 => 'Continental',

                9 => 'Gas' ,                
                10=> 'Rocky',
                11=> 'Continental',
               # 2 => 'Continental',
               # 3 => 'Artificial'
        );

        # Choose a colour map as $Formation + $colour_seed
        my $colour_seed = $seed2 % 8;

        # Choose a pattern based on 
        my $pattern_seed= $seed % 4;

        my $macro = $formations{$formation_seed};


        
        my $pov_sdl = sprintf $POV_template, $info{Name},
                $macro, 
                $colour_seed, $pattern_seed,
                $galaxy_X, $galaxy_Y,
                $norm_seed, $norm_seed2;
        
        #my $tf = File::Temp->new;
        #$tf->print( $pov_sdl );
        #$tf->close;
        my $sdl_file = 'SDL/' . $info{Name} . '.pov';
        open( my $sdl_fh , '>' , $sdl_file ) or die $!;
        $sdl_fh->print( $pov_sdl );
        $sdl_fh->close;
        
        
        if ( defined $render ) {
                my $output = 'Textures/'. $info{Name}.'.png';
                next if -f $output;
                my $rc = system(
                        'megapov',
                        '+Lcm',
                        '-D',
                        # '+W256', '+H1536', # medium resolution
                        '+W128','+H768', # low resolution
                        #'+W512' , '+H512' , # Perspective preview
                        '+O'.$output,
                        '+I'.$sdl_file,
                );
                die $! unless $rc==0;
                die $pov_sdl unless -f $output;
        }
        
        else { print $pov_sdl }
        
}
