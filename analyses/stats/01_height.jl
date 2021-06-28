# load packages
using CSV
using DataFrames
using Turing
using StatsPlots
using MCMCChains

# load data into DataFrame
d = CSV.read(joinpath("analyses",
                      "data",
                      "heights_d.csv"),
             DataFrame)

# build height estimation model
# my initial belief is that I'm 196 cm tall. I'd consider anything between 194
# and 198 to be plausible. however, those end-values should bot be very
# probable.
#

@model function m_height(height)
    μ ~ Normal(196, .75)

    for i in 1:length(height)
        height[i] ~ Normal(μ, .5)
    end
end

# sample
chains = sample(m_height(d.height_cm),
                HMC(.05, 10),
                1000)

