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
    path reads

    output:
    path ('fastqc_results'), emit: qc_results

    script:
    """
    mkdir -p fastqc_results
    fastqc $reads --outdir fastqc_results
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
    tar xzvf "${database}" -C kraken_db
    
    """
}

process KRAKEN2 {
    input:
    path reads
    path db

    output:
    path('*report.txt'), emit: report

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    kraken2 \\
        --db $db \\
        --report kraken2.report.txt \\
        --paired \\
        $reads
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

    ch_kraken_db = UNPACK_DATABASE.out.db

    KRAKEN2(ch_read_pairs, ch_kraken_db)

    ch_report = KRAKEN2.out.report
}