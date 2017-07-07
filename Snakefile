# shell environment used for each job
# note, this is a naked shell, not aware of your bashrc!
shell.executable("/bin/bash")
# unofficial bash strict mode
shell.prefix("set -euo pipefail;")# don't forget trailing semicolon

import os
import glob
import re

##assert 'LIBRARY' in config
##assert 'PARAMS' in config

########### tools & data: ########
## Default tools
FILTER         = srcdir('filter_fail.pl')
SCAFFOLD_STATS = srcdir('scaffold_stats_opt.pl')
CONTIG_SIZE    = srcdir('compute_contig_size.pl')
HISTOGRAM      = srcdir('histogram.R')

lib = config['LIBRARY']
if not 'PREFIX' in config:
    lib_basename = os.path.basename(lib.strip('/'))
else:
    lib_basename = config['PREFIX']

if not 'CHEMISTRY' in config:
    chemistry = 'r94_250bps_2d.cfg'
    sys.stderr.write("Warning: No chemistry specified -- using default `r94_250bps_2d.cfg` (R9.4 2D)\n")
else:    
    chemistry = config['CHEMISTRY'] 

chunks = [os.path.basename(f) for f in glob.glob(lib + '/[0-9]*')]
chunks = [ i for i in chunks if i.isdigit() ]

assert len(chunks) >0
#################################


# def get_dir_for_prefix(wildcards):
#         return config['SAMPLES'][wildcards.prefix]

rule final:
    input:
        lib_basename + "_basecalled_fast5.tar.gz", lib_basename+".prefilter.fasta.gz"

         
rule base_call:
    input:  lib+"/{folder}"
    output: "{folder}.basecalled"
    threads: 12
    params: resource="h_rt=48:00:00,mem_free=20G "
    shell:
        """
        set +u
        source activate nanopore_py3
        set -u
        read_fast5_basecaller.py -i {input} -t {threads} -s {output}  -c {chemistry} -n 0 -o fast5 
        source deactivate
        """

rule poretools_fasta:
    input:   "{folder}.basecalled"
    output:
        fasta = "{folder}.basecalled/sequences.fasta",
    threads: 1
    params: resource="h_rt=48:00:00,mem_free=3G -q ionode.q "
    shell:
        """
        set +u
        source activate nanopore
        set -u
        poretools fasta --type all {input}/workspace/*fast5 > {output.fasta}
        source deactivate
        """
        
rule poretools_fastq:
    input:
        folder ="{folder}.basecalled",
        dummy  ="{folder}.basecalled/sequences.filtered.fasta"  ## pseudo input to execute this after
    output:
        fastq = "{folder}.basecalled/sequences.fastq"
    threads: 1
    params: resource="h_rt=48:00:00,mem_free=3G -q ionode.q "
    shell:
        """
        set +u
        source activate nanopore
        set -u
        poretools fastq --type all {input.folder}/workspace/*fast5 > {output.fastq}
        source deactivate
        """

rule filter_fasta:
    input:   "{folder}.basecalled/sequences.fasta"
    output:  "{folder}.basecalled/sequences.filtered.fasta"         ## later set to temp
    threads: 1
    params: resource="h_rt=48:00:00,mem_free=5G -q ionode.q"
    shell:
        """
        {FILTER}  {input} > {output} 
        """


rule merge_files:
    input:
        folder    =expand("{folder}.basecalled", folder=chunks),
        filtered  =expand("{folder}.basecalled/sequences.filtered.fasta", folder=chunks),
        fastq     =expand("{folder}.basecalled/sequences.fastq", folder=chunks)
    output:
        fasta     =lib_basename+".filtered.fasta",
        fastq     =lib_basename+".prefilter.fastq.gz",
        summary   =lib_basename+".sequencing_summary.txt.gz",
        log       =lib_basename+".pipeline.log.gz",
        config    =lib_basename+".configuration.cfg.gz"
    threads: 1
    params: resource="h_rt=48:00:00,mem_free=5G -q ionode.q "
    shell:
        "find {input.folder} -name 'sequencing_summary.txt' -maxdepth 1 -exec cat {{}} \; | grep -v '^filename'|cat <(head -n1 0.basecalled/sequencing_summary.txt) - | gzip - > {output.summary};"
        "find {input.folder} -name 'pipeline.log' -maxdepth 1 -exec cat {{}} \; | gzip - > {output.log};"
        "cat {input.fastq} | gzip -  > {output.fastq};"
        "gzip -c 0.basecalled/configuration.cfg  > {output.config};"
        "cat {input.filtered}  > {output.fasta}"

rule qc_analysis:
    input:
        lib_basename+".filtered.fasta"  
    output:
        stats   =lib_basename+".stats",
        size    =lib_basename+".size",
        plot    =lib_basename+".hist.pdf"
    threads: 1
    params: resource="h_rt=48:00:00,mem_free=5G"
    shell:
        "perl {SCAFFOLD_STATS} {input} 1 1 > {output.stats};"
        "perl {CONTIG_SIZE} {input} > {output.size};"
        "max=`grep Max {output.stats} | uniq | awk '{{print $NF}}'`;"
        "Rscript {HISTOGRAM} "
        "  {output.size}  " + lib_basename + "_Nanopore " 
        "  {output.plot} "
        "  $max "
        "  1 "
        "  $max ;"

rule compress:
    input:
        prefilter =expand("{folder}.basecalled/sequences.fasta", folder=chunks),
        folder    =expand("{folder}.basecalled", folder=chunks),
        fasta =lib_basename+".filtered.fasta", 
        size  =lib_basename+".stats", 
        stats =lib_basename+".size"
        #prefilter =lib+"/"+lib_basename+".prefilter.fasta.gz",
    output:
        basecalled = lib_basename + "_basecalled_fast5.tar.gz",
        merged_fasta = lib_basename+".prefilter.fasta.gz"

    threads: 1
    params: resource="h_rt=48:00:00,mem_free=5G -q ionode.q"
    shell:
        ##"mkdir -p "+lib_basename+".basecalled.fast5/ ; find {input.folder} -name '*fast5' -exec mv -t "+lib_basename+".basecalled.fast5/ {{}} +;"
        "gzip {input.fasta} {input.size} {input.stats};"
        "cat {input.prefilter} | gzip - > {output.merged_fasta}; "
        "find {input.folder} -type f -maxdepth 1 -exec rm -f {{}} \;;"
        "tar -czf {output.basecalled} {input.folder} --remove-files; "
