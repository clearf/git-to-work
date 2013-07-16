require 'optparse'
require_relative '../../config/environment.rb'
require_relative './git_intf.rb'

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


github_intf = GitHelper::APIInterface.new(options)

def update_assignment(assignment, github_intf)
  login, repo = assignment[:github_login], assignment[:github_repo]
  github_intf.process_pull_requests(login, repo)

  # Clear old assignments out
  assignment.students.clear

  students = []
  github_intf.collaborators[github_intf.key(login,repo)].each do |collaborator|
    student = Student.where(github_login: collaborator[:github_login]).first
    if student
      assignment.students << student
      # Get the contribution that was just created
      contribution = assignment.contributions.last
      contribution.update_attributes(url: collaborator[:url], 
                                     contribution_created_at: collaborator[:created_at], 
                                     contribution_updated_at: collaborator[:updated_at], 
                                     status: collaborator[:status] ) 
    end
  end
end

case options[:control]
when "assignment" 
  if options[:assignment]
    if options[:assignment].downcase == 'all'
      assignments = Assignment.all
      assignments.each do |assignment|
        update_assignment(assignment, github_intf)
      end
    else
      assignment=Assignment.where(id: options[:assignment].to_i).first
      update_assignment(assignment, github_intf)
    end
  end
end
