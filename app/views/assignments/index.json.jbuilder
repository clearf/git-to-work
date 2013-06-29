json.array!(@assignments) do |assignment|
  json.extract! assignment, :title, :description, :github_login, :github_repo, :assigned_date, :due_date
  json.url assignment_url(assignment, format: :json)
end
