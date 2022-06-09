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

# The +HTTP_Status+ class represents all possible status in the program