# Ruby app
# Date: June 1st, 2022
# Authors:  Eduardo Müller Romero
#           Sebastian Morales Martin

require 'json'
require 'aws-sdk-dynamodb'

# Constant containing a dynamo client instance
D_DB = Aws::DynamoDB::Client.new
# Constant that stores the name of the table used
TABLE = 'scores'

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

# Generates an object with all data in the dynamo table "scores" as a list
# Parameters: 
# 1. list:: entries in the table "scores"
# Output::  Object that includes all data entries in list format.
#           The list format comes as follows:
#           * User
#           * Correct_answers
#           * Total
#           * Time
def make_list(list)
    list.map do |item| {
        'User' => item['User'],
        'Correct' => item['Correct'].to_i,
        'Total' => item['Total'].to_i,
        'Time' => item['EndTimeStamp'].to_i - item['timeStamp'].to_i
    }
end
end

# Sort the items obtained from the table "scores"
# Parameters: 
# 1. list:: entries in the table "scores"
# Output:: All the entries in the table "scores" sorted
def sort(list)
    list.sort! {|a,b| a['Correct'] <=> b['Correct']}
    list.sort! {|a,b| a['Total'] <=> b['Total']}
end

# Get scores stored in the table "scores", sorts the items and prepares the format for a JSON response
# Output:: All entries in the table "scores" sorted and formatted
def get_and_prepare_data
    list = D_DB.scan(table_name: TABLE).items
    sort(list)
    make_list(list)
end

# Parses the JSON body given by the client to check if the parameters "User" and "timeStamp" exist within it.
# Parameters:
# 1. body:: Body of the client's request, expected to include "User" and "timeStamp", "endTimeStamp", "Correct", and "Total"
# Output:: Body formatted to be inserted into the table "scores" in the database.
def parse_req(body)
    if body
        begin
            data = JSON.parse(body)
            data.key?('User') and data.key?('timeStamp') ? data : nil
        rescue JSON::ParserError
            nil
        end
    else
        nil
    end
end

# Insert a row into the table "scores"
# Parameters: 
# 1. body:: JSON Body request from the client. expected to contain all the information needed:
#               * User
#               * timeStamp
#               * endTimeStamp
#               * Correct
#               * Total
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
# Output:: A response with HTTP code 200 and all the content in the table "scores"
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
    HTTP_method = event.dig('requestContext', 'http', 'method')
    case HTTP_method
    when 'GET'
        handle_get
    when 'POST'
        if insert_data_to_table(event['body'])
            handle_post
        else
            handle_bad_req
        end
    else
        handle_bad_method(HTTP_method)
    end
end



