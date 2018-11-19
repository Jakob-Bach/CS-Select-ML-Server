# ML Server

ML functionality and dataset handling of *CS:Select*.

## Running the server

1. If not already done, install [*R*](https://www.r-project.org/).
1. If not already done, install necessary dependencies and prepare data by running `RScript Setup.R` from a console (you might need to add the *bin/* directory of your *R* installation to the environment variable `PATH` first).
1. Start the server by running `Rscript RunMLServer.R` from a console.
1. The server starts and prints the URL of the interactive [*Swagger*](https://swagger.io/) API documentation.
1. Stop the server by pressing *CTRL + C* or just closing the console.

## Using the server

By default, the server is available at port *8000* of *localhost*.
You can use a tool like [*curl*](https://curl.haxx.se/) to make requests or simply use your browser.
Examples of queries:

- `localhost:8000/version` (good to check if API is working at all)
- `localhost:8000/features?dataset=populationGender`
- `localhost:8000/score?dataset=populationGender&features=1,2,3`

Furthermore, an interactive API documentation is available at `http://127.0.0.1:8000/__swagger__/`.
If an internal error occurs, e.g. the dataset was not found, status code *500* and an error message are returned.

## Adding a dataset

To add a new dataset, you can (and probably should) first add a custom pre-processing script like `PrepareDemoDataset.R`.
It has to be a classification task formatted as *data.table* with the class labels in column *target*.
If there are any outliers, you need to handle them manually.
NA values are by default replaced with the median in numeric columns and made a new category in categorical columns.
The following steps are necessary to integrate your dataset:

- Save your (pre-processed) dataset in `datasets/<<datasetName>>.rds`.
- Create a two-column (*Feature*, *Description*), tabulator-separated file `datasets/<<datasetName>>_columns.csv` containing feature descriptions.
- Enter your dataset name in `PrepareForClassification.R` and run this script.

Feature summaries, plots and train/test datasets for classification will be created by the script.
They can be found in the directory `datasets/`.
Once you start the server, your dataset will be available.
