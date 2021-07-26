# how-tall
My first attempt at an analysis in the Julia language. Trying to determine how
tall I am using Bayesian estimation with `{Turing.jl}`.

## Structure

- `analyses/`
    - `data/`
        - `hegiht_d.csv`: data file with 30 observations and 3 columns (`date` -
            date of measurement; `time_hours` - the hour at which the
            measurement was taken; `height_cm` - height measured in centimeters)
    - `stats/`
        - `01_height.jl`: Julia analysis code
        - `02_height.stan`: Stan model which I believe should be equivalent
            to the `{Turing}` model defined in `01_height.jl`
- `docs/`
    - `index.[jmd|html]`: written report on height analysis
