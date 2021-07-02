# load packages
using CSV
using DataFrames
using Turing
using StatsPlots
using MCMCChains

# load data into DataFrame
d = CSV.read(joinpath("analyses",
                      "data",
                      "height_d.csv"),
             DataFrame)

# build height estimation model
# my initial belief is that I'm 196 cm tall. I'd consider anything between 194
# and 198 to be plausible. however, those end-values should bot be very
# probable.
#

@model function m_height(height)
    μ ~ Normal(196, .75)
    σ ~ Exponential(1)

    for i in 1:length(height)
        height[i] ~ Normal(μ, σ)
    end
end

# sample
chains = sample(m_height(d.height_cm),
                NUTS(),
                MCMCThreads(),
                1000,
                8)

chains = sample(m_height(d.height_cm),
                Prior(),
                MCMCThreads(),
                1000,
                8)
