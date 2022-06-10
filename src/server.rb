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
  @questionID =  params[:id]
  
  parameters = '?id=' + @questionID
  questionURL = BASE + parameters
  connection = Faraday.new(url: questionURL)
  response = connection.get
  session[:questionID] = @questionID

  
  @question = ''
  @answers = []
  @actual_question = session[:actual_question]
  @number_of_questions = session[:number_of_questions]
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
    @User = session[:User]
    @number_of_questions = session[:number_of_questions]
    @score = session[:score]    
  erb :checkResults
end

#Route for supporting function to correctly create the URL using the session
post'/submitAnswer' do
  @answer = params[:option]
  @questionID = session[:questionID]
    redirect '/checkAnswer/' + @questionID.to_s + '/' + @answer.to_s
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
  @actual_question = session[:actual_question]
  @number_of_questions = session[:number_of_questions]

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
post '/nextQuestion' do
    if !session[:listaPreguntas].empty? 
      @nextQuestion = session[:listaPreguntas].pop
      session[:actual_question] = session[:actual_question] + 1
      redirect '/quiz/' + @nextQuestion.to_s
    else
      redirect '/checkResults'
    end  

end

#Route that invokes a supporting function that does the apps setup
post'/iniciaQuiz' do
  number_of_questions = params[:customRange1]
  number_of_questions =Integer(number_of_questions)
  User = params[:idUser]
  session[:User] = User
  session[:number_of_questions] = number_of_questions
  session[:actual_question] = 1
  session[:score] = 0
  b = (0..49).to_a
  session[:listaPreguntas] = b.sample(number_of_questions)
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
    Username: session[:User],
    Right: session[:score],
    Total: session[:number_of_questions]
  }
  
  dynamodb.put_item(table_name: 'scores', item: new_item)
  
  redirect '/highscore'
  
end