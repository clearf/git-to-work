class Assignment < ActiveRecord::Base
  include GitHelper

  has_many :contributions
  has_many :students, :through => :contributions

  after_save :update_assignment


  private
  

  def update_assignment
    # This API call takes a moment to run. It would be nice if it ran in some safe multithreaded environment
    # and wouldn't hang our app.
    # It'd be nice if I owned a pony, also. 
    github_intf = GitHelper::ApiInterface.new({})
    github_intf.update_assignment(self)
  end
end
