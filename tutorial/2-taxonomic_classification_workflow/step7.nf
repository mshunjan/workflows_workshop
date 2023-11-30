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
    container 'quay.io/biocontainers/fastqc:0.11.9--0'
    
    input:
    tuple val(sample_id), path(reads)

    output:
    path "fastqc_${sample_id}_logs", emit: qc_results

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

process KRAKEN2 {
    container 'quay.io/biocontainers/mulled-v2-5799ab18b5fc681e75923b2450abaa969907ec98:87fc08d11968d081f3e8a37131c1f1f6715b6542-0'
    
    input:
    tuple val(sample_id), path(reads)    
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

process BRACKEN {
    container 'quay.io/biocontainers/bracken:2.7--py39hc16433a_0'
    
    input:
    path kraken_report
    path db

    output:
    path('bracken_output.tsv'), emit: bracken_results

    when:
    task.ext.when == null || task.ext.when

    script: 
    """
    bracken \\
        -l S -t 10 -r 150 \\
        -d '${db}' \\
        -i '${kraken_report}' \\
        -o  bracken_output.tsv
    """
}

process MULTIQC {
    container 'quay.io/biocontainers/multiqc:1.13--pyhdfd78af_0'
    publishDir params.outdir, mode:'copy'

    input:
    path '*'

    output:
    path 'multiqc_report.html'

    script:
    """
    multiqc .
    """
}

workflow {
    ch_read_pairs = Channel.fromFilePairs(params.reads)
    FASTQC(ch_read_pairs)

    UNPACK_DATABASE(params.kraken_db)

    ch_kraken_db = UNPACK_DATABASE.out.db
    KRAKEN2(ch_read_pairs, ch_kraken_db)

    ch_report = KRAKEN2.out.report
    BRACKEN (ch_report, ch_kraken_db)
    ch_multiqc_files = Channel.empty()
    MULTIQC(ch_multiqc_files.mix(FASTQC.out.qc_results).collect())
}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone! Open the following report in your browser --> $params.outdir/multiqc_report.html\n" : "Oops .. something went wrong" )
}