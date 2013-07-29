require 'csv'

class KeyManager
  KEYFILENAME="keyfile.txt"
  @@users = {}
  ROLES = ['user', 'admin']
  def initialize
    load_users
  end
  def load_users
    CSV.foreach(KEYFILENAME, {col_sep: "\t", headers: true }) do |row|
      @@users[row["key"]] = User.new(row["username"], row["email"], row["role"], row["key"])
    end
  end
  def add_user(username, email, role = 'user')
    new_user = User.new(username, email, role)
    @@users[new_user.key] = new_user
    new_user
  end
  def valid_key?(key)
    @@users.keys.include?(key)
  end
  def admin_key?(key)
    @@users[key].role == 'admin'
  end
  def save_users_to_file
    CSV.open(KEYFILENAME, "wb", {col_sep: "\t", headers: true }) do |csv|
      headers = ["key","username","email","role"]
      csv << headers
      @@users.each do |key, user|
        row = []
        headers.each do |col| 
          row << user.send(col)
        end
        csv << row
      end
    end
  end
end

class User
  attr_accessor :key, :username, :email, :role
  def initialize(username = '', email = '', role = 'user', key = nil)
    @username = username
    @email = email
    @role = role
    @key = key || generate_key
  end
  def generate_new_key (length = 16)
    @key = generate_key length
  end
  private
  def generate_key(length = 16)
    chars = ('1'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a
    Array.new(length) { chars[rand(chars.length)].chr }.join
  end
end