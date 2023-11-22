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

ch_read_pairs = Channel.fromFilePairs(params.reads)

process FASTQC {
    input:
    tuple val(sample_id), path(reads)

    output:
    path "fastqc_${sample_id}_logs"

    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
    """
}
process UNPACK_DATABASE {

    input:
    path (database)

    output:
    path ('kraken_db')                 , emit: db
    
    script:
    """
    mkdir kraken_db
    tar xzvf "${database}" -C kraken_db --strip-components=1
    
    """
}

workflow {
    ch_read_pairs = Channel.fromFilePairs(params.reads)
    FASTQC(
        ch_read_pairs
    )

    UNPACK_DATABASE(
        params.kraken_db
    )
}