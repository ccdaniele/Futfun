require_relative 'config/environment.rb'
require 'pry'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'

def find_a_players_team_by_name(player) 
    if Player.find_by(name: "#{player}")
        Player.find_by(name: "#{player}").club.name
    else
        puts "Sorry, we cannot find your player!"
    end
end

def find_a_player_by_name(name)
    id = Player.find_by(name: "#{name}").player_id
    call_player(id)
end

def find_a_club(club_name) 
    Club.find_by(name: "#{club_name}")
end

def call_custom_league(league, season)
    call(URI("https://v3.football.api-sports.io/teams?league=#{league}&season=#{season}"))
end

def call_team
    call(URI("https://v3.football.api-sports.io/players?season=2019&league=39&team=50"))
end

def call_team_players(league, season, team)
    call(URI("https://v3.football.api-sports.io/players?season=#{season}&league=#{league}&team=#{team}"))
end

def call_player(id, season)
    call(URI("https://v3.football.api-sports.io/players?id=#{id}&season=#{season}"))
end

def call_club_stats(club, league, season)
   x  = call(URI("https://v3.football.api-sports.io/teams/statistics?league=#{league}&team=#{club}&season=#{season}"))
end

def call_league_and_season(league, season)
    l = league_selection(league)
    url = URI("https://v3.football.api-sports.io/leagues?season=#{season}&id=#{l}")
    call(url)
end

def call_league
    call(URI("https://v3.football.api-sports.io/teams?league=39&season=2014"))
end

def call_league_by_id(id, season)
    call(URI("https://v3.football.api-sports.io/teams?league=#{id}&season=#{season}"))
end


def seed_league_teams_and_players(league, season)     #populates with a league, its teams with basic data, and their players' ids and basic data by season
    x = call_custom_league(league, season)
    x["response"].map do |team|
        club_id = team["team"]["id"]
        name = team["team"]["name"]
        country = team["team"]["country"]
        founded = team["team"]["founded"]
        stadium = team["venue"]["name"]
        city = team["venue"]["city"]
        new_club = Club.find_or_create_by(club_id: club_id, name: name, country: country, founded: founded, stadium: stadium, city: city)
        url = URI("https://v3.football.api-sports.io/players?season=#{season}&league=#{league}&team=#{club_id}")
        create_players_from_team(new_club, url)
    end
end



#-------  older methods-----

  #           <--------api methods------->


def call(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(url)
    request["x-rapidapi-host"] = 'v3.football.api-sports.io'
    request["x-rapidapi-key"] = '8c78b34553ee9daa9b38805f456cdadb'
    response = http.request(request)
    JSON(response.read_body)
end

def call_league(league, season)     #basic team data, teams in a league for a season
    call(URI("https://v3.football.api-sports.io/teams?league=#{league}&season=#{season}"))
end

def call_league_by_id(id, season)
    call(URI("https://v3.football.api-sports.io/teams?league=#{id}&season=#{season}"))
end

def call_custom_league(league, season)
    call(URI("https://v3.football.api-sports.io/teams?league=#{league}&season=#{season}"))
end

def call_team(league, club, season)   #could populate both teams and players with data across a league
    call(URI("https://v3.football.api-sports.io/players?season=#{season}&league=#{league}&team=#{club}"))
end

def call_team_players(league, season, team)
    call(URI("https://v3.football.api-sports.io/players?season=#{season}&league=#{league}&team=#{team}"))
end

def call_player(id, season)
    call(URI("https://v3.football.api-sports.io/players?id=#{id}&season=#{season}"))
end

  #           <--------database methods------->


league_array = [39, 140, 78, 61, 135, 253]
seasons = [2017, 2018, 2019]

def league_selection(league)
    if league == "Premier League"
        l = 39
    elsif league == "140"
        league == "La Liga"
        l = 140
    elsif
        league == "Bundesliga"
        l = 78
    elsif 
        league == "Ligue 1"
        l = 61
    elsif
        league == "Serie A"
        l = 135
    elsif
        league == "MLS"
        l = 253
    end
    l
end

def find_a_players_team_by_name(player) 
    if Player.find_by(name: "#{player}")
        Player.find_by(name: "#{player}").club.name
    else
        puts "Sorry, we cannot find your player!"
    end
end

def find_a_player_by_name(name)
    id = Player.find_by(name: "#{name}").player_id
    call_player(id)
end

def find_a_club(club_name) 
    Club.find_by(name: "#{club_name}")
end


  #           <--------create methods-------> 

def destroy_all
    Club.destroy_all
    Player.destroy_all
    League.destroy_all
end

def create_all(league_array, season)
    create_leagues_ids
    create_leagues_clubs(league_array, season)
    create_players_across_leagues(league_array, season)
    create_club_stats_across_leagues(league_array, season)
end

def create_leagues_ids   #good     #populates with leagues, their ids and basic data
    url = URI("https://v3.football.api-sports.io/leagues?type=league")
    x = call(url)
    x["response"].each do |league|
        league_id = league["league"]["id"]
        name = league["league"]["name"]
        country = league["country"]["name"]
        stats_since = league["seasons"][0]["year"]
        League.find_or_create_by(league_id: league_id, name: name, country: country)
    end
end


def create_league_clubs(league, season) #good 1/7
    x = call_custom_league(league, season)
    x["response"].map do |team|
        club_id = team["team"]["id"]
        new_club = Club.find_or_create_by(club_id: club_id)
        new_club.name = team["team"]["name"]
        new_club.country = team["team"]["country"]
        new_club.founded = team["team"]["founded"]
        new_club.stadium = team["venue"]["name"]
        new_club.city = team["venue"]["city"]
        new_club.save
    end
end

def create_club_stats_across_league(league, season)   #good 1/7
    x = call_custom_league(league, season)
    x["response"].map do |team|
        club = team["team"]["id"]
        y = call_club_stats(club, league, season)
        club_id = club
        new_club = Club.find_or_create_by(club_id: club_id)
        new_club.name = y["response"]["team"]["name"]
        new_club.form = y["response"]["form"]
        new_club.played = y["response"]["fixtures"]["played"]["total"]
        new_club.wins = y["response"]["fixtures"]["wins"]["total"]
        new_club.draws = y["response"]["fixtures"]["draws"]["total"]
        new_club.losses = y["response"]["fixtures"]["loses"]["total"]
        new_club.goals_for = y["response"]["goals"]["for"]["total"]["total"]
        new_club.goals_against = y["response"]["goals"]["against"]["total"]["total"]
        new_club.clean_sheets = y["response"]["clean_sheet"]["total"]
        new_club.failed_to_score = y["response"]["failed_to_score"]["total"]
        new_club.save
    end
end


def create_leagues_clubs(league_array, season)   #in create_all
    league_array.each do |league|
    create_league_clubs(league, season)
    end
end

def create_club_stats_across_leagues(league_array, season)   #untested, theoretically good
    league_array.each do |league|
    create_club_stats_across_league(league, season)
    end
end

def create_players_from_clubs_in_league(league, season)   #populates players across one league
    x = call_custom_league(league, season)
    x["response"].map do |team|
        club_id = team["team"]["id"]
        y = call_team_players(league, season, club_id)
        y["response"].each do |player|
            player_id = player["player"]["id"]
            create_player(player_id, season)
        end
    end
end

def create_players_across_leagues(league_array, season)      #in create_all
    league_array.each do |league|
        create_players_from_clubs_in_league(league, season) 
    end
end

def create_player(player_id, season) #good 1/7
    player_stats = call_player(player_id, season)
    player_id = player_stats["parameters"]["id"]
    season = player_stats["parameters"]["season"]
    new_player = Player.find_or_create_by(player_id: player_id)
    new_player.name = player_stats["response"][0]["player"]["name"]
    new_player.club_id = player_stats["response"][0]["statistics"][0]["team"]["id"]
    new_player.age = player_stats["response"][0]["player"]["age"]
    new_player.height = player_stats["response"][0]["player"]["height"]
    new_player.weight = player_stats["response"][0]["player"]["weight"]
    new_player.appearances =  player_stats["response"][0]["statistics"][0]["games"]["appearences"]
    new_player.minutes =  player_stats["response"][0]["statistics"][0]["games"]["minutes"]
    new_player.position =  player_stats["response"][0]["statistics"][0]["games"]["position"]
    new_player.rating =  player_stats["response"][0]["statistics"][0]["games"]["rating"]
    new_player.shots =  player_stats["response"][0]["statistics"][0]["shots"]["total"]
    new_player.shots_on_target =  player_stats["response"][0]["statistics"][0]["shots"]["on"]
    new_player.goals =  player_stats["response"][0]["statistics"][0]["goals"]["total"]
    new_player.goals_conceded =  player_stats["response"][0]["statistics"][0]["goals"]["conceded"]
    new_player.goals_saved =  player_stats["response"][0]["statistics"][0]["goals"]["saves"]
    new_player.assists =  player_stats["response"][0]["statistics"][0]["goals"]["assists"]
    new_player.passes =  player_stats["response"][0]["statistics"][0]["passes"]["total"]
    new_player.pass_accuracy =  player_stats["response"][0]["statistics"][0]["passes"]["accuracy"]
    new_player.tackles =  player_stats["response"][0]["statistics"][0]["tackles"]["total"]
    new_player.blocks =  player_stats["response"][0]["statistics"][0]["tackles"]["blocks"]
    new_player.interceptions =  player_stats["response"][0]["statistics"][0]["tackles"]["interceptions"]
    new_player.duels =  player_stats["response"][0]["statistics"][0]["duels"]["total"]
    new_player.duels_won =  player_stats["response"][0]["statistics"][0]["duels"]["won"]
    new_player.dribbles_attempted =  player_stats["response"][0]["statistics"][0]["dribbles"]["attempts"]
    new_player.dribbles_successful =  player_stats["response"][0]["statistics"][0]["dribbles"]["success"]
    new_player.fouls_drawn =  player_stats["response"][0]["statistics"][0]["fouls"]["drawn"]
    new_player.fouls_committed =  player_stats["response"][0]["statistics"][0]["fouls"]["committed"]
    new_player.yellow_cards =  player_stats["response"][0]["statistics"][0]["cards"]["yellow"]
    new_player.red_cards =  player_stats["response"][0]["statistics"][0]["cards"]["red"]
    new_player.penalties_won =  player_stats["response"][0]["statistics"][0]["penalty"]["won"]
    new_player.penalties_committed =  player_stats["response"][0]["statistics"][0]["penalty"]["committed"]
    new_player.penalties_scored =  player_stats["response"][0]["statistics"][0]["penalty"]["scored"]
    new_player.penalties_missed =  player_stats["response"][0]["statistics"][0]["penalty"]["missed"]
    new_player.penalties_saved =  player_stats["response"][0]["statistics"][0]["penalty"]["saved"]
    new_player.save
    end

    #------------- Methods for later use -----------#


def seed_all(league_array, seasons)
    seasons.each do |year|
        season = year
        league_array.each do |table|
            league = table
                seed_league_teams_and_players(league, season)
        end
    end
end

    def create_clubs_ids_across_leagues(league_array, season)
        league_array.each do |league| league_id = league
            create_club_ids(league_id, season)
        end
    end
    
    def create_player_ids_across_season_for_array_of_leagues(league_array, season)
        league_array.each do |league| 
            create_player_ids_across_league_for_a_season(league, season)
        end
    end
    
    def create_clubs_ids_across_seasons_and_leagues(league_array, seasons)
        seasons.each do |season|
            create_clubs_ids_across_leagues(league_id, season)
        end
    end  
    
    def create_player_ids
        x = call_team   #manchester city 2019
        x["response"].map do |player|
            name = player["player"]["name"]
            nationality = player["player"]["nationality"]
            player_id = player["player"]["id"]
                Player.find_or_create_by(player_id: player_id, name: name, nationality: nationality)
        end
    end
    
    def create_player_ids_across_league_for_a_season(league, season)
        x = call_custom_league(league, season)
        x["response"].each do |club|
            team = club["team"]["id"]
            players = call_team_players(league, season, team)
            players["response"].each do |player|
                name = player["player"]["name"]
                nationality = player["player"]["nationality"]
                player_id = player["player"]["id"]
                  Player.find_or_create_by(player_id: player_id, name: name, nationality: nationality)
            end
        end
    end
    

    def create_seasons
        year = 2011
        while year < 2019 do
        season = Season.create(season: "#{year}")
        year += 1
        end
    end
 

binding.pry