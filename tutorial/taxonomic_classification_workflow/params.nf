// WORKFLOW parameters
params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"
params.kraken_db = "https://genome-idx.s3.amazonaws.com/kraken/16S_Greengenes13.5_20200326.tgz"
params.multiqc = "$projectDir/multiqc"


log.info """\
    M E T A S E N S E   P I P E L I N E
    ===================================
    transcriptome: ${params.transcriptome_file}
    reads        : ${params.reads}
    outdir       : ${params.outdir}
    """
    .stripIndent(true)
