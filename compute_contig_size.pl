#!/usr/bin/perl
use warnings "all";

my ($contig_file) = @ARGV;

open(IN, "$contig_file");

#my $size_threshold = 200;
my $max_contig = -1;
my $comp = 0;
my $n = 0;

my $contig_name = "";
my $contig_size = 0;
while(<IN>){
    last if($comp == $max_contig);
    
    chomp $_;
    
    if($_ ne ""){

	if(index($_, ">") != -1){
	    print $contig_name."\t".$contig_size."\n" if($contig_size != 0);
	    
	    $contig_name = $_;

	    #print STDERR $contig_name."\n";<STDIN>;

	    $contig_size = 0;
	    #<STDIN>;
	    #print STDERR "\n".$contig_seq;
	}
	else{
	    $contig_size += length($_); 
	}
    }
}

#The last contig
print $contig_name."\t".$contig_size."\n";
