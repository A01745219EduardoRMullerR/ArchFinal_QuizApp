# Final Project: Quiz Application with Microservices
# Date: 1-June-2022
# Authors: 
#
#          Sebastian Morales Martin         A01376228
#          Eduardo Roberto Müller Romero    A01745219

require 'json'
require 'aws-sdk-dynamodb'

# Constant containing a dynamo client instance
D_DB = Aws::DynamoDB::Client.new
# Constant that stores the name of the table used
TABLE = 'hallOfFame'

# The +HTTP_Status+ class represents all possible status in the program.
class HTTP_Status
    # OK
    OK = 200
    # Created
   CREATED = 201
   # Bad request
   BAD_REQUEST = 400
   # Method is not allowed
   METHOD_NOT_ALLOWED = 405
end

# Generates a response for the lambda handler
# Parameters: 
# 1. status:: HTTP Status code that will indicate if the transaction was succesful or an error otherwise.
# 2. body:: JSON response that includes the question or an error detailing what happened.
# Output:: Object that includes the status code and a JSON response or an error.
def response(status, body)
    {
        statusCode: status,
        headers: {
      "Content-Type" => "application/json; charset=utf-8"
    },
    body: JSON.generate(body)
    }
end

# Generates an object with all data in the dynamo table "hallOfFame" as a list
# Parameters: 
# 1. list:: entries in the table "hallOfFame"
# Output::  Object that includes all data entries in list format.
#           The list format comes as follows:
#           * user
#           * score
#           * nQuestions
def make_list(list)
    list.map do |item| {
        'user' => item['user'],
        'score' => item['score'],
        'nQuestions' => item['nQuestions']
    }
end
end

# Sort the items obtained from the table "hallOfFame"
# Parameters: 
# 1. list:: entries in the table "hallOfFame"
# Output:: All the entries in the table "hallOfFame" sorted
def sort(list)
    list.sort! {|a,b| a['score'] <=> b['score']}
    list.sort! {|a,b| a['nQuestions'] <=> b['nQuestions']}
end

# Get hallOfFame stored in the table "hallOfFame", sorts the items and prepares the format for a JSON response
# Output:: All entries in the table "hallOfFame" sorted and formatted
def get_and_prepare_data
    list = D_DB.scan(table_name: TABLE).items
    sort(list)
    make_list(list)
end

# Parses the JSON body given by the client to check if the parameters "user" and "timeStamp" exist within it.
# Parameters:
# 1. body:: Body of the client's request, expected to include "user", "score", and "nQuestions"
# Output:: Body formatted to be inserted into the table "hallOfFame" in the database.
def parse_req(body)
    if body
        begin
            data = JSON.parse(body)
            data.key?('user')
        rescue JSON::ParserError
            nil
        end
    else
        nil
    end
end

# Insert a row into the table "hallOfFame"
# Parameters: 
# 1. body:: JSON Body request from the client. expected to contain all the information needed:
#               * user
#               * score
#               * nQuestions
def insert_data_to_table(body)
    data = parse_req(body)
    if data
        D_DB.put_item(table_name: TABLE, item: data)
        true
    else 
        false
    end
end

# Handles 'GET' methods
# Output:: A response with HTTP code 200 and all the content in the table "hallOfFame"
def handle_get
    response(HTTP_Status::OK, get_and_prepare_data)
end

# Handles 'POST' methods
# Output:: A response with HTTP code 201 if the data was succesfully inserted
def handle_post
    response(HTTP_Status::CREATED, {message: 'Data uploaded.'})
end

# Handles any unsuccesful request to insert data
# Output:: A response with HTTP code 400 with a message informing that something went wrong.
def handle_bad_req
    response(HTTP_Status::BAD_REQUEST, {message: 'Something went wrong (invalid input).'})
end

# Handles unsuccesful request to insert data
# Output:: A responde with HTTP code 400 with a message informing that something went wrong.
def handle_bad_method
    response(HTTP_Status::METHOD_NOT_ALLOWED, {message: "Something went wrong. (Method #{method} not allowed)"})
end

# Lambda handler for the client's requests based on the HTTP method used and the parameters sent.
# Parameters: 
# 1. event:: HTTP method including the parameters.
# Output:: Object that has the HTTP status code and a JSON response which could either be a notificarion or an error.
def lambda_handler(event:, context:)
    method = event.dig('requestContext', 'http', 'method')
    case method
    when 'GET'
        handle_get
    when 'POST'
        if insert_data_to_table(event['body'])
            handle_post
        else
            handle_bad_req
        end
    else
        handle_bad_method(method)
    end
end



