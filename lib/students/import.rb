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

student_importer = StudentImporter.new ARGV[1]
student_importer.add_students_to_db
