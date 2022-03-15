//There is a -L option to only output alignments in interval, might be an option for exons/panel data?
process SAMTOOLS_VIEWINDEX {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::samtools=1.15" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.15--h1170115_1' :
        'quay.io/biocontainers/samtools:1.15--h1170115_1' }"

    input:
    tuple val(meta), path(input), path(index)
    path  fasta
    path  fasta_fai

    output:
    tuple val(meta), path("*.bam"), path("*.bai")  , optional: true, emit: bam_bai
    tuple val(meta), path("*.cram"), path("*.crai"), optional: true, emit: cram_crai
    path  "versions.yml"                                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args  ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reference_command = fasta ? "--reference ${fasta} -C" : ""
    """
    samtools view --threads ${task.cpus-1} ${reference_command} $args $input > ${prefix}.cram
    samtools index -@${task.cpus} ${prefix}.cram

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
