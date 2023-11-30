# Use an official base image as a parent image
FROM ubuntu:20.04

# Set the working directory in the container
WORKDIR /usr/src/app

# Install any needed packages specified in requirements.txt
RUN apt-get update && \
    apt-get install -y default-jdk perl wget unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and install FastQC
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip && \
    unzip fastqc_v0.11.9.zip && \
    chmod +x FastQC/fastqc && \
    ln -s /usr/src/app/FastQC/fastqc /usr/local/bin/fastqc

# Run FastQC when the container launches
CMD ["fastqc", "--version"]
