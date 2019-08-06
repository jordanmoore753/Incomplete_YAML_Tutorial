class User
  attr_reader :user, :pw, :interests

  def initialize(username, pw)
    @user = username
    @pw = pw
    @interests = []
  end

  def add_interest(int)
    @interests << int
  end

  def remove_interest(int)
    @interests.delete(int)
  end
end
