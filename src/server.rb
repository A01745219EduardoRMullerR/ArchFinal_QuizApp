# Final Project: Quiz Application with Microservices
# Date: 1-June-2022
# Authors: 
#
#          Sebastian Morales Martin         A01376228
#          Eduardo Roberto Müller Romero    A01745219

require 'json'
require 'faraday'
require 'sinatra'
require 'aws-sdk-dynamodb'

#Allows for sessions to be used by server.rb
enable :sessions

#Home route, shows the index
get '/' do
  erb :index
end

#Route for the questions, retrieves the questions from aws
# Parameters::
#   id:: The id of the question that will be retrieved from aws
get '/quiz/:id' do
  @idPregunta =  params[:id]
  
  parameters = '?id=' + @idPregunta
  questionURL = BASE + parameters
  connection = Faraday.new(url: questionURL)
  response = connection.get
  session[:idPregunta] = @idPregunta

  
  @question = ''
  @answers = []
  @preguntaActual = session[:preguntaActual]
  @cantidadPreguntas = session[:cantidadPreguntas]
  if response.success?
    data = JSON.parse(response.body)
    puts data
    @question = data['question']
    @answers = data['answers']
  end
  erb :quiz
end

#Route that shows the final results of a quiz attempt
get '/checkResults' do
    @usuario = session[:usuario]
    @cantidadPreguntas = session[:cantidadPreguntas]
    @score = session[:score]    
  erb :checkResults
end

#Route for supporting function to correctly create the URL using the session
post'/submitAnswer' do
  @answer = params[:option]
  @idPregunta = session[:idPregunta]
    redirect '/checkAnswer/' + @idPregunta.to_s + '/' + @answer.to_s
end

#Route that invokes the screen where the user receives feedback
# Parameters::
#   id:: The id of the question that will be checked from aws
#   answer:: The answer the user choose
get'/checkAnswer/:id/:answer' do
  parameters = '?id=' + params[:id] + "&answer=" + params[:answer] 
  questionURL = lambdaCheckAnswer + parameters
  connection = Faraday.new(url: questionURL)
  response = connection.get
  @question = ""
  @rightData = ""
  @correct = ""
  @preguntaActual = session[:preguntaActual]
  @cantidadPreguntas = session[:cantidadPreguntas]

  if response.success?
    data = JSON.parse(response.body)
    puts data
    @question = data['question']
    @rightData = data['right']
    @correct = data['correct']
  end
  
  if @rightData
    session[:score] = session[:score] + 1
  end
    erb :checkAnswer 
end

#Route for supporting function that has the logic to know when the user has answered all the questions
post '/siguientePregunta' do
    if !session[:listaPreguntas].empty? 
      @siguientePregunta = session[:listaPreguntas].pop
      session[:preguntaActual] = session[:preguntaActual] + 1
      redirect '/quiz/' + @siguientePregunta.to_s
    else
      redirect '/checkResults'
    end  

end

#Route that invokes a supporting function that does the apps setup
post'/iniciaQuiz' do
  cantidadPreguntas = params[:customRange1]
  cantidadPreguntas =Integer(cantidadPreguntas)
  usuario = params[:idUsuario]
  session[:usuario] = usuario
  session[:cantidadPreguntas] = cantidadPreguntas
  session[:preguntaActual] = 1
  session[:score] = 0
  b = (0..49).to_a
  session[:listaPreguntas] = b.sample(cantidadPreguntas)
  primerPregunta = session[:listaPreguntas].pop
  puts session[:horaInicio]
  redirect '/quiz/' + primerPregunta.to_s
end

#Route thatt invokes the highscore screen
get'/highscore' do
    connection = Faraday.new(url:lambdaHighscore)
    response = connection.get
    @highscores = []
    
    if response.success?
      @highscores = JSON.parse(response.body)
    end
    puts @highscores
    erb :highscore
end

#Route that invokes lambda to upload the user score 
post '/postHighscore' do
  dynamodb = Aws::DynamoDB::Client.new
  
  new_item = {
    Username: session[:usuario],
    Right: session[:score],
    Total: session[:cantidadPreguntas]
  }
  
  dynamodb.put_item(table_name: 'HighScores', item: new_item)
  
  redirect '/highscore'
  
end