desc "This task is called by the Heroku scheduler add-on"
task :update_github_assignments => :environment do
  puts "Updating github assignments..."
    `ruby lib/github/git_info.rb --assignment=all`
  end

task :load_students => :environment do
  puts "Load students from a file..."
    `ruby lib/github/git_info.rb --students lib/github/students.txt`
  end
