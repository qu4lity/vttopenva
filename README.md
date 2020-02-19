# VTT OpenVA
VTT OpenVA platform consist of software components that are used as building blocks of visual analytics tools:

* A database that stores the application data in a standard domain independent form
* An extendable analysis and visualization library providing a selection of analysis and visualization methods. The library is customized based on application needs
* Embedded R statistical computing environment
* A web user interface where the user can select variables for analysis and explore the data with the help of visualizations. The visualizations can be e.g. in 2D, 3D or augmented reality, and interconnected with real object visualizations. The user interface suggests the user the appropriate analysis methods letting them to concentrate on the substance instead of data analysis methods.

VTT OpenVA is independent of the underlying data collection solution.The data can come from several sources, also in realtime. The data to be analyzed is loaded from the sources to the database through a uniform data interface.

# Quick start

If you want to see how VTT OpenVA works, there there are two Docker images that demonstrate OpenVA in action. download [docker-compose.yml](https://github.com/pekka-siltanen/vttopenva/blob/master/docker-compose.yml), run `docker-compose up -d`  in the same directory and open _http://localhost:8080_ in your browser. Additional instructions on the Docker demo can be found [here](https://github.com/pekka-siltanen/vttopenva/wiki/Docker-demo).

# Find out more
## [Technical documents](https://github.com/pekka-siltanen/vttopenva/wiki/Technical-documents)
## Setup Guide

