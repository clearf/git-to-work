class StudentsController < ApplicationController
  before_action :set_student, only: [:show, :edit, :update, :destroy]

  # GET /students
  # GET /students.json
  def index
    @students = Student.all
    @assignments = Assignment.all
    @page_key='/students/'
  end

  # GET /students/1
  # GET /students/1.json
  def show
    uniq_assignments = @student.assignments.uniq do |assignment| 
      assignment.id
    end
    @contributions = []
    uniq_assignments.each do |assignment|
      @contributions << assignment.contributions.where(student_id: @student.id, 
                                                       assignment_id: assignment.id).order('contribution_updated_at desc').first
    end
    
    @missing_assignment = (Assignment.all - uniq_assignments)
  end

  # GET /students/new
  def new
    @student = Student.new
  end

  # GET /students/1/edit
  def edit
  end

  # POST /students
  # POST /students.json
  def create
    @student = Student.new(student_params)

    respond_to do |format|
      if @student.save
        format.html { redirect_to @student, notice: 'Student was successfully created.' }
        format.json { render action: 'show', status: :created, location: @student }
      else
        format.html { render action: 'new' }
        format.json { render json: @student.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /students/1
  # PATCH/PUT /students/1.json
  def update
    respond_to do |format|
      if @student.update(student_params)
        format.html { redirect_to @student, notice: 'Student was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @student.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /students/1
  # DELETE /students/1.json
  def destroy
    @student.destroy
    respond_to do |format|
      format.html { redirect_to students_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_student
      @student = Student.find(params[:id])

      uniq_assignments = @student.assignments.uniq do |assignment| 
        assignment.id
      end
      @contributions = []
      uniq_assignments.each do |assignment|
        @contributions << @student.contributions.where(assignment_id: assignment.id, 
                                                        student_id: @student.id).order('contribution_updated_at desc').first
      end
      @page_key='/students/'
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def student_params
      params.require(:student).permit(:name, :email, :github_login, :course)
    end
end
