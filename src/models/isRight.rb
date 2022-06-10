# Final Project: Quiz Application with Microservices
# Date: 1-June-2022
# Authors: 
#
#          Sebastian Morales Martin         A01376228
#          Eduardo Roberto Müller Romero    A01745219

require 'json'
require 'yaml'

# Constant where the answers will be stored
ANSWER_SET = YAML.load_file('answers.yaml')

# Generates an url via string format
# Parameters:
# 1. host:: Host of the service
# 2. path:: Host path
# 3. index:: Index of the question in the array.
def make_url(host, path, index)
    "https://#{host}#{path}?id=#{index}&answer=#{answer}"
end 

# Generates de response for the lambda handler.
# Parameters:
# 1. id:: Id of the question being checked.
# 2. answer:: Answer submitter by the user to be reviewed.
# Output:: Object with the HTTP status code and a JSON body including the question id, correct answer check, and the question.
def check_res_id(id, answer)
    if ANSWER_SET[id]['answer'] == answer.to_i
        response(200, {id: id, isRight: true, correct: ANSWER_SET[id]['completeAnswer'], question: ANSWER_SET[id]['question']})
    else 
        response(200, {id: id, isRight:false, correct: ANSWER_SET[id]['completeAnswer'], question: ANSWER_SET[id]['question']})
    end 
end

# Generates a response for the lambda handler
# Parameters: 
# 1. status:: HTTP Status code that will indicate if the transaction was succesful or an error otherwise.
# 2. body:: JSON response that includes the question or an error detailing what happened.
# Output::  Object with the HTTP status code and a JSON bodt that contains the output in
#           +check_res_id(id, answer)+ or an error otherwise.
def response(status, body)
    {
        statusCode: status,
        headers: {
      "Content-Type" => "application/json; charset=utf-8"
    },
    body: JSON.generate(body)
    }
end

# Lambda handler for the client's requests based on the HTTP method used and the parameters sent.
# Parameters: 
# 1. event:: HTTP method including the parameters.
# Output::  Object containing the HTTP Status code and a JSON body that conrains the output in
#           +check_res_id(id, answers)+ or an error.
def lambda_handler(event:, context:)
    method = event.dig('requestContext', 'http', 'method')
    case method
    when 'GET'
        query = event['queryStringParameters'] || {}
        if query['id']
            id = query['id'].to_i
            if 0 <= id and id < ANSWER_SET.size
                answer = query['answer']
                if answer.length > 0
                    check_res_id(id, answer)
                else 
                    response(404, {error: "answer is empty."})
                end
            else 
                response(404, {error: "The id #{id} was not found"})
            end
        else
            response(405, {error: "Method #{method} not allowed."})
        end
    end
end
