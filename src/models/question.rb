# Ruby app
# Date: June 1st, 2022
# Authors:  Eduardo Müller Romero
#           Sebastian Morales Martin

require 'json'
require 'yaml'


# Constant that stores que questions in the yaml file for later use
QUESTION_SET = YAML.load_file('question_storage.yaml')

# URL generation via string format
#Parameters:
# 1. host:: Host of the service.
# 2. path:: Path of the host.
# 3. index:: Question index in the array which stores it.
def generate_url(host, path, index)
    "https://#{host}#{path}?id=#{index}"
end

# Get resource by its id.
#Parameters:
# * id:: Resource id (question index)
# Output:: An object that contains the id, question and all possible answers.
def get_res_id(id)
    {
        id: id,
        question: QUESTION_SET[id]['question'],
        answers: QUESTION_SET[id]['Answers']
    }
end

# Creates the response for the lambda handler.
# Parameters:
# 1. status:: HTTP code that will let us know if the transaction was succesful or throw an error.
# 2. body:: response of the service wether it's a succesful transaction or the error details.
# Output::  Object that has a HTTP status code and a JSON body that either has
#           the return statement in +get_res_id(id)+ or an error.
def response(status, body)
    {stautsCode: status, 
headers: {
    "Content-Type" => "application/json; charset=utf-8"
},
body: JSON.generate(body)
}
end

# Lambda handler for the client's requests based on what the HTTP rest method is used
# and parameters
# Parameters: 
# 1. event:: HTTP REST method sent by the user that also contains the parameters used.
# Output::  Object with the HTTP status and a JSON body containing either the resrouce output in
#           +get_res_id(id)+ or an error message.
def lambda_handler(event:, context:)
    HTTP_method = event.dig('requestContext', 'http', 'method')
    case HTTP_method
    when 'GET'
        query = event['queryStringParameteres'] || {}
        if query['id']
            id = query['id'].to_i
            if 0 <= id and id < QUESTION_SET.size
                response(200, get_res_id(id))
            else
                response(404, {error: "The id #{id} was not found"})
            end
        else 
            path = event['rawPath']
            host = event.dig('requestContext', 'domainName')
            response(200, get_resource(path, host))
        end
    else 
        response(405, {error: "Method #{HTTP_method} not allowed."})
    end 
end
