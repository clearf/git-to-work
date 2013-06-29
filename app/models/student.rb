class Student < ActiveRecord::Base
  has_many :contributions
  has_many :assignments, :through => :contributions
end
