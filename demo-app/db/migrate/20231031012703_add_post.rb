class AddPost < ActiveRecord::Migration[7.0]
  def up
    Post.create(title: "Hello, world!", body: "This is my first post.")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
