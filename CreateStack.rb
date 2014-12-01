require 'json'
require 'aws-sdk'

AWS.config(JSON.parse(File.read('config/aws_credentials.json'), :symbolize_names => true) )

ARGV.each do |filename|
  begin
    options = JSON.parse(File.read(filename))
    template = File.read(options["template_location"])
    cfn = AWS::CloudFormation.new(:region=>options["region"])
    statuses = [:create_complete, :update_complete, :update_rollback_complete]
    AWS.memoize do
      stack_exists = false
      cfn.stacks.with_status(statuses).each do |stack|
        if options["stack_name"]==stack.name
          stack_exists=true
          puts "#{stack.name} already exists in #{options["region"]}, attempting to update..."
          stack.update(:template=>template,:parameters=>options["parameters"])
        break
        end
      end
      if !stack_exists
        puts "Attempting to create #{options["stack_name"]} in #{options["region"]}..."
        cfn.stacks.create(options["stack_name"], template, :parameters=>options["parameters"])
      end
    end
  rescue Exception => e
    puts "Error Updating or creating #{filename}"
    puts e
  end
end

