#setwd("C:/Users/Install/Desktop/R-dashboard")
######################################################################
######################################################################
# Word cloud Shiny app
######################################################################
######################################################################
library(shiny)
library(ggplot2)
library(colourpicker)
library(wordcloud2)
library(wordcloud)
library(tm)
######################################################################
# Function create_wordcloud()
######################################################################
create_wordcloud <- function(data, num_words = 100, background = "white") {
  
  # If text is provided, convert it to a dataframe of word frequencies
  if (is.character(data)) {
    corpus <- Corpus(VectorSource(data))
    corpus <- tm_map(corpus, tolower)
    corpus <- tm_map(corpus, removePunctuation)
    corpus <- tm_map(corpus, removeNumbers)
    corpus <- tm_map(corpus, removeWords, stopwords("english"))
    tdm <- as.matrix(TermDocumentMatrix(corpus))
    data <- sort(rowSums(tdm), decreasing = TRUE)
    data <- data.frame(word = names(data), freq = as.numeric(data))
  }
  
  # Make sure a proper num_words is provided
  if (!is.numeric(num_words) || num_words < 3) {
    num_words <- 3
  }  
  
  # Grab the top n most common words
  data <- head(data, n = num_words)
  if (nrow(data) == 0) {
    return(NULL)
  }
  
  wordcloud2(data, backgroundColor = background)
}

######################################################################
# Word cloud Shiny app
######################################################################

# Define UI for the application
ui <- fluidPage(
  h1("Word Cloud"),
  # Add the word cloud output placeholder to the UI
  wordcloud2Output(outputId = "cloud")
)

# Define the server logic
server <- function(input, output) {
  # Render the word cloud and assign it to the output list
  output$cloud <- renderWordcloud2({
    # Create a word cloud object
    create_wordcloud(artofwar)
  })
}

# Run the application
shinyApp(ui = ui, server = server)


######################################################################
# Upload a text file (server)
######################################################################
ui <- fluidPage(
  h1("Word Cloud"),
  sidebarLayout(
    sidebarPanel(
      textAreaInput("text", "Enter text", rows = 7),
      fileInput("file", "Select a file"),
      numericInput("num", "Maximum number of words",
                   value = 100, min = 5),
      colourInput("col", "Background colour", value = "white")
    ),
    mainPanel(
      wordcloud2Output("cloud")
    )
  )
)

server <- function(input, output) {
  # Define a reactive variable named `input_file`
  input_file <- reactive({
    if (is.null(input$file)) {
      return("")
    }
    # Read the text in the uploaded file
    readLines(input$file$datapath)
  })
  
  output$cloud <- renderWordcloud2({
    # Use the reactive variable as the word cloud data source
    create_wordcloud(data = input_file(), num_words = input$num,
                     background = input$col)
  })
}

shinyApp(ui = ui, server = server)


######################################################################
# Choose the data source (ui)
######################################################################

ui <- fluidPage(
  h1("Word Cloud"),
  sidebarLayout(
    sidebarPanel(
      radioButtons(
        inputId = "source",
        label = "Word source",
        choices = c(
          "Art of War" = "book",
          "Use your own words" = "own",
          "Upload a file" = "file"
        )
      ),
      textAreaInput("text", "Enter text", rows = 7),
      fileInput("file", "Select a file"),
      numericInput("num", "Maximum number of words",
                   value = 100, min = 5),
      colourInput("col", "Background colour", value = "white")
    ),
    mainPanel(
      wordcloud2Output("cloud")
    )
  )
)

server <- function(input, output) {
  # Create a "data_source" reactive variable
  data_source <- reactive({
    # Return the appropriate data source depending on
    # the chosen radio button
    if (input$source == "book") {
      data <- artofwar
    } else if (input$source == "own") {
      data <- input$text
    } else if (input$source == "file") {
      data <- input_file()
    }
    return(data)
  })
  
  input_file <- reactive({
    if (is.null(input$file)) {
      return("")
    }
    readLines(input$file$datapath)
  })
  
  output$cloud <- renderWordcloud2({
    # Use the data_source reactive variable as the data
    # in the word cloud function
    create_wordcloud(data = data_source(), num_words = input$num,
                     background = input$col)
  })
}

shinyApp(ui = ui, server = server)



######################################################################
# Conditionally show or hide required inputs
######################################################################
ui <- fluidPage(
  h1("Word Cloud"),
  sidebarLayout(
    sidebarPanel(
      radioButtons(
        inputId = "source",
        label = "Word source",
        choices = c(
          "Art of War" = "book",
          "Use your own words" = "own",
          "Upload a file" = "file"
        )
      ),
      conditionalPanel(
        condition = "input.source == 'own'",
        textAreaInput("text", "Enter text", rows = 7)
      ),
      # Wrap the file input in a conditional panel
      conditionalPanel(
        # The condition should be that the user selects
        # "file" from the radio buttons
        condition = "input.source == 'file'",
        fileInput("file", "Select a file")
      ),
      numericInput("num", "Maximum number of words",
                   value = 100, min = 5),
      colourInput("col", "Background colour", value = "white")
    ),
    mainPanel(
      wordcloud2Output("cloud")
    )
  )
)

server <- function(input, output) {
  data_source <- reactive({
    if (input$source == "book") {
      data <- artofwar
    } else if (input$source == "own") {
      data <- input$text
    } else if (input$source == "file") {
      data <- input_file()
    }
    return(data)
  })
  
  input_file <- reactive({
    if (is.null(input$file)) {
      return("")
    }
    readLines(input$file$datapath)
  })
  
  output$cloud <- renderWordcloud2({
    create_wordcloud(data_source(), num_words = input$num,
                     background = input$col)
  })
}

shinyApp(ui = ui, server = server)



######################################################################
# Create a new word cloud on demand
######################################################################



ui <- fluidPage(
  h1("Word Cloud"),
  sidebarLayout(
    sidebarPanel(
      radioButtons(
        inputId = "source",
        label = "Word source",
        choices = c(
          "Art of War" = "book",
          "Use your own words" = "own",
          "Upload a file" = "file"
        )
      ),
      conditionalPanel(
        condition = "input.source == 'own'",
        textAreaInput("text", "Enter text", rows = 7)
      ),
      conditionalPanel(
        condition = "input.source == 'file'",
        fileInput("file", "Select a file")
      ),
      numericInput("num", "Maximum number of words",
                   value = 100, min = 5),
      colourInput("col", "Background colour", value = "white"),
      # Add a "draw" button to the app
      actionButton(inputId = "draw", label = "Draw!")
    ),
    mainPanel(
      wordcloud2Output("cloud")
    )
  )
)

server <- function(input, output) {
  data_source <- reactive({
    if (input$source == "book") {
      data <- artofwar
    } else if (input$source == "own") {
      data <- input$text
    } else if (input$source == "file") {
      data <- input_file()
    }
    return(data)
  })
  
  input_file <- reactive({
    if (is.null(input$file)) {
      return("")
    }
    readLines(input$file$datapath)
  })
  
  output$cloud <- renderWordcloud2({
    # Add the draw button as a dependency to
    # cause the word cloud to re-render on click
    input$draw
    isolate({
      create_wordcloud(data_source(), num_words = input$num,
                       background = input$col)
    })
  })
}

shinyApp(ui = ui, server = server)