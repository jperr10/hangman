require 'json'
require 'pry-byebug'
require 'time'

class Hangman
  WORD_LIST = File.readlines('google-10000-english-no-swears.txt', chomp: true)
  POSSIBLE_WORDS = WORD_LIST.select {|word| word.length >= 5 && word.length <= 12}
  attr_accessor :correct_letters_display, :incorrect_guesses, :game_over
  attr_reader :game_word

  def initialize(game_word, correct_letters_display, incorrect_guesses)
    @game_word = game_word
    @correct_letters_display = correct_letters_display
    @incorrect_guesses = incorrect_guesses
    @game_over = false
  end

  def finish_game()
    if @game_over == "saved"
      puts "...Game saved\n"
      puts "Would you like to start a new game? Type 'y' for yes or 'n' for no."
    else
      self.show_scoreboard()
      if @game_over == "won"
        puts "\n\nYOU WIN!!!"
      else
        puts "\n\nGame over :("
        puts "The word was #{@game_word}."
      end
      puts "Would you like to play again? Type 'y' for yes or 'n' for no."
    end
    if gets.chomp == "y"
      start_playing()
    else
      puts "Thanks for playing!"
    end
  end

  def game_over?()
     if @correct_letters_display.join == @game_word
      @game_over = "won"
     elsif @incorrect_guesses["letters"].length + @incorrect_guesses["words"].length > 5
      @game_over = "lost"
     else
      @game_over = false
    end
  end

  def self.from_json(filename)
    data = JSON.load File.read(filename)
    File.delete(filename)
    loaded_game_info = data["game_word"], data["correct_letters_display"], data["incorrect_guesses"]
  end

  def to_json()
    JSON.dump({
      :game_word => @game_word,
      :correct_letters_display => @correct_letters_display,
      :incorrect_guesses => @incorrect_guesses,
    })
  end

  def generate_id(game)
    date = Time.new.strftime("%m:%d")
    correct_display = game.correct_letters_display.join
    total_incorrect = game.incorrect_guesses["letters"].length + game.incorrect_guesses["words"].length
  
    id = "#{date}-#{correct_display}-#{total_incorrect}"
  end

  def save_game(game)
    game.game_over = 'saved'
    Dir.mkdir('saved_games') unless Dir.exist?('saved_games')

    id = game.generate_id(game)
    game_name = "saved_games/#{id}.json"

    File.open(game_name, "w") { |g| g.puts game.to_json() }
  end

  def show_hangman(num_incorrect_guesses)
    case num_incorrect_guesses
    when 0 then puts "_____\n|   |\n|\n|\n|\n|\n|\n\n"
    when 1 then puts "_____\n|   |\n|   O\n|\n|\n|\n|\n\n"
    when 2 then puts "_____\n|   |\n|   O\n|   ||\n|   ||\n|\n|\n"
    when 3 then puts "_____\n|   |\n|   O\n|   ||\n|   ||\n|   /\n|\n"
    when 4 then puts "_____\n|   |\n|   O\n|   ||\n|   ||\n|   /\\\n|\n"
    when 5 then puts "_____\n|   |\n|   O\n|  /||\n|   ||\n|   /\\\n|\n"
    when 6 then puts "_____\n|   |\n|   O\n|  /||\\\n|   ||\n|   /\\\n|\n"
    end
  end

  def show_scoreboard()
    puts "\n#{@correct_letters_display.join(" ")}"
    show_hangman(@incorrect_guesses["letters"].length + @incorrect_guesses["words"].length)
    puts "Incorrect letters: #{@incorrect_guesses["letters"].join(" ")}" if @incorrect_guesses["letters"].length > 0
    puts "Incorrect words: #{@incorrect_guesses["words"].join(" ")}" if @incorrect_guesses["words"].length > 0
  end

  def self.get_game_to_load()
    saved_games_arr = Dir.glob('saved_games/*.json')
    puts "Which saved game would you like to load?\n\n"
    for i in 1..saved_games_arr.length
      id_arr = saved_games_arr[i-1].split('/')[1].split('.')[0].split('-')
      date = Time.parse(id_arr[0]).strftime("%d of %B")
      correct_letters_display = id_arr[1].split('').join(' ')
      num_wrong_guesses = id_arr[2]
      puts "#{i}) From #{date}: #{correct_letters_display}  (#{num_wrong_guesses} wrong guesses)"
    end
    puts "\nPlease enter the corresponding number or type 'n' for a new game."
    answer = gets.chomp.to_i
    if answer > 0 && answer <= saved_games_arr.length
      saved_games_arr[answer-1]
    else
      "new_game"
    end
  end

  def self.create_correct_letters_display(length)
    display = []
    length.times do
      display.unshift("_")
    end
    display
  end

  def self.create_game_word()
    game_word = POSSIBLE_WORDS[rand POSSIBLE_WORDS.length].upcase
  end

  def self.create_new_game(answer = 1)
    if answer == 1
      game_word = self.create_game_word()
      correct_letters_display = self.create_correct_letters_display(game_word.length)
      incorrect_guesses = {"letters" => [], "words" => []}
      Hangman.new(game_word, correct_letters_display, incorrect_guesses)
    else
      filename = self.get_game_to_load()
      if filename == "new_game"
        self.create_new_game()
      else
        loaded_game_info = self.from_json(filename)
        Hangman.new(loaded_game_info[0], loaded_game_info[1], loaded_game_info[2])
      end
    end
  end
end

class Guess < Hangman
  def initialize(guess, guess_type)
    @guess = guess
    @guess_type = guess_type
  end

  def check_guess(game)
    if game.game_over == "saved"
      return
    elsif game.game_word.include?(@guess)
      @guess_type == "word" ? game.correct_letters_display = [@guess] :
      for i in 0...game.game_word.length
        if @guess == game.game_word[i]
          game.correct_letters_display[i] = @guess
        end
      end
    else
      @guess_type == "letter"? game.incorrect_guesses["letters"].push(@guess) : game.incorrect_guesses["words"].push(@guess)
    end
    game.game_over?()
  end

  def self.get_guess_type(guess)
    if guess.length == 1
      "letter"
    elsif guess == "SAVE"
      "save"
    else
      "word"
    end
  end

  def self.valid_guess?(game, guess)
    if guess.length == 1
      if (game.incorrect_guesses["letters"] && game.incorrect_guesses["letters"].include?(guess)) || game.correct_letters_display.include?(guess)
        puts "'#{guess}' was already used. Please guess a different letter or word."
        false
      else
        true
      end
    elsif guess.length == game.game_word.length
      if game.incorrect_guesses["words"] && game.incorrect_guesses["words"].include?(guess)
        puts "'#{guess}' was already used. Please guess a different word or letter."
        false
      else
        true
      end
    elsif guess == "SAVE"
      puts "Saving game..."
      game.save_game(game)
      true
    else
      puts "'#{guess}' is not a valid guess. Please try another letter or a #{game.game_word.length}-letter word"
      false
    end
  end

  def self.get_guess(game)
    guess = gets.chomp.upcase
    until self.valid_guess?(game, guess)
      guess = gets.chomp.upcase
    end
    guess
  end

  def self.create_new_guess(game)
    game.show_scoreboard()
    puts "\nGuess a letter or word (or type 'save' to save game)"
    guess = self.get_guess(game)
    guess_type = self.get_guess_type(guess)
    Guess.new(guess, guess_type)
  end
end

def start_playing()
  if Dir.glob('saved_games/*.json').length == 0
    game = Hangman.create_new_game()
  else
    puts "Type 1 to start a new game"
    puts "Type 2 to load a saved game"
    answer = gets.chomp.to_i
    until answer == 1 || answer == 2
      puts "Please type '1' for a new game or '2' to load a saved game"
      answer = gets.chomp.to_i
    end
    game = Hangman.create_new_game(answer)
  end

  until game.game_over do
    round_guess = Guess.create_new_guess(game)
    round_guess.check_guess(game)
  end

  game.finish_game() 
end



start_playing()