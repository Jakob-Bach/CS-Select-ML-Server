# ML Server

ML functionality and dataset handling of *CS:Select*, a (discontinued) research project intended to crowdsource feature selection.
The basic idea is to let domain experts decide which features to select and display them a score for their selection decision.
To that end, the ML server stores datasets, receives a combination of selected features from a client, builds a prediction model from that, and returns prediction performance.
Also, the server provides basic summary plots and feature descriptions to the client, which can be shown to domain experts.
The REST API for this is implemented in `MLServerAPI.R`, using the package `plumber`.
Below you can find hints to run the server, potentially in a parallelized manner with automatic load balancing.
An implementation of the frontend and backend of the main software can be found [here](https://github.com/cs-select-team).
We haven't properly versioned our R packages/environment, so you if wanted to run the software, you needed to install all required packages manually.

## Adding a dataset

A demo dataset for the server can be obtained by running `PrepareDemoDataset.R`.
To add a new dataset to the server, you can (and probably should) first add a similar pre-processing script, as there are some requirements:

- The dataset has to represent a classification task formatted as *data.table* with the class labels being in the last column.
- Currently we only support binary classification, so the class labels should either be *logical* (boolean) or a *factor* with two levels.
- If there are any outliers which you don't want, you need to handle them yourself; we won't do any outlier-related pre-processing.
- NA values are by default replaced with the median in numeric columns and made a new category in categorical columns.

The following steps are necessary to integrate your dataset:

- Save your (pre-processed) dataset in `datasets/<<datasetName>>.rds`.
- Create a tabulator-separated, *UTF-8*-encoded file `datasets/<<datasetName>>_columns.csv` containing feature descriptions. One column has to be named *dataset_feature* and has to contain the feature names as used in the dataset, further columns should contain natural-language names and descriptions, possibily in several languages (e.g. *name_en*, *description_en*).
- Enter your dataset name in `PrepareForClassification.R` and run this script. Feature summaries, plots and train/test datasets for classification will be created by the script. They can be found in the directory `datasets/`.

Once you start the server, your dataset will be available.

## Running the server

Make sure you have provided a dataset, e.g., by running `PrepareDemoDataset.R`.
Else, the server is only able to tell you its version, but cannot train prediction models.

### Manual solution

1. If not already done, install [*R*](https://www.r-project.org/).
1. If not already done, install necessary dependencies and prepare data by running `RScript Setup.R` from a console (you might need to add the *bin/* directory of your *R* installation to the environment variable `PATH` first).
1. Start the server by running `Rscript RunMLServer.R` from a console.
1. The server starts and prints the URL of the interactive [*Swagger*](https://swagger.io/) API documentation.
1. Stop the server by pressing *CTRL + C* or just closing the console.

### Docker solution

1. If not already done, install [*Docker*](https://www.docker.com/).
1. If not already done, install our *Docker* image by running `docker build --rm -t ml-server .` from a console (image name is arbitrary). This might take some minutes and print a lot of stuff to the console.
1. Start the server by running `docker run --rm -p 8000:8000 -d ml-server` from a console.
1. Stop the server by running `docker stop $(docker ps -f "ancestor=ml-server" -q)` from a console.

### Docker Compose solution

In contrast to the two other solutions, this approach allows multi-threading.
Incoming requests are load-balanced by [*nginx*](https://www.nginx.com/).

1. If not already done, install [*Docker*](https://www.docker.com/). On Linux systems, you also need to install [*Docker Compose*](https://docs.docker.com/compose/install/) separately.
1. If not already done, install our *Docker* image by running `docker build --rm -t ml-server .` from a console (image name is arbitrary). This might take some minutes and print a lot of stuff to the console.
1. Start the ML server instances by running `docker-compose up -d --scale ml-server-api=2` from a console. This would start two instances of the ML server. While the servers are running, you can call that command again with a different number to increase or decrease the number of ML server instances.
1. Stop and remove all instances by running `docker-compose down` from a console. You can also stop the containers without removing them by calling `docker-compose stop` and later restart them with `docker-compose start`.

## Using the server

By default, the server is available at port *8000* of *localhost* for the manual and for the *Docker* solution.
The *Docker Compose* approach uses port *80*, but you can leave the port specification out of the URL.
You can use a tool like [*curl*](https://curl.haxx.se/) to make requests or simply use your browser.
Examples of queries:

- `localhost:8000/version` (good to check if API is working at all)
- `localhost:8000/features?dataset=populationGender`
- `localhost:8000/score?dataset=populationGender&features=1,2,3`

Furthermore, an interactive API documentation is available at `http://127.0.0.1:8000/__swagger__/`.
If an internal error occurs, e.g. the dataset was not found, status code *500* and an error message are returned.
