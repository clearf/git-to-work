require 'github_api'
require 'optparse'
require 'pry'
require_relative '../../config/environment.rb'



def parse_students(filename=nil)
  students={}
  filename ||='students.txt'
  student_data = File.new(filename)
  student_data.each do |line| 
    data = line.chomp.split('|')
    students[data[0]]={name: data[1], email: data[2]}
  end
  return students
end
students = parse_students

def parse_assignments_file(filename=nil)
  # Parse assignments file 
  assignments=[]
  filename ||='homework_assignments.txt'
  homework_strings = File.new(filename)
  homework_strings.each do |line| 
    login, repo = line.split('/')
    if login and repo
      assignments << {login: login, repo:repo}
    end
  end
  return assignments
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"
  opts.on('--summary', 'print out a summary') { options[:control] = "summary" }
  opts.on('--assignment', 'drill down into a specific assignment') { options[:control] = "assignment" }
  opts.on('-v', '--verbose', 'verbose') { |v| options[:verbose] = v }
end.parse!

class GithubInterface
  attr_accessor :students, :options
  attr_reader :github

  def initialize(options, students={})
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
    @students = students
    @options = options
    @collaborators = {}
    @missing_students = {}
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
      abort "Forbidden: Too many api calls. Perhaps your API KEY environment variables aren't initialized?"
    end
    pull_requests.flatten!
    pull_requests.each do |pull_request| 
      repo_name = pull_request['head']['repo']['name']
      repo_owner = pull_request['head']['repo']['owner']['login']
      begin
        repo_collaborator_list = @github.repos.collaborators.list(repo_owner, repo_name)
        repo_collaborator_list.body.each do |collaborator| 
          @collaborators[key(owner,repo)] << collaborator['login']
        end
      rescue Github::Error::NotFound
        puts "Missing repository #{repo} for user #{owner}"
      rescue Github::Error::Forbidden
        abort "Forbidden: Too many api calls. Perhaps your API KEY environment variables aren't initialized?"
      end
    end 
    @missing_students[key(owner,repo)]= (@students.keys) - @collaborators[key(owner, repo)]
  end

  def missing_students(login,repo)
    unless @missing_students[key(login,repo)]
      self.process_pull_requests(login,repo)
    end
    return @missing_students[key(login,repo)]
  end

  def print_missing_students(login, repo, verbose = nil) 
    missing_students = self.missing_students(login,repo)
    if missing_students.length > 0 
      puts "******************"
      puts "#{repo}"
      if verbose || self.verbose?
        puts "#{missing_students.length} student(s) not turned in" 
        puts "******************"
        missing_students.each do |missing_student| 
          puts "#{students[missing_student][:name]} <#{students[missing_student][:email]}>"
        end
        puts "******************"
      else
        puts "Missing #{missing_students.length} assignments"
      end
    end
  end
  
  def verbose?
    @options[:verbose]
  end

  def key(owner,name)
    return "#{owner}/#{name}"
  end
end


github_intf = GithubInterface.new(options, students)


case github_intf.options[:control]
when 'assignment'
  assignments = parse_assignments_file
  puts "Choose assignment"
  assignments.each_with_index do |assignments, index|
    puts "#{index+1}) #{assignments[:login]}/#{assignments[:repo]}"
  end
  assignment = gets.chomp.to_i
  owner = assignments[assignment-1][:login] 
  repo = assignments[assignment-1][:repo] 
  github_intf.process_pull_requests(owner, repo)
  github_intf.print_missing_students(owner,repo, true)
when "summary"
  assignments = parse_assignments_file
  assignments.each do |assignment| 
    owner = assignment[:login] 
    repo = assignment[:repo] 
    github_intf.print_missing_students(owner,repo)
    missing_students = github_intf.missing_students(owner, repo)
    missing_students.each do |student|
      unless github_intf.students[student][:missing_assignments]
        github_intf.students[student][:missing_assignments]=[]
      end
      github_intf.students[student][:missing_assignments] << "#{owner}/#{repo}"
    end
  end
  
  
  sorted_students = github_intf.students.sort_by do |login, student| 
    if student[:missing_assignments]
      student[:missing_assignments].length
    else
      0
    end
  end
  sorted_students.reverse!
  
  sorted_students.each_with_index do |(login, student), index|
    if student[:missing_assignments]
      puts "#{index}) #{student[:name]}, <#{student[:email]}>, #{student[:missing_assignments].length} / #{assignments.length}"
    end
  end
end
