# This file is part of CanStaging.

# CanStaging is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# CanStaging is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with CanStaging.  If not, see <https://www.gnu.org/licenses/>.

# Author: Morten Ervik, ervikm@iarc.fr, CSU/IARC

require 'csv'

class KeyManager
  KEYFILENAME="./data/keyfile.txt"
  @@users = {}
  ROLES = ['user', 'admin']
  def initialize
    if File.exist? KEYFILENAME
      load_users
    else
      # add defaults
      key = 'xyz'
      @@users[key] = User.new("Default", "NA", "user", key)
    end
  end
  def load_users
    CSV.foreach(KEYFILENAME, col_sep: "\t", headers: true ) do |row|
      @@users[row["key"]] = User.new(row["username"], row["email"], row["role"], row["key"])
    end
  end
  def add_user(username, email, role = 'user')
    new_user = User.new(username, email, role)
    @@users[new_user.key] = new_user
    new_user
  end
  def valid_key?(key)
    !get_user(key).nil?
  end
  def get_user(key)
    # @@users.keys.include?(key)
    if (key.nil?)
      return nil
    else
      @@users.values.find { |user| key.start_with?(user.key) }
    end
  end
  def admin_key?(key)
    get_user(key).role == 'admin'
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