class Assignment < ActiveRecord::Base
  has_many :contributions
  has_many :students, :through => :contributions
end
