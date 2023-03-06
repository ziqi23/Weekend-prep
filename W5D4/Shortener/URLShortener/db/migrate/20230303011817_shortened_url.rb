class ShortenedUrl < ActiveRecord::Migration[7.0]
  def change
    create_table :shortened_urls do |t|
      t.string :long_url, null: false, unique: true
      t.string :short_url, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :shortened_urls, :short_url, unique: true
  end
end
