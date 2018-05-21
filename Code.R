
library(ggplot2)
library(ggthemes)
library(dplyr)
library(plotly)
library(scales)

options(scipen = 999)

n.trials <- 25000
prior.alpha <- 1
prior.beta <- 1

a.success <- 134
a.failure <- 50799 - a.success # Total views/impressions (denominator) minus success

b.success <- 162
b.failure <- 52935 - b.success

# Sample from beta distribution based on results
a.samples <- rbeta(n.trials, a.success + prior.alpha, a.failure + prior.beta)
b.samples <- rbeta(n.trials, b.success + prior.alpha, b.failure + prior.beta)

# probability that b is superior to a
p.b_superior <- sum(b.samples > a.samples)/n.trials
p.b_superior

df <- data.frame(Effect = b.samples/a.samples - 1)

# Remove extreme outliers for nicer plot
outlier_values <- boxplot.stats(df$Effect, coef = 3)$out
df <- df %>% filter(!Effect %in% outlier_values)

# ggplot base histogram
p <- ggplot(df, aes(x = Effect)) + geom_histogram(fill = 'grey50', alpha = .6, bins = 30)
    
# Extract out ggplot data object for 2nd axis transformation
ggplot_df <- ggplot_build(p)$data[[1]]

# Find max
transform <- max(ggplot_df$ymax)

# Find min/max of x for custom breaks, set to .5
xmin <- min(ggplot_df$x)
xmax <- max(ggplot_df$x)

# p + geom_line(aes_string(y = paste0('..y.. * ', transform), label = '..y..'), stat='ecdf') + 
#     geom_vline(xintercept = 0, linetype = 'dashed') +
#     scale_y_continuous(sec.axis = sec_axis(~./transform, name = "ecdf")) +
#     scale_x_continuous(labels = scales::percent) +
#     theme_light()

plotly_text <- 'Cumulative Probability'

p + geom_line(aes_string(y = paste0('..y.. * ', transform), text = 'plotly_text', label = '..y..'), stat='ecdf', size = 1.3) + # Add ecdf distribution
    # geom_ribbon(aes_string(ymin = 0, ymax = paste0('..y.. * ', transform), label = '..y..'), stat='ecdf', 
    #             alpha = .4, fill = 'steelblue2') + # area fill, doesn't work with plotly
    geom_vline(xintercept = 0, linetype = 'dashed') +
    scale_y_continuous(breaks = round(seq(0, transform, transform/4),0), # Main axis
                       minor_breaks = NULL,
                       sec.axis = sec_axis(~./transform, breaks = seq(0, 1, .25), 
                                           name = "Cumulative Probability (line)", labels = scales::percent)) + # 2nd axis
    scale_x_continuous(breaks = seq((xmin - xmin %% .5 + .5), (xmax + xmax %% .5), .5), # x-axis breaks at .5
                       # minor_breaks = NULL,
                       labels = scales::percent) +
    labs(title = 'A/B Test Results', x = 'Effect', y = 'Count (bar)') +
    theme_light()


ggplotly(tooltip = c('plotly_text', 'Effect', 'count','label'))


# Equivalent to upper tailed t-test

p_hat <- (a.success + b.success) / (a.success + a.failure + b.success + b.failure) # pooled p

z_score <- abs((a.success / (a.success + a.failure)) - (b.success / (b.success + b.failure)) - 0) /
    sqrt((p_hat)*(1 - p_hat)*(1/(a.success + a.failure) + 1/(a.success + a.failure))) 

alpha = .05 
z.alpha = qnorm(1-alpha) 
z.alpha # rejection Z

z_score # Test Z score

pnorm(z_score, lower.tail = FALSE) # p-value of upper tail test

# equivalent to our simulation
1 - p.b_superior
