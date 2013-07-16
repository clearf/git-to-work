require 'optparse'
require_relative '../../config/environment.rb'
require_relative './api_interface.rb'

# A hacked script to let us update one or all assignments
# Probably should replace with straight rake tasks at some point in time.

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"
  opts.on('--assignment=id', 'Parse data for a specific assignment') { |v| 
    options[:assignment] = v 
    options[:control] = "assignment"
  }
  opts.on('-v', '--verbose', 'verbose') { |v| options[:verbose] = v }
end.parse!


github_intf = GitHelper::ApiInterface.new({})

case options[:control]
when "assignment" 
  if options[:assignment]
    if options[:assignment].downcase == 'all'
      assignments = Assignment.all
      assignments.each do |assignment|
        github_intf.update_assignment(assignment)
      end
    else
      assignment=Assignment.where(id: options[:assignment].to_i).first
      github_intf.update_assignment(assignment)
    end
  end
end
