
library(DT)
library(shiny)
library(shinydashboard)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(plotly)
library(scales)

#### Shiny UI ####

options(scipen = 999)

header <- dashboardHeader(title = "BigTimeStats A/B Testing App", titleWidth = 300)
                          
sidebar <- dashboardSidebar(disable = TRUE)

body <- dashboardBody(
    
    fluidRow(
        column(width = 2,
            box(title = 'Directions',
                status = "warning", solidHeader = TRUE,
                p('1. Start by selecting your click thoughs (successes) for your control/test groups.'),
                p('2. Next, select the # of Trials (i.e. impressions).'),
                p('3. If you have CTR:'),
                p('# of Successes = CTR * # of Trials'),
                p('4. If you have prior knowledge about the success of the test, input it under the', strong('Prior'),
                  ' section. Leave as 0 if no information available.'),
                p('5. Adjust # of Simulations for better results. Higher number results in increased processing but slightly more accuracy'),
                p('6. Select plot type'),
                p('7. Click on Run (few sec)'),
                # p('-------------'),
                p('Made by Adam Vagner'),
                p(a("LinkedIn", href="https://www.linkedin.com/in/adamvagner/", target="_blank")),
                p(a("Blog", href="https://bigtimestats.wordpress.com", target="_blank")),
                p('See', a("Source Code", href="https://github.com/BigTimeStats/AB-Testing-Shiny-Bayes", target="_blank"), 'for more info and license'),
                p('Based on work at: ',a("Count Bayesie", href="https://www.countbayesie.com/blog/2015/4/25/bayesian-ab-testing", target="_blank")),
                
                width = NULL
            )
        ),
        
        column(width = 4,
               
               fluidRow(
                   column(width = 6,
                        box(title = 'Control Inputs',
                            status = "danger", solidHeader = TRUE,
                            
                            h5('Prior'),
                            
                            numericInput("control.prior.success", 
                                         p("# of Successes"), 
                                         value = 0),
                            numericInput("control.prior.trials", 
                                         p("# of Trials"), 
                                         value = 0),
                            
                            h5('Current A/B Experiment'),
                            
                            numericInput("control.success", 
                                         p("# of Successes"), 
                                         value = 15),
                            numericInput("control.trials", 
                                         p("# of Trials"), 
                                         value = 100),
                            width = NULL
                        )
                    ),
                
                    column(width = 6,
                           box(title = 'Test Inputs',
                               status = "danger", solidHeader = TRUE,
                               
                               h5('Prior'),
                               
                               
                               numericInput("test.prior.success", 
                                            p("# of Successes"), 
                                            value = 0),
                               numericInput("test.prior.trials", 
                                            p("# of Trials"), 
                                            value = 0),
                               
                               h5('Current A/B Experiment'),
                               
                               numericInput("test.success", 
                                            p("# of Successes"), 
                                            value = 25),
                               numericInput("test.trials", 
                                            p("# of Trials"), 
                                            value = 100),
                               
                               width = NULL
                           )
                        )
                   ),
               
               fluidRow(
                   column(width = 12,
                          box(title = 'Simulation',
                              status = "danger", solidHeader = TRUE,
                              
                              numericInput("ntrials", 
                                           p("# of Simulations (10,000 recommended)"), 
                                           value = 10000,
                                           min = 1,
                                           max = 100000),
                              
                              selectInput("radio", p("Plot Type"),
                                           choices = list("Lift Curve" = 1, 
                                                          "Histogram Comparison" = 2,
                                                          "Density Plot Comparison" = 3), 
                                           selected = 1),
                              
                              actionButton(inputId = "button", 
                                           label = "Run"),
                              
                              width = NULL
                          )
                   )
               )
               ),
        
        column(width = 6,
             fluidRow( 
               column(width = 6,
                      box(title = 'Simulated Bayesian Probability',
                            status = "info", solidHeader = TRUE,
                          p('Simulated Probability Test > Control: '),
                          textOutput('superior'),
                            width = NULL
                      )
               ),
               column(width = 6,
                      box(title = 'Classical T-Test',
                           status = "info", solidHeader = TRUE,
                          p('Upper Tail P-Value: '),
                          textOutput('ttest'),
                           width = NULL
                      )
               )
             ),
             
             fluidRow(
                 column(width = 12,
                       box(title = 'Interactive Plot Output',
                           status = "info", solidHeader = TRUE,
                           plotlyOutput('plotly', height = '540px'),
                           width = NULL
                       )
                 )
             )
        )
    )
)

ui <- dashboardPage(
    header, 
    sidebar,
    body,
    skin = 'blue'
    
)

#### Server #### 

server <- function(input, output) { 
    
    df <- eventReactive(input$button, {
        
        n.trials <- input$ntrials
        a.prior.alpha <- input$control.prior.success
        a.prior.beta <- input$control.prior.trials - a.prior.alpha
        
        b.prior.alpha <- input$test.prior.success
        b.prior.beta <- input$test.prior.trials - b.prior.alpha
        
        a.success <- input$control.success
        a.failure <- input$control.trials - a.success # Total views/impressions (denominator) minus success
        
        b.success <- input$test.success
        b.failure <- input$test.trials - b.success
        
        # Sample from beta distribution based on results
        a.samples <- rbeta(n.trials, a.success + a.prior.alpha, a.failure + a.prior.beta)
        b.samples <- rbeta(n.trials, b.success + b.prior.alpha, b.failure + b.prior.beta)
        
        df <- data.frame(Lift = b.samples/a.samples - 1, Control = a.samples, Test = b.samples)
        
        # Remove extreme outliers for nicer plot
        outlier_values <- boxplot.stats(df$Lift, coef = 3)$out
        df <- df %>% filter(!Lift %in% outlier_values)
        df
        
        
    })
    
    output$superior <- renderText({
        
        p.b_superior <- sum(df()$Lift > 0)/nrow(df())
        scales::percent(p.b_superior)
    })
    
    pvalue <- eventReactive(input$button, {
        
        a.success <- input$control.success
        a.failure <- input$control.trials - a.success # Total views/impressions (denominator) minus success
        
        b.success <- input$test.success
        b.failure <- input$test.trials - b.success
        
        p_hat <- (a.success + b.success) / (a.success + a.failure + b.success + b.failure) # pooled p
        
        z_score <- ((b.success / (b.success + b.failure) - a.success / (a.success + a.failure)) - 0) /
            sqrt((p_hat)*(1 - p_hat)*(1/(a.success + a.failure) + 1/(a.success + a.failure))) 
        
        pnorm(z_score, lower.tail = FALSE) 
        
    })
    
    output$ttest <- renderText({
        
       round(pvalue(), 20)
        
    })
    
    output$plotly <- renderPlotly({
            
        # ggplot base histogram
        p1 <- ggplot(df(), aes(x = Lift)) + 
            geom_histogram(fill = 'steelblue4', alpha = .6, bins = 30) + 
            geom_vline(xintercept = 0, linetype = 'dashed')
        
        # Extract out ggplot data object for 2nd axis transformation
        ggplot_df <- ggplot_build(p1)$data[[1]]
        
        transform <- max(ggplot_df$ymax)
        median1 <- median(df()$Lift)
        
        xmin <- min(ggplot_df$x)
        xmax <- max(ggplot_df$x)
        
        y_data <- data.frame(x = c(xmin, median1), y = c(.5 * transform, .5 * transform))
        x_data <- data.frame(x = c(median1, median1), y = c(0, .5 * transform))
    
        plotly_text <- 'Cumulative Probability'
        
        p1 <- p1 + geom_line(aes_string(y = paste0('..y.. * ', transform), text = 'plotly_text', label = '..y..'), stat='ecdf', size = 1.3) + 
            geom_line(data = y_data, aes(x = x, y = y), linetype = 'dotted') + #, color = '#33CCFF') + # horizontal line
            geom_line(data = x_data, aes(x = x, y = y), linetype = 'dotted') + #, color = '#33CCFF') + # vert line
            scale_y_continuous(breaks = round(seq(0, transform, transform/4), 0), # Main axis
                               minor_breaks = NULL,
                               labels = scales::comma,
                               sec.axis = sec_axis(~./transform, breaks = seq(0, 1, .25), 
                                                   name = "Cumulative Probability (line)", labels = scales::percent)) + # 2nd axis
            scale_x_continuous(breaks = seq((xmin - xmin %% .5), (xmax + xmax %% .5), .5), # x-axis breaks at .5
                               labels = scales::percent) +
            labs(x = 'Lift', y = 'Count (bar)') +
            theme_light()
        
        p1 <- ggplotly(p1, tooltip = c('plotly_text', 'Lift', 'count','label'), height = 540)
        
        median_control <- median(df()$Control)
        median_test <- median(df()$Test)
        
        p2 <- ggplot(df()) + 
            geom_histogram(aes(x = Control, fill = 'Control '), alpha = .5) +
            geom_histogram(aes(x = Test, fill = 'Test '), alpha = .5) + 
            geom_vline(xintercept = median_control, color = '#0072B2', linetype = 'dashed') +
            geom_vline(xintercept = median_test, color = '#D55E00', linetype = 'dashed') +
            labs(x = 'CTR', y = 'Count') +
            scale_fill_manual(name = NULL, guide = 'legend', 
                              values = c('Control ' = '#0072B2', 'Test ' = '#D55E00'), labels = c('Control ', 'Test ')) +
            scale_y_continuous(labels = scales::comma) +
            scale_x_continuous(labels = scales::percent) +
            theme_light()
        
        p2 <- ggplotly(p2, tooltip = c('Control', 'Test', 'count'))
        
        p3 <- ggplot(df()) + 
            geom_density(aes(x = Control, fill = 'Control ', color = 'Control '), alpha = .5) +
            geom_density(aes(x = Test, fill = 'Test ', color = 'Test '), alpha = .5) +
            geom_vline(xintercept = median_control, color = '#0072B2', linetype = 'dashed') +
            geom_vline(xintercept = median_test, color = '#D55E00', linetype = 'dashed') +
            labs(x = 'CTR', y = 'Density') +
            scale_fill_manual(name = NULL, guide = 'legend', 
                              values = c('Control ' = '#0072B2', 'Test ' = '#D55E00'), labels = c('Control ','Test ')) +
            scale_colour_manual(name = NULL, guide = 'legend',
                                values = c('Control ' = '#0072B2', 'Test ' = '#D55E00'), labels = c('Control ','Test ')) +
            scale_y_continuous(labels = scales::comma) +
            scale_x_continuous(labels = scales::percent) +
            theme_light()
        
        p3 <- ggplotly(p3, tooltip = c('Control', 'Test', 'count'))
        
        if(input$radio == 1){
            p1
        } else if(input$radio == 2){
            p2
        } else {
            p3
        }
        
        
    })
    
}

shinyApp(ui, server)

