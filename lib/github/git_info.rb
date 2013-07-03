require 'github_api'
require 'optparse'
require_relative '../../config/environment.rb'

class StudentImporter
  def initialize(filename=nil, course=nil)
    @filename = filename ||'students.txt'
    @students = {}
    @course = course  || 'WDI June 2013'
  end

  def add_students_to_db()
    if @students.empty?
      parse_students_file
    end
    @students.each do |github_login, student_profile| 
      student = Student.where(github_login: github_login).first_or_initialize
      student.update_attributes(github_login: github_login, name: student_profile[:name], 
                                email: student_profile[:email], course: @course)
    end
  end

  private

  def parse_students_file()
    student_data = File.new(@filename)
    student_data.each do |line|
      data = line.chomp.split('|')
      @students[data[0]]={name: data[1], email: data[2]}
    end
  end
end

class GithubInterface
  attr_accessor :options
  attr_reader :github, :collaborators
  
  def initialize(options)
    @github = Github.new do |config|
      config.client_id = ENV['GIT_CLIENT_ID']
      config.client_secret = ENV['GIT_CLIENT_SECRET']
      config.oauth_token = ENV['GIT_TOKEN']
      config.scopes      = ['public_repo']
      config.endpoint    = 'https://api.github.com'
      config.site        = 'https://github.com'
      config.adapter     = :net_http
      config.ssl         = {:verify => false}
    end
    @options = options
    @collaborators = {}
  end
  
  def process_pull_requests(owner, repo)
    pull_requests = []
    @collaborators[key(owner,repo)] = []
    begin 
      pull_requests << (@github.pull_requests.list owner, repo, "state" => "closed")
      pull_requests << (@github.pull_requests.list owner, repo)
    rescue Github::Error::NotFound
      puts "Missing repository #{repo} for user #{owner}"
    rescue Github::Error::Forbidden
      abort "Forbidden: Too many api calls. Perhaps your API KEY environment variables are not initialized?"
    end
    pull_requests.flatten!
    pull_requests.each do |pull_request| 
      repo_name = pull_request['head']['repo']['name']
      repo_owner = pull_request['head']['repo']['owner']['login']
      begin
        repo_collaborator_list = @github.repos.collaborators.list(repo_owner, repo_name)
        repo_collaborator_list.body.each do |collaborator| 
          collaborator = {github_login: collaborator['login'], 
            created_at: pull_request['created_at'], 
            updated_at: pull_request['updated_at'], 
            status: pull_request['state'], 
            url: pull_request['html_url'] 
          }
          @collaborators[key(owner,repo)] << collaborator
        end
      rescue Github::Error::NotFound
        puts "Missing repository #{repo} for user #{owner}"
      rescue Github::Error::Forbidden
        abort "Forbidden: Too many api calls. Perhaps your API KEY environment variables are not initialized?"
      end
    end 
  end
  
  def key(owner,name)
    return "#{owner}/#{name}"  
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"
  opts.on('--assignment=id', 'Parse data for a specific assignment') { |v| 
    options[:assignment] = v 
    options[:control] = "assignment"
  }
  opts.on('--students [filename]', 'Parse data for a specific assignment') { |v| options[:control] = "students"; options[:students_file] = v }
  opts.on('-v', '--verbose', 'verbose') { |v| options[:verbose] = v }
end.parse!

github_intf = GithubInterface.new(options)

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
when "students"
  student_importer = StudentImporter.new(options[:students_file])
  student_importer.add_students_to_db
end
