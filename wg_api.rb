require 'httpclient'
require 'json'
require 'pg'

class WGAPI
  attr_accessor :application_id
  attr_accessor :database_url

  def initialize(application_id:, database_url:)
    self.application_id = application_id
    self.database_url = database_url
  end
  def GetClanMembers(clan_id)
    url = "https://api.wotblitz.asia/wotb/clans/info/?application_id=#{application_id}&clan_id=#{clan_id}&fields=tag%2Cmembers_ids"
    client = HTTPClient.new
    response = client.get(url)
    result = JSON.parse(response.body)
    return result
  end
  def GetDBConn
    uri = URI.parse(ENV['DATABASE_URL'])
    conn = PG.connect(
      host: uri.hostname,
      dbname: uri.path[1..-1],
      user: uri.user,
      port: uri.port,
      password: uri.password
    )
    return conn
  end
  def GetAccessToken(id)
    conn = self.GetDBConn
    rows = conn.exec("select * from access_token where id=#{id}")
    row = rows.first
    access_token = row['access_token']
    return access_token
  end
  def GetMembersData(member_ids)
    access_token = self.GetAccessToken(1)
    url = "https://api.wotblitz.asia/wotb/account/info/?application_id=#{application_id}&access_token=#{access_token}&account_id=#{member_ids}&fields=nickname%2Clast_battle_time"
    client = HTTPClient.new
    response = client.get(url)
    results = JSON.parse(response.body)
  end
  def GetMembersClan(member_ids)
    url = "https://api.wotblitz.asia/wotb/clans/accountinfo/?application_id=#{application_id}&account_id=#{member_ids}"
    client = HTTPClient.new
    response = client.get(url)
    results = JSON.parse(response.body)
  end
  def GetTournamentList
    url = "https://api.wotblitz.asia/wotb/tournaments/list/?application_id=#{application_id}&fields=start_at%2Ctitle%2Ctournament_id"
    client = HTTPClient.new
    response = client.get(url)
    results = JSON.parse(response.body)
    return results
  end
  def GetTournamentStages(tournament_id)
    url = "https://api.wotblitz.asia/wotb/tournaments/stages/?application_id=#{application_id}&tournament_id=#{tournament_id}"
    client = HTTPClient.new
    response = client.get(url)
    result = JSON.parse(response.body)
    return result
  end
  def ProlongateAccessToken(id)
    access_token = self.GetAccessToken(id)
    url = 'https://api.worldoftanks.asia/wot/auth/prolongate/'
    client = HTTPClient.new
    response = client.post(url, {
                             application_id: application_id.to_s,
                             access_token: access_token.to_s
                           })
    result = JSON.parse(response.body)
    print result
    access_token = result['data']['access_token']
    conn = self.GetDBConn
    conn.exec("
      update access_token
      set access_token='#{access_token}'
      where id=#{id}
      ")
  end
  def SetAccessToken(id,access_token)
    conn = self.GetDBConn
    conn.exec("
      update access_token
      set access_token='#{access_token}'
      where id=#{id}
      ")
  end
  def GetTournamentFuture
    url = "https://tmsis.wotblitz.asia/api/v3/tournaments/future/?visibility=1&page_size=10&page=1&lang[]=ja&lang[]=en"
    return self.Get(url)
  end
  def GetTournamentRunning
    url = "https://tmsis.wotblitz.asia/api/v3/tournaments/running/?visibility=1&page_size=10&page=1&lang[]=ja&lang[]=en"
    return self.Get(url)
  end
  def GetTournamentPast
    url = "https://tmsis.wotblitz.asia/api/v3/tournaments/past/?visibility=1&page_size=10&page=1&lang[]=ja&lang[]=en"
    return self.Get(url)
  end
  def GetTournamentTeams(tournament_id)
    url = "https://tmsis.wotblitz.asia/api/v3/landings/tournaments/#{tournament_id}/teams/confirmed/?page_size=25&page=1"
    return self.Get(url)
  end
  def GetTournamentTeamData(tournament_id,team_id)
    url = "https://tmsis.wotblitz.asia/api/v3/landings/tournaments/#{tournament_id}/teams/#{team_id}/"
    return self.Get(url)
  end
  def Get(url)
    access_token = self.GetAccessToken(2)
    headers = {
      "Host" => "tmsis.wotblitz.asia",
      "Accept" => "*/*",
      "Cache-Control" => "no-cache",
      "Accept-Language" => "ja",
      "Authorization" => "Bearer #{access_token}"
    }
    client = HTTPClient.new
    response = client.get(url,header: headers)
    result = JSON.parse(response.body)
    return result
  end
end
