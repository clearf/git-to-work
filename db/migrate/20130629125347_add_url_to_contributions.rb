class AddUrlToContributions < ActiveRecord::Migration
  def change
    add_column :contributions, :url, :string
  end
end
