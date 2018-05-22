
library(DT)
library(shiny)
library(shinydashboard)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(plotly)
library(scales)

#### Shiny UI ####

header <- dashboardHeader(title = "BigTimeStats A/B Testing App", titleWidth = 300)
                          
sidebar <- dashboardSidebar(disable = TRUE)

body <- dashboardBody(
    
    fluidRow(
        column(width = 2,
            box(title = 'Directions',
                status = "warning", solidHeader = TRUE,
                p('1. Start by selecting your click thoughts (successes) for your control/test groups.'),
                p('2. Next, select the # of Trials (i.e. impressions).'),
                p('3. If you have CTR:'),
                p('# of Successes = CTR * # of Trials'),
                p('4. If you have prior knowledge about the success of the test, input it under ', strong('Prior'),
                  ' in the ', strong('Simulation'), ' section'),
                p('5. Adjust # of Simulations for better results. Higher number results in increased processing but slightly more accuracy'),
                p('6. Click on Run (few sec)'),
                # p('-------------'),
                p('Made by Adam Vagner'),
                p(a("LinkedIn", href="https://www.linkedin.com/in/adamvagner/", target="_blank")),
                p(a("Blog", href="https://bigtimestats.wordpress.com", target="_blank")),
                p('See', a("Source Code", href="https://github.com/BigTimeStats/AB-Testing-Shiny-Bayes", target="_blank"), 'for more info on outputs'),
                p('Based on work at: ',a("Count Bayesie", href="https://www.countbayesie.com/blog/2015/4/25/bayesian-ab-testing", target="_blank")),
                
                width = NULL
            )
        ),
        
        column(width = 4,
               
               fluidRow(
                   column(width = 6,
                        box(title = 'Control Inputs',
                            status = "danger", solidHeader = TRUE,
                            
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
                               
                               numericInput("test.success", 
                                            p("# of Successes"), 
                                            value = 15),
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
                              
                              h3('Prior'),
                              
                              helpText('Leave as 0 if no information is available'),
                              
                              numericInput("prior.success", 
                                           p("# of Successes"), 
                                           value = 0),
                              numericInput("prior.trials", 
                                           p("# of Trials"), 
                                           value = 0),
                              br(),
                              numericInput("ntrials", 
                                           p("# of Simulations"), 
                                           value = 10000),
                              
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
                           plotlyOutput('plotly', height = '509px'),
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
    
    # Take a reactive dependency on input$button, but
    # not on any of the stuff inside the function
    df <- eventReactive(input$button, {
        
        n.trials <- input$ntrials
        prior.alpha <- input$prior.success
        prior.beta <- input$prior.trials - prior.alpha
        
        a.success <- input$control.success
        a.failure <- input$control.trials - a.success # Total views/impressions (denominator) minus success
        
        b.success <- input$test.success
        b.failure <- input$test.trials - b.success
        
        # Sample from beta distribution based on results
        a.samples <- rbeta(n.trials, a.success + prior.alpha, a.failure + prior.beta)
        b.samples <- rbeta(n.trials, b.success + prior.alpha, b.failure + prior.beta)
        
        df <- data.frame(Lift = b.samples/a.samples - 1)
        
        # Remove extreme outliers for nicer plot
        outlier_values <- boxplot.stats(df$Lift, coef = 3)$out
        df <- df %>% filter(!Lift %in% outlier_values)
        
        
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
        
        z_score <- abs((a.success / (a.success + a.failure)) - (b.success / (b.success + b.failure)) - 0) /
            sqrt((p_hat)*(1 - p_hat)*(1/(a.success + a.failure) + 1/(a.success + a.failure))) 
        
        pnorm(z_score, lower.tail = FALSE) 
        
    })
    
    output$ttest <- renderText({
        
       pvalue()
        
    })
    
    output$plotly <- renderPlotly({
            
        # ggplot base histogram
        p <- ggplot(df(), aes(x = Lift)) + geom_histogram(fill = 'grey50', alpha = .6, bins = 30)
        
        # Extract out ggplot data object for 2nd axis transformation
        ggplot_df <- ggplot_build(p)$data[[1]]
        
        transform <- max(ggplot_df$ymax)
        
        xmin <- min(ggplot_df$x)
        xmax <- max(ggplot_df$x)
    
        plotly_text <- 'Cumulative Probability'
        
        p <- p + geom_line(aes_string(y = paste0('..y.. * ', transform), text = 'plotly_text', label = '..y..'), stat='ecdf', size = 1.3) + 
            geom_vline(xintercept = 0, linetype = 'dashed') +
            geom_hline(yintercept = .5 * transform, linetype = 'dotted') +
            scale_y_continuous(breaks = round(seq(0, transform, transform/4),0), # Main axis
                               minor_breaks = NULL,
                               labels = scales::comma,
                               sec.axis = sec_axis(~./transform, breaks = seq(0, 1, .25), 
                                                   name = "Cumulative Probability (line)", labels = scales::percent)) + # 2nd axis
            scale_x_continuous(breaks = seq((xmin - xmin %% .5 + .5), (xmax + xmax %% .5), .5), # x-axis breaks at .5
                               labels = scales::percent) +
            labs(x = 'Lift', y = 'Count (bar)') +
            theme_light()
        
        ggplotly(p, tooltip = c('plotly_text', 'Lift', 'count','label'), height = 509)
        
    })
    
}

shinyApp(ui, server)

