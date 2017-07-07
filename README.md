# Minion basecalling on GIS's HPC environment

Usage (call bases for direct RNA-Seq)
```
/mnt/projects/rpd/apps.testing/miniconda3/envs/snakemake-3.7.1/bin/snakemake --latency-wait 150 -p -T --snakefile Snakefile -j 40 --drmaa ' -pe OpenMP {threads} -l {params.resource} -V -b y -cwd -w n' --config LIBRARY=folder CHEMISTRY=r94_70bps_rna_linear.cfg
```
