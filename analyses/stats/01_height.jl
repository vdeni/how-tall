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
d.weekday = CategoricalArrays.CategoricalArray(Dates.dayname.(d.date);
                                               ordered = true)

CategoricalArrays.levels!(d.weekday,
                          ["Monday", "Tuesday", "Wednesday", "Thursday",
                           "Friday", "Saturday", "Sunday"])

# set plotting variables
marker_color = Plots.palette(:viridis, 3)[2]
line_color = Plots.palette(:viridis, 3)[2]

# make plots
p_height_by_day = StatsPlots.@df d #=
    =# Plots.scatter(:weekday,
                     :height_cm;
                     yticks = 194:200,
                     ylims = (194.5, 199.5),
                     xlims = (0.4, 7.5),
                     xticks = 1:7,
                     legend = false,
                     color = marker_color,
                     dpi = 300,
                     xlabel = "Day of the week",
                     ylabel = "Height in centimeters",
                     markeralpha = .7,
                     markerstrokewidth = 1,
                     gridstyle = :dash)

# plot height by time of day
d_p_by_hour = DataFrames.filter(x -> x.time_hours > 0,
                                d)

p_height_by_hour = StatsPlots.@df d_p_by_hour #=
    =# Plots.scatter(:time_hours,
                     :height_cm;
                     yticks = 194:199,
                     ylims = (194.5, 199.5),
                     xticks = 10:2:20,
                     xlims = (9, 21),
                     legend = false,
                     color = marker_color,
                     dpi = 300,
                     xlabel = "Time of day (hours)",
                     ylabel = "Height in centimeters",
                     markeralpha = .7,
                     markerstrokewidth = 1,
                     gridstyle = :dash)

# plot height distribution
p_height_distr = StatsPlots.@df d #=
    =# Plots.density(:height_cm;
                     dpi = 300,
                     fillcolor = Plots.palette(:viridis, 2)[1],
                     fillalpha = .5,
                     fillrange = 0,
                     color = :black,
                     yaxis = nothing,
                     xlabel = "Height in centimeters",
                     grid = false,
                     yshowaxis = false,
                     legend = :none)

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
                NUTS(1500, .80),
                MCMCThreads(),
                3000,
                6;
                discard_adapt = true)

# model diagnostics
# check trace and posterior density plots
Plots.plot(chains)

# check autocorrelation
MCMCChains.autocorplot(chains,
                       size = (600, 400))

# check chain mixing via R-hat, and check effective sample size
MCMCChains.summarize(chains)[:, [:parameters, :ess, :rhat]]

# make posterior predictive check
ppc = Turing.predict(m_height(Vector{Union{Missing, Number}}(missing,
                                                             nrow(d))),
                     chains)

# extract draws
d_ppc = DataFrames.DataFrame(ppc)

# fix column names
newnames = replace.(names(d_ppc),
                    "[" => "_") |>
    x -> replace.(x,
                  "]" => "")

d_ppc = DataFrames.rename(d_ppc,
                          newnames)

# plot predicted heights based on values from 100 randomly chosen iterations
v_iters = rand(1:nrow(d_ppc),
               1500)

d_ppc_plot = d_ppc[v_iters, :]

d_ppc_plot.id = 1:nrow(d_ppc_plot)

# reshape data for plotting
d_ppc_plot = DataFrames.stack(d_ppc_plot,
                              r"height_";
                              variable_name = "rep_id",
                              value_name = "rep_height")

# plot posterior predictions
p_ppc = StatsPlots.@df d_ppc_plot #=
    =# Plots.density(:rep_height;
                     group = :iteration,
                     legend = :topright,
                     linecolor = :black,
                     linewidth = 1,
                     linealpha = .1,
                     yaxis = nothing,
                     xlabel = "Height in centimeters",
                     grid = false,
                     yshowaxis = false,
                     label = ["Posterior predictions" #=
                              =# repeat([""], 1, 1499)])

Plots.density!(p_ppc,
               d.height_cm;
               linewidth = 2,
               linecolor = line_color,
               fillrange = 0,
               fill = line_color,
               fillalpha = .5,
               label = "Data")
