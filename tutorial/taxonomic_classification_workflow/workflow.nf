#!/usr/bin/env nextflow

params.fastq = "$baseDir/data/*.fastq"

process fastqc {
    input:
    file fastq from params.fastq

    output:
    file "fastqc_results" into fastqc_results

    script:
    """
    fastqc $fastq
    """
}

process kraken {
    input:
    file fastq from params.fastq

    output:
    file "kraken_results" into kraken_results

    script:
    """
    kraken --db path_to_kraken_database $fastq > kraken_report.txt
    """
}

process bracken {
    input:
    file kraken_report from kraken_results

    output:
    file "bracken_results" into bracken_results

    script:
    """
    bracken -d path_to_bracken_database -i $kraken_report -o bracken_report.txt
    """
}

process multiqc {
    input:
    file qc_results from fastqc_results.mix(bracken_results)

    script:
    """
    multiqc .
    """
}

workflow {
    fastqc()
    kraken()
    bracken()
    multiqc()
}
