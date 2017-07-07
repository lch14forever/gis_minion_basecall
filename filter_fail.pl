#!/usr/bin/perl
use warnings "all";
use Switch;

#This script filters failed reads that have been extracted. Only '2D_2d' should be obtained. For those without '2d reads', get '2D_template' - if this does not exist get '2D_complement'.

my ($contig_file) = @ARGV;
my $nb_contig = 0;
my %contig_name = ();

$command = "sed -e 's/Basecall_2D/Basecall_2D_2d/g' -e 's/1D_template/2D_atemplate/g' -e 's/1D_complement/2D_complement/g'  $contig_file > ${contig_file}_tmp";
`$command`;

#To obtain last common column
#$command = "awk -F'_' '{for(i=1;i<=NF;i++){if (\$i ~ /2D/){print i}}}' ${contig_file}_tmp | uniq";
$command = " head -n 100 ${contig_file}_tmp | awk -F'_' '{for(i=1;i<=NF;i++){if (\$i ~ /template|complement/){print i-1}}}'  | uniq";
my @column=`$command`;
chomp @column;
print STDERR $column[0]."\n";

#To obtain 2D_2d only. For those without 2d reads, get 2D_template - if this does not exist get 2D_complement.
$command = "grep '>' ${contig_file}_tmp | sort | sort -u -t_ -k 1,${column[0]} > ${contig_file}_tmp2";
`$command`;
print STDERR $command."\n";

$command = "sed -i -e 's/2D_atemplate/1D_template/g' -e 's/2D_complement/1D_complement/g' -e 's/Basecall_2D_2d/Basecall_2D/g'  ${contig_file}_tmp2";
`$command`;

print STDERR "\n***Contig name file\n";
open(IN, "${contig_file}_tmp2");
while(<IN>){

    chop $_;
    $contig_name{$_} = 1;
}
close(IN);


print STDERR "\n***Read contig file\n";
$nb_contig = 0;
open(IN, $contig_file);
my $print_flag = 0;

while(<IN>){

    if(index($_, ">") == -1){
        print $_ if($print_flag);
    }
    else{

        print STDERR "---> $nb_contig\n" if($nb_contig % 500000 == 0);$nb_contig++;

        chomp($_);
        if(exists $contig_name{$_}){
            $print_flag = 1;
            print $_."\n";
        }
        else{
            $print_flag = 0;
        }
    }
}

$command = "rm ${contig_file}_tmp*";
`$command`;

