require 'github_api'

module GitHelper
  class APIInterface
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
end
