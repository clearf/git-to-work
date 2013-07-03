desc "This task is called by the Heroku scheduler add-on"
task :update_github_assignments => :environment do
  puts "Updating github assignments..."
    `ruby lib/github/git_info --assignment=all`
  end
