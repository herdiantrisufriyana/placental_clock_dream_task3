# Project template

## System requirements

Install Docker desktop once in your machine. Start the service every time you build this project image or run the container.

## Installation guide

Modify Dockerfile according to AMD64 or ARM64.

https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh

Change `project_template` and `$(pwd)` to the project image name and the absolute path of the project folder.

Build the project image once for a new machine.

```{bash}
docker build -t project_template --load .
```

Run the container every time you start working on the project.

```{bash}
docker run -d -p 8787:8787 -p 8888:8888 -v "$(pwd)":/home/rstudio/project --name project_template_container project_template
```

## Instructions for use

### Rstudio

Visit http://localhost:8787.
Username: rstudio
Password: 1234

Your working directory is ~/project.

### Jupyter lab

Use terminal in RStudio to run jupyter lab using this line of codes.

```{bash}
jupyter-lab --ip=0.0.0.0 --no-browser --allow-root
```

Click a link in the results to open jupyter lab in a browser.






