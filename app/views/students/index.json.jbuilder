json.array!(@students) do |student|
  json.extract! student, :name, :email, :github_login
  json.url student_url(student, format: :json)
end
