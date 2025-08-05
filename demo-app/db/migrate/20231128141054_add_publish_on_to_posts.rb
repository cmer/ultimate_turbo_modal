class AddPublishOnToPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :publish_on, :date
  end
end
