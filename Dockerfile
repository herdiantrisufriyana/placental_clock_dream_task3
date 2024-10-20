# Start with the official RStudio image
FROM rocker/rstudio:4.4.1

# Avoid user interaction with tzdata
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev \
    libfontconfig1-dev \
    libcairo2-dev \
    libxt-dev \
    xorg-dev \
    libreadline-dev \
    libbz2-dev \
    liblzma-dev \
    zlib1g-dev \
    gfortran \
    software-properties-common \
    bash \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    pkg-config \
    libtiff5-dev \
    libjpeg-dev \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Download and install Miniconda to /opt/conda, a directory accessible by the rstudio user
RUN curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniconda3-latest-Linux-x86_64.sh

# Add Conda to the PATH and initialize Conda globally for all users
ENV PATH="/opt/conda/bin:$PATH"
RUN /opt/conda/bin/conda init bash && \
    echo ". /opt/conda/etc/profile.d/conda.sh" > /etc/profile.d/conda.sh

# Install Python and its libraries
RUN conda create -n conda_env python=3.12.4 -y
RUN conda install -n conda_env jupyterlab=4.0.11 -y
RUN conda install -n conda_env pandas=2.2.2 -y
RUN conda install -n conda_env scikit-learn=1.5.1 -y

# Activate the conda environment globally
RUN echo "conda activate conda_env" >> /etc/profile.d/conda.sh

# Install R packages
RUN R -e "install.packages('BiocManager', repos='http://cran.rstudio.com/')"
RUN R -e "BiocManager::install('tidyverse', ask=FALSE, update=FALSE, force=TRUE)"
RUN R -e "BiocManager::install('kableExtra', ask=FALSE, update=FALSE, force=TRUE)"
RUN R -e "BiocManager::install('ggpubr', ask=FALSE, update=FALSE, force=TRUE)"
RUN R -e "BiocManager::install('dslabs', ask=FALSE, update=FALSE, force=TRUE)"

# Install project-specific R packages/Python libraries (in chronological order)
RUN R -e "BiocManager::install('reticulate', ask=FALSE, update=FALSE, force=TRUE)"
RUN R -e "BiocManager::install('pbapply', ask=FALSE, update=FALSE, force=TRUE)"
RUN R -e "BiocManager::install('methylumi', ask=FALSE, update=FALSE, force=TRUE)"
RUN R -e "BiocManager::install('IlluminaHumanMethylation450kanno.ilmn12.hg19', ask=FALSE, update=FALSE, force=TRUE)"
RUN R -e "BiocManager::install('IlluminaHumanMethylationEPICanno.ilm10b4.hg19', ask=FALSE, update=FALSE, force=TRUE)"
RUN R -e "BiocManager::install('IlluminaHumanMethylation450kmanifest', ask=FALSE, update=FALSE, force=TRUE)"
RUN R -e "BiocManager::install('IlluminaHumanMethylationEPICmanifest', ask=FALSE, update=FALSE, force=TRUE)"
RUN R -e "BiocManager::install('DMRcate', ask=FALSE, update=FALSE, force=TRUE)"
RUN R -e "BiocManager::install('ChAMP', ask=FALSE, update=FALSE, force=TRUE)"
RUN R -e "BiocManager::install('vroom', ask=FALSE, update=FALSE, force=TRUE)"
RUN R -e "BiocManager::install('torch', ask=FALSE, update=FALSE, force=TRUE)"

# Set the working directory to ~/project on R session start
RUN echo 'setwd("~/project")' >> /home/rstudio/.Rprofile

# Reset DEBIAN_FRONTEND variable
ENV DEBIAN_FRONTEND=

# Set the working directory
WORKDIR /home/rstudio/

# Expose ports for RStudio and JupyterLab
EXPOSE 8787 8888

# Set up the password for rstudio user
ENV PASSWORD=1234
RUN echo "rstudio:${PASSWORD}" | chpasswd && adduser rstudio sudo

# Start RStudio Server
CMD ["/init"]