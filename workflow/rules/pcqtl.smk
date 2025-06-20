rule calculate_pcs:
    input:
        clusters = clusters_dir + '{TISSUE}_clusters_all_chr.csv',
        filtered_normed_expression = filtered_expression_output_dir + '{TISSUE}.v8.normalized_residualized_expression.cluster_genes.bed',
        covariates = covariates_dir + '{TISSUE}.v8.covariates.txt'
    conda:
        'tensorqtl_r'
    output:
        pc_output_dir + '{TISSUE}.pcs.bed'
    shell:
        """
        python workflow/scripts/get_pcs.py \
                -cl {input.clusters} \
                -e {input.filtered_normed_expression} \
                -co {input.covariates} \
                -o {output} 
        """


# PCQTLS

# cis-QTL mapping: summary statistics for all variant-phenotype pairs
rule run_pcqtl_cis_nominal:
    input:
        genotypes = genotype_stem + '.fam',
        pcs = pc_output_dir + '{TISSUE}.pcs.bed',
        covariates = covariates_dir + '{TISSUE}.v8.covariates.txt'
    params:
        genotype_stem = genotype_stem,
        pcqtl_output_dir = pcqtl_output_dir,
        tissue='{TISSUE}'
    resources:
        mem = "30G",
        time = "4:00:00"
    threads: 10
    conda:
        'tensorqtl_r'
    output:
        expand(pcqtl_output_dir + '{TISSUE}/{TISSUE}.v8.pcs.cis_qtl_pairs.{CHROM}.parquet', CHROM=chr_list,  allow_missing=True)
    script:
        '../scripts/snakemake_run_pcqtl_nominal.py'

# cis eQTL mapping: permutations (i.e. top variant per phenotype group)
rule run_pcqtl_cis:
    input:
        genotypes = genotype_stem + '.fam',
        pcs = pc_output_dir + '{TISSUE}.pcs.bed',
        covariates = covariates_dir + '{TISSUE}.v8.covariates.txt'
    params:
        genotype_stem = genotype_stem,
        pcqtl_output_dir = pcqtl_output_dir
    resources:
        mem = "30G",
        time = "4:00:00"
    threads: 10
    conda:
        'tensorqtl_r'
    output:
        pcqtl_output_dir + '{TISSUE}/{TISSUE}.v8.pcs.cis_qtl.txt.gz'
    shell:"""
        python -m tensorqtl {params.genotype_stem} \
            {input.pcs} \
            {params.pcqtl_output_dir}{wildcards.TISSUE}/{wildcards.TISSUE}.v8.pcs \
            --covariates {input.covariates} \
            --mode cis
        """

# cis-QTL mapping: conditionally independent QTLs
# This mode maps conditionally independent cis-QTLs using the stepwise regression procedure described in GTEx Consortium, 2017. 
# The output from the permutation step (see map_cis above) is required. 


rule run_pcqtl_cis_independent:
    input:
        genotypes = genotype_stem + '.fam',
        pcs = pc_output_dir + '{TISSUE}.pcs.bed',
        covariates = covariates_dir + '{TISSUE}.v8.covariates.txt',
        cis_results = pcqtl_output_dir + '{TISSUE}/{TISSUE}.v8.pcs.cis_qtl.txt.gz'
    params:
        genotype_stem = genotype_stem,
        tissue = '{TISSUE}',
        use_pc1_only = False
    resources:
        mem = "60G",
        time = "6:00:00"
    threads: 20
    conda:
        'tensorqtl_r'
    output:
        pcqtl_output_dir + '{TISSUE}/{TISSUE}.v8.pcs.cis_independent_qtl.txt.gz'
    script:
        '../scripts/snakemake_run_qtl_permutations.py'


rule run_pcqtl_cis_independent_pc1:
    input:
        genotypes = genotype_stem + '.fam',
        pcs = pc_output_dir + '{TISSUE}.pcs.bed',
        covariates = covariates_dir + '{TISSUE}.v8.covariates.txt',
        cis_results = pcqtl_output_dir + '{TISSUE}/{TISSUE}.v8.pcs.cis_qtl.txt.gz'
    params:
        genotype_stem = genotype_stem,
        tissue = '{TISSUE}',
        use_pc1_only = True
    resources:
        mem = "60G",
        time = "6:00:00"
    threads: 20
    conda:
        'tensorqtl_r'
    output:
        pcqtl_output_dir + '{TISSUE}/{TISSUE}.v8.pc1_only.cis_independent_qtl.txt.gz'
    script:
        '../scripts/snakemake_run_qtl_permutations.py'



# cis-QTL mapping: susie credible set summary stats
rule run_pcqtl_susie:
    input:
        genotypes = genotype_stem + '.fam',
        pcs = pc_output_dir + '{TISSUE}.pcs.bed',
        covariates = covariates_dir + '{TISSUE}.v8.covariates.txt',
    params:
        genotype_stem = genotype_stem,
        pcqtl_output_dir = pcqtl_output_dir
    resources:
        mem = "30G",
        time = "4:00:00"
    threads: 10
    conda:
        'tensorqtl_r'
    output:
        pcqtl_output_dir + '{TISSUE}/{TISSUE}.v8.pcs.susie.txt'
    shell:"""
        python workflow/scripts/run_susie.py {params.genotype_stem} \
            {input.pcs} \
            {params.pcqtl_output_dir}{wildcards.TISSUE}/{wildcards.TISSUE}.v8.pcs.susie.txt \
            {input.covariates}
        """