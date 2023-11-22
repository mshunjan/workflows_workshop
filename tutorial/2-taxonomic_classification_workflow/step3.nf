// WORKFLOW parameters
params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"
params.kraken_db = "https://genome-idx.s3.amazonaws.com/kraken/16S_Greengenes13.5_20200326.tgz"
params.multiqc = "$projectDir/multiqc"
params.outdir = "results"

log.info """\
    C O O L B E A N S   P I P E L I N E
    ===================================
    reads        : ${params.reads}
    kraken_db    : ${params.kraken_db}
    outdir       : ${params.outdir}
    """
    .stripIndent()

process FASTQC {
    input:
    path reads

    output:
    path('fastqc_results'), emit: qc_results

    script:
    """
    mkdir -p fastqc_results
    fastqc $reads --outdir fastqc_results
    """
}

workflow {
    ch_read_pairs = Channel.fromFilePairs(params.reads)
    FASTQC(
        ch_read_pairs
    )
}
