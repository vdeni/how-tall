# load packages
using CSV
using DataFrames
using CategoricalArrays
using Turing
using Plots
using StatsPlots
using MCMCChains
using Dates

# set plotting backend
Plots.GRBackend()

# load data into DataFrame
d = CSV.read(joinpath("analyses",
                      "data",
                      "height_d.csv"),
             DataFrames.DataFrame)

# plot height by day of week
d.weekday = CategoricalArrays.CategoricalArray(Dates.dayname.(d.date),
                                               ordered = true)

levels!(d.weekday,
        ["Monday", "Tuesday", "Wednesday", "Thursday",
         "Friday", "Saturday", "Sunday"])

p_height_by_day = @df d scatter(:weekday,
                                :height_cm;
                                yticks = 194:200,
                                ylims = (194.5, 199.5),
                                xlims = (0.4, 7.5),
                                xticks = 1:7,
                                legend = false,
                                color = palette(:viridis, 3)[2],
                                dpi = 300,
                                xlabel = "Day of the week",
                                ylabel = "Height in centimeters",
                                markeralpha = .7,
                                markerstrokewidth = 1,
                                gridstyle = :dash)

# plot height by time of day
d_p_by_hour = DataFrames.filter( x -> x.time_hours > 0, d)

p_height_by_hour = @df d_p_by_hour scatter(:time_hours,
                                           :height_cm;
                                           yticks = 194:199,
                                           ylims = (194.5, 199.5),
                                           xticks = 10:20,
                                           xlims = (9, 21),
                                           legend = false,
                                           color = palette(:viridis, 3)[2],
                                           dpi = 300,
                                           xlabel = "Time of day (hours)",
                                           ylabel = "Height in centimeters",
                                           markeralpha = .7,
                                           markerstrokewidth = 1,
                                           gridstyle = :dash)

# build height estimation model
# my initial belief is that I'm 196 cm tall. I'd consider anything between 194
# and 198 to be plausible. however, those end-values should bot be very
# probable.
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
                3000,
                6;
                n_adapts = 1500,
                drop_warmup = true)
