require 'json'
require 'pry-byebug'

class Hangman
  WORD_LIST = File.readlines('google-10000-english-no-swears.txt', chomp: true)
  POSSIBLE_WORDS = WORD_LIST.select {|word| word.length >= 5 && word.length <= 12}
  attr_accessor :correct_letters_display, :incorrect_guesses, :game_over
  attr_reader :game_word

  def initialize(game_word, correct_letters_display)
    @game_word = game_word
    @correct_letters_display = correct_letters_display
    @incorrect_guesses = {letters: [], words: []}
    @game_over = false
  end

  def finish_game()
    self.show_scoreboard()
    if @game_over == "won"
      puts "\n\nYOU WIN!!!"
    else
      puts "\n\nGame over :("
      puts "The word was #{@game_word}."
    end
    puts "Would you like to play again? Type 'y' for yes or 'n' for no."
    if gets.chomp == "y"
      play_game()
    else
      puts "Thanks for playing!"
    end
  end

  def game_over?()
     if @correct_letters_display.join == @game_word
      @game_over = "won"
     elsif @incorrect_guesses[:letters].length + @incorrect_guesses[:words].length > 5
      @game_over = "lost"
     else
      @game_over = false
    end
  end

  # def save_game()
  #   JSON.dump({
  #     :game_word => @game_word,
  #     :correct_letters_display => @correct_letters_display,
  #     :incorrect_guesses => @incorrect_guesses,
  #     :game_over => @game_over
  #   })
  #   binding.pry
  # end

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
    show_hangman(@incorrect_guesses[:letters].length + @incorrect_guesses[:words].length)
    puts "Incorrect letters: #{@incorrect_guesses[:letters].join(" ")}" if @incorrect_guesses[:letters].length > 0
    puts "Incorrect words: #{@incorrect_guesses[:words].join(" ")}" if @incorrect_guesses[:words].length > 0
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

  def self.create_new_game()
        #difficulty = self.set_difficulty()
    game_word = self.create_game_word()
    correct_letters_display = self.create_correct_letters_display(game_word.length)
    Hangman.new(game_word, correct_letters_display)
  end
end

class Guess < Hangman
  def initialize(guess, guess_type)
    @guess = guess
    @guess_type = guess_type
  end

  def check_guess(game)
    if game.game_word.include?(@guess)
      @guess_type == "word" ? game.correct_letters_display = [@guess] :
      for i in 0...game.game_word.length
        if @guess == game.game_word[i]
          game.correct_letters_display[i] = @guess
        end
      end
    else
      @guess_type == "letter"? game.incorrect_guesses[:letters].push(@guess) : game.incorrect_guesses[:words].push(@guess)
    end
    game.game_over?()
  end

  def self.get_guess_type(guess)
    if guess.length == 1
      "letter"
    # elsif guess == "SAVE"
    #   "save"
    else
      "word"
    end
  end

  def self.valid_guess?(game, guess)
    if guess.length == 1
      if (game.incorrect_guesses[:letters] && game.incorrect_guesses[:letters].include?(guess)) || game.correct_letters_display.include?(guess)
        puts "'#{guess}' was already used. Please guess a different letter or word."
        false
      else
        true
      end
    elsif guess.length == game.game_word.length
      if game.incorrect_guesses[:words] && game.incorrect_guesses[:words].include?(guess)
        puts "'#{guess}' was already used. Please guess a different word or letter."
        false
      else
        true
      end
    # elsif guess == "SAVE"
    #   puts "Saving game..."
    #   game.save_game()
    #   true
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

def play_game()
  game = Hangman.create_new_game()

  until game.game_over do
    round_guess = Guess.create_new_guess(game)
    round_guess.check_guess(game)
  end

  game.finish_game() 
end

play_game()








# class GameWord < Hangman
#   def initialize(game_word)
#     @@game_word = game_word
#   end

#   def self.game_word()
#     @@game_word
#   end

#   def self.create_game_word()
#     game_word = POSSIBLE_WORDS[rand POSSIBLE_WORDS.length]
#     GameWord.new(game_word)
#   end
# end