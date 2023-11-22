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
    container 'quay.io/biocontainers/mulled-v2-5799ab18b5fc681e75923b2450abaa969907ec98:87fc08d11968d081f3e8a37131c1f1f6715b6542-0'
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

process BRACKEN {
    container 'quay.io/biocontainers/bracken:2.7--py39hc16433a_0'
    input:
    path kraken_report
    path db

    output:
    path('bracken_output'), emit: bracken_results

    when:
    task.ext.when == null || task.ext.when

    script:
    def threshold = meta.threshold ?: 10
    def taxonomic_level = meta.taxonomic_level ?: 'S'
    def read_length = meta.read_length ?: 150
    def args = task.ext.args ?: "-l ${taxonomic_level} -t ${threshold} -r ${read_length}"
    bracken_report = "${kraken_report.basename}.tsv"
    """
    bracken \\
        ${args} \\
        -d '${database}' \\
        -i '${kraken_report}' \\
        -o '${bracken_report}'
    """
}

process PLOT_DATA {
    container 'plot-data:latest'
    publishDir "${params.outdir}/plots", mode: 'copy'

    input:
    path data_file

    output:
    path "${params.outdir}/plots/*.html", emit: plot

    script:
    """
    python ./plot_data.py -i $data_file -o ${params.outdir}/plots/output.html
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
    BRACKEN(ch_report, ch_kraken_db)

    PLOT_DATA(BRACKEN.out.bracken_results)
    ch_plot = PLOT_DATA.out.plot
    
    MULTIQC(quant_ch.mix(FASTQC.out.qc_results).collect())
}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone! Open the following report in your browser --> $params.outdir/multiqc_report.html\n" : "Oops .. something went wrong" )
}