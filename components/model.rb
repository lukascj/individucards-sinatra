require 'sinatra'
require 'bcrypt'
require 'sqlite3'
require 'json'

#Connect to the database
def connectToDb()
    db = SQLite3::Database.new("./db/warcardsdb.db")
    db.results_as_hash = true
    return db
end

#Check if the user exists in the database
def getUserByUsername(username)
    db = connectToDb()
    user = db.execute("SELECT * FROM users WHERE username=?", username).first || nil
    return user
end

#create user with username and password, return status code 200 if user created, and userId
def createUser(username, password, passwordConfirm)
    status = 200
    db = connectToDb()
    user = getUserByUsername(username)

    if password != passwordConfirm
        p "Passwords do not match"
        return status = 400
    end

    if user 
        p user, "User already exists"
        return status = 400
    end

    passwordDigest = BCrypt::Password.create(password)
    db.execute(
      "INSERT INTO users (username, passwordDigest) VALUES (?, ?);",[username.downcase, passwordDigest]
    )

    return status
end

def loginUser(username, password)
    status = 200
    db = connectToDb()

    user = getUserByUsername(username)

    if BCrypt::Password.new(user["passwordDigest"]) != password 
        return status = 400
    end

    return status, user 
end

# Get all users ranked by hs from highest to lowest, return array of users
def fetchSortedUsersbyHs()

    db = connectToDb()

    sortedUsersbyHs = db.execute("SELECT * FROM users ORDER BY highscore DESC")

    return sortedUsersbyHs
end

# Get all cards, return array of cards with cardId, name, img_url
def fetchCards()

    db = connectToDb()

    cards = db.execute("SELECT * FROM cards")

    randCards = cards.shuffle    

    cardsJSON = randCards.to_json

    return cardsJSON, randCards
end

def updateScore(score)
    db = connectToDb()

    user_highscore = db.execute("SELECT highscore FROM users WHERE username = ?", session[:loggedIn]["username"]).first

    if score.to_i > user_highscore["highscore"].to_i
      db.execute("UPDATE users SET highscore = ? WHERE username = ?", score, session[:loggedIn]["username"])
    end  
end