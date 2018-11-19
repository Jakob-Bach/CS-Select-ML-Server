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
