# ML Server

ML functionality and dataset handling of *CS:Select*.

## Running the server

1. If not already done, install [*R*](https://www.r-project.org/).
1. If not already done, install necessary dependencies and prepare data by running `RScript Setup.R` from a console (you might need to add the *bin/* directory of your *R* installation to the environment variable `PATH` first).
1. Start the server by running `Rscript RunMLServer.R` from a console.
1. The server starts and prints the URL of the interactive [*Swagger*](https://swagger.io/) API documentation.
1. Stop the server by pressing *CTRL + C* or just closing the console.
