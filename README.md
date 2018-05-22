### Bayesian AB Testing

Code repository that visualizes simulated A/B Test Lift distribution and cumulative distribution on the same chart via ggplot2 in R.

Useful to measure click-through rate A/B tests to visualize distribution of possible lift, as well as the probability that the test CTR > control CTR

Additional Info: <a href="https://www.countbayesie.com/blog/2015/4/25/bayesian-ab-testing" target="_blank">Count Bayesie Bayesian AB Testing</a>  

### Example Plot Output & Interpretation

Control CTR = 25%,

Control Trials = 100

Test CTR = 35%,

Test Trials = 100

![Sample Plot](Rplot.png)

The histogram shows the distribution of simulated Test CTR's / Control CTR's to visualize potential Test lift probabilistically.

The line shows the cumulative distribution function of Test CTR / Control CTR. This can be used to quantify the probability of a certain effect size. For example, in the above plot, there is a 50% chance that the test group will exhibit a lift of 40% or more (the median effect, same as doing (.35 - .25) / .25).

The line intercept at 0 shows the probability that the test group will underperform the control group, or ~ 6.5% above. 1 - .065 = 93.5%, or the probability that the test group will overperform the control group. 

A p-value can be derived from the line intercept at 0, or ~.065 above. This is interpreted as the probability that this result would occur by chance alone, given that the control CTR is true. 

Classically, when a result is statistically significant (typically, p < .05), all we can say, as in Count Bayesie above, is that these 2 values are not likely the same (i.e. not from the same distribution). However, in a typical business setting, we want to know the effect size of our test, or how much better the test group will perform. The plotted distribution gives a business a more probabilistic view of that effect.


### Shiny App

https://bigtimestats.shinyapps.io/Bayesian-AB-Testing-App/

![Shiny](ShinyApp.png)

The shiny app takes all of the above, allows a user to input custom A/B test results, and adds the Bayesian Probability that Test > Control and the p-value derived using a single tailed t-test.

1 - the Bayesian Probability is within range of the classically computed p-value, which is expected. The benefit of the app is to visualize possible outcomes probabilistically.

One limitation of the ggplotly package in R (interactive plot) is that it does not have the capability to visualize a secondary axis. A user show hover over the line values to see the Cumulative Probability.




