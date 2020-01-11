require 'json'
require 'aws-sdk-dynamodb'

def lambda_handler(event:, context:)
  
  Aws.config[:region] = 'us-west-2'
  
  ddb = Aws::DynamoDB::Client.new
  ## Create the table if it doesn't exist
  begin
    ddb.describe_table(:table_name => "sunpower-energy-readings")
  rescue Aws::DynamoDB::Errors::ResourceNotFoundException
    ddb.create_table(
      :table_name => "sunpower-energy-readings",
      :attribute_definitions => [
        {
          :attribute_name => :DateTime,
          :attribute_type => :S
        },
      ],
      :key_schema => [
        {
          :attribute_name => :DateTime,
          :key_type => :HASH
        }
      ],
      :provisioned_throughput => {
        :read_capacity_units => 1,
        :write_capacity_units => 1,
      }
    )
    # wait for table to be created
      puts "waiting for table to be created..."
      ddb.wait_until(:table_exists, table_name: "sunpower-energy-readings")
      puts "table created!"
  end
  
  t = Time.now.strftime("%Y-%m-%dT%H:%I:%S")
  v = ENV["READING"]
  
  # Write a record
  item = {
   DateTime: t,
   Reading: v
  }
  ddb.put_item(:table_name => "sunpower-energy-readings", :item => item)
  
  {
    statusCode: 200,
    body: {
      message: item,
      # location: response.body
    }.to_json
  }
end
